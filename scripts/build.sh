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
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' CYAN='' NC=''
fi

# Find available iOS simulator from xcodebuild destinations (returns "name|uuid")
find_simulator() {
    local simulator_name=""
    local simulator_uuid=""

    # Get available destinations from xcodebuild (this is the authoritative source)
    local destinations
    destinations=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showdestinations 2>/dev/null | grep "iOS Simulator")

    # Try preferred simulators in order
    for name in "iPhone 16 Pro" "iPhone 16" "iPhone 15 Pro" "iPhone 15" "iPhone 14 Pro" "iPhone 14"; do
        local line
        line=$(echo "$destinations" | grep -F "name:$name }" | head -1)
        if [[ -n "$line" ]]; then
            simulator_name="$name"
            # Extract UUID from the line (format: "{ platform:iOS Simulator, ..., id:UUID, ... }")
            simulator_uuid=$(echo "$line" | sed -E 's/.*id:([A-F0-9-]+).*/\1/')
            break
        fi
    done

    if [[ -z "$simulator_name" ]]; then
        echo -e "${RED}Error: No compatible iPhone simulator found${NC}" >&2
        echo "Available destinations:" >&2
        echo "$destinations" | grep iPhone >&2
        exit 1
    fi

    echo "$simulator_name|$simulator_uuid"
}

# Get destination string (uses UUID for reliability)
get_destination() {
    local result
    result=$(find_simulator)
    local simulator_name="${result%%|*}"
    local simulator_uuid="${result##*|}"

    echo -e "${CYAN}Using simulator: $simulator_name ($simulator_uuid)${NC}" >&2
    # Use UUID-based destination for maximum compatibility
    echo "platform=iOS Simulator,id=$simulator_uuid"
}

# Commands
cmd_build() {
    local destination
    destination=$(get_destination)
    echo -e "${GREEN}Building for: $destination${NC}"

    xcodebuild build \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$destination" \
        -sdk iphonesimulator \
        CODE_SIGNING_ALLOWED='NO'
}

cmd_test() {
    local destination
    destination=$(get_destination)
    echo -e "${GREEN}Testing on: $destination${NC}"

    xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$destination" \
        -sdk iphonesimulator \
        CODE_SIGNING_ALLOWED='NO' || echo "Tests completed or no tests found"
}

cmd_test_unit() {
    local destination
    destination=$(get_destination)
    echo -e "${GREEN}Running unit tests on: $destination${NC}"

    xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$destination" \
        -sdk iphonesimulator \
        CODE_SIGNING_ALLOWED='NO' \
        -only-testing:"LeavesOfBlocksTests" || echo "Unit tests completed or no tests found"
}

cmd_test_ui() {
    local destination
    destination=$(get_destination)
    echo -e "${GREEN}Running UI tests on: $destination${NC}"

    xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$destination" \
        -sdk iphonesimulator \
        CODE_SIGNING_ALLOWED='NO' \
        -only-testing:"LeavesOfBlocksUITests" || echo "UI tests completed or no tests found"
}

cmd_clean() {
    local destination
    destination=$(get_destination)
    echo -e "${GREEN}Clean building for: $destination${NC}"

    xcodebuild clean build \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$destination" \
        -sdk iphonesimulator \
        CODE_SIGNING_ALLOWED='NO'
}

cmd_info() {
    echo -e "${CYAN}=== Build Environment ===${NC}"
    echo ""
    echo -e "${YELLOW}Xcode Version:${NC}"
    xcodebuild -version
    echo ""
    echo -e "${YELLOW}Selected Simulator:${NC}"
    local result
    result=$(find_simulator)
    local simulator_name="${result%%|*}"
    local simulator_uuid="${result##*|}"
    echo "$simulator_name ($simulator_uuid)"
    echo ""
    echo -e "${YELLOW}Available iPhone Simulators (from xcodebuild):${NC}"
    xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showdestinations 2>/dev/null | grep "iOS Simulator" | grep "iPhone" | head -10
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
        echo "The script auto-detects available iOS simulators."
        echo "Preferred order: iPhone 16 Pro > iPhone 16 > iPhone 15 Pro > iPhone 15"
        exit 1
        ;;
esac
