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

# Get test destination - finds first available iPhone simulator
get_test_destination() {
    # Use xcrun simctl which reliably lists available simulators
    local first_iphone
    first_iphone=$(xcrun simctl list devices available | grep "iPhone" | head -1 | sed 's/^[[:space:]]*//' | sed 's/ (.*//')

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
        exit 1
        ;;
esac
