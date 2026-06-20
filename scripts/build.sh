#!/bin/bash
#
# build.sh - Unified build script for local and CI environments
#
# Local Development Commands:
#   ./scripts/build.sh build          # Build only
#   ./scripts/build.sh test           # Build and run all tests (parallel)
#   ./scripts/build.sh test-unit      # Unit tests only
#   ./scripts/build.sh test-ui        # UI tests only
#   ./scripts/build.sh clean          # Clean build
#   ./scripts/build.sh run            # Build and run in simulator
#   ./scripts/build.sh info           # Show build environment
#
# CI-Optimized Commands (build once, test separately):
#   ./scripts/build.sh build-for-testing          # Build test artifacts
#   ./scripts/build.sh test-without-building      # Run all tests from artifacts
#   ./scripts/build.sh test-unit-without-building # Run unit tests from artifacts
#   ./scripts/build.sh test-ui-without-building   # Run UI tests from artifacts

set -euo pipefail

# Configuration
PROJECT="LeavesOfBlocks.xcodeproj"
SCHEME="LeavesOfBlocks"
BUNDLE_ID="timothy.veil.LeavesOfBlocks"

# Script directory - resolve to project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Change to project root
cd "$PROJECT_ROOT"

# Colors (disabled in CI)
if [[ -t 1 ]] && [[ -z "${CI:-}" ]]; then
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    CYAN='\033[0;36m'
    RED='\033[0;31m'
    NC='\033[0m'
else
    GREEN='' YELLOW='' CYAN='' RED='' NC=''
fi

# Simulator discovery parses `xcrun simctl list devices available`, whose
# device lines have the form `    <name> (<UDID>) (<state>)`. The `available`
# filter drops unavailable runtimes for us, and the UDID is matched by its
# fixed 8-4-4-4-12 hex shape, so this is robust without depending on an
# interpreter. (Previously this shelled out to python3 to parse the JSON form;
# that breaks on machines where `python3` is an asdf/pyenv shim with no version
# selected — it exits non-zero and the script wrongly reports "No iPhone
# simulator found".)

# Emits "<name>\t<udid>" for every available iPhone simulator, in listing order.
list_iphone_simulators() {
    xcrun simctl list devices available 2>/dev/null \
        | sed -nE 's/^[[:space:]]+(iPhone.*) \(([0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12})\).*/\1\t\2/p'
}

# Get first available iPhone simulator name
get_simulator_name() {
    list_iphone_simulators | head -1 | cut -f1
}

# Get simulator UDID by name
get_simulator_udid() {
    local sim_name="$1"
    list_iphone_simulators | awk -F'\t' -v name="$sim_name" '$1 == name { print $2; exit }'
}

# Get test destination - adapts strategy based on environment
# CI: Uses name,OS=latest (works reliably on GitHub Actions runners)
# Local: Uses UDID (works reliably with Xcode 26.x where OS=latest fails)
get_test_destination() {
    local sim_name
    sim_name=$(get_simulator_name)

    if [[ -z "$sim_name" ]]; then
        echo -e "${RED}Error: No iPhone simulator found${NC}" >&2
        echo "Available simulators:" >&2
        xcrun simctl list devices available | head -20 >&2
        return 1
    fi

    # In CI, use name+OS=latest (works on GitHub Actions)
    # Locally, use UDID (works with Xcode 26.x where OS=latest fails)
    if [[ -n "${CI:-}" ]]; then
        echo "platform=iOS Simulator,name=$sim_name,OS=latest"
    else
        local sim_udid
        sim_udid=$(get_simulator_udid "$sim_name")
        echo "id=$sim_udid"
    fi
}

# Commands
cmd_build() {
    echo -e "${GREEN}Building for iOS Simulator...${NC}"

    xcodebuild build \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination 'generic/platform=iOS Simulator' \
        CODE_SIGNING_ALLOWED='NO'
}

cmd_build_for_testing() {
    echo -e "${GREEN}Building for testing...${NC}"

    xcodebuild build-for-testing \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination 'generic/platform=iOS Simulator' \
        -derivedDataPath "build/DerivedData" \
        CODE_SIGNING_ALLOWED='NO'
}

cmd_clean() {
    echo -e "${GREEN}Clean building for iOS Simulator...${NC}"

    xcodebuild clean build \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination 'generic/platform=iOS Simulator' \
        CODE_SIGNING_ALLOWED='NO'
}

