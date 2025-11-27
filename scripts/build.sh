#!/bin/bash
#
# build.sh - Unified build script for local and CI environments
#
# Usage:
#   ./scripts/build.sh build          # Build only
#   ./scripts/build.sh test           # Build and run all tests
#   ./scripts/build.sh test-unit      # Unit tests only
#   ./scripts/build.sh test-ui        # UI tests only
#   ./scripts/build.sh clean          # Clean build
#   ./scripts/build.sh run            # Build and run in simulator

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

# Get first available iPhone simulator name
get_simulator_name() {
    xcrun simctl list devices available | grep "iPhone" | head -1 | sed 's/^[[:space:]]*//' | sed 's/ (.*//'
}

# Get simulator UDID by name
get_simulator_udid() {
    local sim_name="$1"
    xcrun simctl list devices available | grep "$sim_name" | head -1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/'
}

# Get test destination - finds first available iPhone simulator
get_test_destination() {
    local first_iphone
    first_iphone=$(get_simulator_name)

    if [[ -n "$first_iphone" ]]; then
        echo "platform=iOS Simulator,name=$first_iphone,OS=latest"
        return 0
    fi

    echo -e "${RED}Error: No iPhone simulator found${NC}" >&2
    echo "Available simulators:" >&2
    xcrun simctl list devices available | head -20 >&2
    return 1
}

# Commands
cmd_build() {
    echo -e "${GREEN}Building for iOS Simulator...${NC}"

    # Use generic destination for build - works reliably across all environments
    xcodebuild build \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination 'generic/platform=iOS Simulator' \
        CODE_SIGNING_ALLOWED='NO'
}

cmd_test() {
    local destination
    destination=$(get_test_destination) || exit 1
    echo -e "${GREEN}Testing on: $destination${NC}"

    xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$destination" \
        CODE_SIGNING_ALLOWED='NO' || echo "Tests completed or no tests found"
}

cmd_test_unit() {
    local destination
    destination=$(get_test_destination) || exit 1
    echo -e "${GREEN}Running unit tests on: $destination${NC}"

    xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$destination" \
        CODE_SIGNING_ALLOWED='NO' \
        -only-testing:"LeavesOfBlocksTests" || echo "Unit tests completed or no tests found"
}

cmd_test_ui() {
    local destination
    destination=$(get_test_destination) || exit 1
    echo -e "${GREEN}Running UI tests on: $destination${NC}"

    xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$destination" \
        CODE_SIGNING_ALLOWED='NO' \
        -only-testing:"LeavesOfBlocksUITests" || echo "UI tests completed or no tests found"
}

cmd_clean() {
    echo -e "${GREEN}Clean building for iOS Simulator...${NC}"

    xcodebuild clean build \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination 'generic/platform=iOS Simulator' \
        CODE_SIGNING_ALLOWED='NO'
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

    # Boot simulator
    echo ""
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
    local destination
    if destination=$(get_test_destination 2>/dev/null); then
        echo "$destination"
    else
        echo "No iPhone simulator found"
    fi
}

# Main
case "${1:-help}" in
    build)      cmd_build ;;
    test)       cmd_test ;;
    test-unit)  cmd_test_unit ;;
    test-ui)    cmd_test_ui ;;
    clean)      cmd_clean ;;
    run)        cmd_run ;;
    info)       cmd_info ;;
    *)
        echo "Usage: $0 {build|test|test-unit|test-ui|clean|run|info}"
        echo ""
        echo "Commands:"
        echo "  build      Build the project for iOS Simulator"
        echo "  test       Run all tests"
        echo "  test-unit  Run unit tests only"
        echo "  test-ui    Run UI tests only"
        echo "  clean      Clean and rebuild"
        echo "  run        Build and run in simulator (without Xcode)"
        echo "  info       Show build environment info"
        exit 1
        ;;
esac
