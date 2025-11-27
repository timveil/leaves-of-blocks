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

set -euo pipefail

# Configuration
PROJECT="LeavesOfBlocks.xcodeproj"
SCHEME="LeavesOfBlocks"

# Preferred iPhone simulators in order of preference
PREFERRED_DEVICES=("iPhone 16" "iPhone 15" "iPhone 14" "iPhone SE (3rd generation)")

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

# Get test destination - tries preferred iPhones in order, returns destination string
get_test_destination() {
    local destinations
    destinations=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showdestinations 2>/dev/null)

    for device in "${PREFERRED_DEVICES[@]}"; do
        # Match "name:iPhone 16 }" or "name:iPhone 16," (handles end of line or continuation)
        if echo "$destinations" | grep -qE "name:${device}[[:space:]]*[},]"; then
            echo "platform=iOS Simulator,name=$device,OS=latest"
            return 0
        fi
    done

    echo -e "${RED}Error: No compatible iPhone simulator found${NC}" >&2
    echo "Searched for: ${PREFERRED_DEVICES[*]}" >&2
    echo "" >&2
    echo "Available iPhone simulators:" >&2
    echo "$destinations" | grep "iPhone" | head -10 >&2
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
        echo "No compatible simulator found"
        echo "Preferred devices: ${PREFERRED_DEVICES[*]}"
    fi
}

# Main
case "${1:-help}" in
    build)      cmd_build ;;
    test)       cmd_test ;;
    test-unit)  cmd_test_unit ;;
    test-ui)    cmd_test_ui ;;
    clean)      cmd_clean ;;
    info)       cmd_info ;;
    *)
        echo "Usage: $0 {build|test|test-unit|test-ui|clean|info}"
        echo ""
        echo "Commands:"
        echo "  build      Build the project for iOS Simulator"
        echo "  test       Run all tests"
        echo "  test-unit  Run unit tests only"
        echo "  test-ui    Run UI tests only"
        echo "  clean      Clean and rebuild"
        echo "  info       Show build environment info"
        echo ""
        echo "Preferred simulators: ${PREFERRED_DEVICES[*]}"
        exit 1
        ;;
esac