# Unified test runner
# Usage: run_tests <test_type> <without_building> <is_ci>
#   test_type: "all", "unit", or "ui"
#   without_building: "true" or "false"
#   is_ci: "true" or "false" (enables CI-specific optimizations)
run_tests() {
    local test_type="${1:-all}"
    local without_building="${2:-false}"
    local is_ci="${3:-false}"
    local destination
    local sim_name
    local workers=4
    local parallel_testing="YES"
    local only_testing=""
    local skip_testing=""
    local test_label="tests"
    local xctestrun_file=""

    destination=$(get_test_destination) || exit 1
    sim_name=$(get_simulator_name)

    # Configure based on test type
    case "$test_type" in
        unit)
            only_testing="-only-testing:LeavesOfBlocksTests"
            test_label="unit tests"
            # CI-specific optimizations for unit tests
            if [[ "$is_ci" == "true" ]]; then
                # Disable parallel testing in CI - avoids xcodebuild crash (Abort trap: 6)
                parallel_testing="NO"
                workers=1
            fi
            ;;
        ui)
            only_testing="-only-testing:LeavesOfBlocksUITests"
            test_label="UI tests"
            # CI-specific optimizations for UI tests
            if [[ "$is_ci" == "true" ]]; then
                # Skip screenshot test (it's for Fastlane App Store submissions only)
                skip_testing="-skip-testing:LeavesOfBlocksUITests/LeavesOfBlocksUITests/testCaptureScreenshots"
                # Disable parallel testing for UI tests in CI - simulator clones are unstable
                parallel_testing="NO"
                workers=1
            else
                workers=2
            fi
            ;;
    esac

    # Test artifacts: text log (via tee, for tail/grep during the run) plus
    # an .xcresult bundle (via -resultBundlePath, for structured analysis
    # afterward — query with `xcrun xcresulttool get test-results tests
    # --path <bundle>`). xcodebuild errors if -resultBundlePath already
    # exists, so always emit a fresh timestamped bundle. Both directories
    # live under build/ and are wiped by cleanup-project.sh and by
    # prepare_test_environment in menu.sh.
    local ts
    ts=$(date +%Y%m%d-%H%M%S)
    mkdir -p "$PROJECT_ROOT/build/logs" "$PROJECT_ROOT/build/results"
    local log_file="$PROJECT_ROOT/build/logs/test-${test_type}-${ts}.log"
    local result_bundle="$PROJECT_ROOT/build/results/test-${test_type}-${ts}.xcresult"

    # Handle test-without-building mode
    if [[ "$without_building" == "true" ]]; then
        xctestrun_file=$(find build/DerivedData -name "*.xctestrun" -print -quit 2>/dev/null)
        if [[ -z "$xctestrun_file" ]]; then
            echo -e "${RED}Error: No .xctestrun file found. Run 'build-for-testing' first.${NC}"
            exit 1
        fi
        echo -e "${GREEN}Running $test_label on: $sim_name ($destination) (parallel=$parallel_testing, workers=$workers)${NC}"
        echo -e "${CYAN}  Log:    $log_file${NC}"
        echo -e "${CYAN}  Result: $result_bundle${NC}"

        xcodebuild test-without-building \
            -xctestrun "$xctestrun_file" \
            -destination "$destination" \
            -resultBundlePath "$result_bundle" \
            ${only_testing:+"$only_testing"} \
            ${skip_testing:+"$skip_testing"} \
            -parallel-testing-enabled "$parallel_testing" \
            -maximum-parallel-testing-workers "$workers" \
            CODE_SIGNING_ALLOWED='NO' 2>&1 | tee "$log_file"
    else
        echo -e "${GREEN}Running $test_label on: $sim_name ($destination) (parallel=$parallel_testing, workers=$workers)${NC}"
        echo -e "${CYAN}  Log:    $log_file${NC}"
        echo -e "${CYAN}  Result: $result_bundle${NC}"

        xcodebuild test \
            -project "$PROJECT" \
            -scheme "$SCHEME" \
            -destination "$destination" \
            -resultBundlePath "$result_bundle" \
            ${only_testing:+"$only_testing"} \
            ${skip_testing:+"$skip_testing"} \
            -parallel-testing-enabled "$parallel_testing" \
            -maximum-parallel-testing-workers "$workers" \
            CODE_SIGNING_ALLOWED='NO' 2>&1 | tee "$log_file"
    fi
}

