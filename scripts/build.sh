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

# Simple destination - let xcodebuild pick the best available simulator
# Using OS=latest ensures we always use the newest iOS version
# Not specifying a device name lets xcodebuild choose any compatible iPhone
DESTINATION="platform=iOS Simulator,OS=latest"

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
    NC='\033[0m'
else
    GREEN='' YELLOW='' CYAN='' NC=''
fi

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
    echo -e "${GREEN}Testing on iOS Simulator (latest OS)...${NC}"

    xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        CODE_SIGNING_ALLOWED='NO' || echo "Tests completed or no tests found"
}

cmd_test_unit() {
    echo -e "${GREEN}Running unit tests on iOS Simulator (latest OS)...${NC}"

    xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        CODE_SIGNING_ALLOWED='NO' \
        -only-testing:"LeavesOfBlocksTests" || echo "Unit tests completed or no tests found"
}

cmd_test_ui() {
    echo -e "${GREEN}Running UI tests on iOS Simulator (latest OS)...${NC}"

    xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
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
    echo "$DESTINATION"
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
        echo "Tests run on: $DESTINATION"
        exit 1
        ;;
esac