cmd_run() {
    echo -e "${GREEN}Building and running in iOS Simulator...${NC}"
    echo ""

    # Get simulator
    local sim_name
    sim_name=$(get_simulator_name)
    if [[ -z "$sim_name" ]]; then
        echo -e "${RED}Error: No iPhone simulator found${NC}"
        exit 1
    fi

    local sim_udid
    sim_udid=$(get_simulator_udid "$sim_name")
    if [[ -z "$sim_udid" ]]; then
        echo -e "${RED}Error: Could not get UDID for $sim_name${NC}"
        exit 1
    fi

    echo -e "${CYAN}Selected simulator: $sim_name${NC}"
    echo ""

    # Build
    local build_dir="$PROJECT_ROOT/build"
    mkdir -p "$build_dir"

    echo -e "${YELLOW}Building...${NC}"
    if ! xcodebuild build \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -sdk iphonesimulator \
        -destination "id=$sim_udid" \
        -derivedDataPath "$build_dir/DerivedData" \
        CODE_SIGNING_ALLOWED='NO' 2>&1 | tail -20; then
        echo -e "${RED}Build failed!${NC}"
        exit 1
    fi

    # Shut down any already-booted simulators first, then boot only the target.
    # `open -a Simulator` restores a window for every booted device, so without
    # this a stray simulator left running (from Xcode, a prior run, or an
    # interrupted parallel-test run) would pop open alongside ours — the "many
    # simulators open" surprise. After this, exactly one device is running.
    echo ""
    if xcrun simctl list devices booted 2>/dev/null | grep -q "(Booted)"; then
        echo -e "${YELLOW}Shutting down other booted simulators...${NC}"
        xcrun simctl shutdown all 2>/dev/null || true
    fi

    echo -e "${YELLOW}Booting simulator...${NC}"
    xcrun simctl boot "$sim_udid" 2>/dev/null || true
    open -a Simulator
    sleep 2

    # Find and install app
    local app_path
    app_path=$(find "$build_dir/DerivedData" -name "LeavesOfBlocks.app" -type d | head -1)
    if [[ -z "$app_path" ]]; then
        echo -e "${RED}Error: Could not find built app${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Installing and launching...${NC}"
    xcrun simctl install "$sim_udid" "$app_path"
    xcrun simctl launch "$sim_udid" "$BUNDLE_ID"

    echo ""
    echo -e "${GREEN}✓ App launched in $sim_name!${NC}"
}

cmd_info() {
    echo -e "${CYAN}=== Build Environment ===${NC}"
    echo ""
    echo -e "${YELLOW}Xcode Version:${NC}"
    xcodebuild -version
    echo ""
    echo -e "${YELLOW}Test Destination:${NC}"
    local destination sim_name
    if destination=$(get_test_destination 2>/dev/null); then
        sim_name=$(get_simulator_name)
        echo "$sim_name ($destination)"
    else
        echo "No iPhone simulator found"
    fi
}

# Main
case "${1:-help}" in
    build)                      cmd_build ;;
    test)                       run_tests all false false ;;
    test-unit)                  run_tests unit false false ;;
    test-ui)                    run_tests ui false false ;;
    clean)                      cmd_clean ;;
    run)                        cmd_run ;;
    info)                       cmd_info ;;
    build-for-testing)          cmd_build_for_testing ;;
    test-without-building)      run_tests all true true ;;
    test-unit-without-building) run_tests unit true true ;;
    test-ui-without-building)   run_tests ui true true ;;  # Skips screenshot test in CI
    *)
        echo "Usage: $0 <command>"
        echo ""
        echo "Local Development Commands:"
        echo "  build      Build the project for iOS Simulator"
        echo "  test       Run all tests (with parallel execution)"
        echo "  test-unit  Run unit tests only"
        echo "  test-ui    Run UI tests only"
        echo "  clean      Clean and rebuild"
        echo "  run        Build and run in simulator (without Xcode)"
        echo "  info       Show build environment info"
        echo ""
        echo "CI-Optimized Commands (build once, test separately):"
        echo "  build-for-testing          Build and generate test artifacts"
        echo "  test-without-building      Run all tests from pre-built artifacts"
        echo "  test-unit-without-building Run unit tests from pre-built artifacts"
        echo "  test-ui-without-building   Run UI tests from pre-built artifacts"
        exit 1
        ;;
esac
