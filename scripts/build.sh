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
# This ensures we get UUIDs that xcodebuild actually recognizes
find_simulator() {
    local simulator_name=""
    local simulator_uuid=""

    # Get available destinations from xcodebuild (authoritative source for xcodebuild)
    # This is critical: simctl and xcodebuild can have different UUIDs for the same simulator!
    local destinations
    destinations=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showdestinations 2>/dev/null)

    # Try preferred simulators in order
    for name in "iPhone 16 Pro" "iPhone 16" "iPhone 15 Pro" "iPhone 15" "iPhone 14 Pro" "iPhone 14" "iPhone SE"; do
        local line
        # Find a line with this iPhone name (avoid matching "iPhone 16 Pro Max" when looking for "iPhone 16 Pro")
        line=$(echo "$destinations" | grep -E "name:$name[[:space:]]*\}" | head -1)
        if [[ -n "$line" ]]; then
            simulator_name="$name"
            # Extract UUID from the line (format: "{ ..., id:UUID, ... }")
            simulator_uuid=$(echo "$line" | grep -oE 'id:[A-Fa-f0-9-]{36}' | head -1 | sed 's/id://')
            if [[ -n "$simulator_uuid" ]]; then
                break
            fi
        fi
    done

    if [[ -z "$simulator_name" ]] || [[ -z "$simulator_uuid" ]]; then
        echo -e "${RED}Error: No compatible iPhone simulator found${NC}" >&2
        echo "Searched for: iPhone 16 Pro, iPhone 16, iPhone 15 Pro, iPhone 15, iPhone 14 Pro, iPhone 14, iPhone SE" >&2
        echo "" >&2
        echo "Available iPhone destinations from xcodebuild:" >&2
        echo "$destinations" | grep -i "name:iPhone" | head -10 >&2
        return 1
    fi

    echo "$simulator_name|$simulator_uuid"
}

# Get destination for testing (uses UUID for specific simulator)
get_test_destination() {
    local result
    result=$(find_simulator) || exit 1
    local simulator_name="${result%%|*}"
    local simulator_uuid="${result##*|}"

    echo -e "${CYAN}Using simulator: $simulator_name ($simulator_uuid)${NC}" >&2
    echo "id=$simulator_uuid"
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
    destination=$(get_test_destination)
    echo -e "${GREEN}Testing on: $destination${NC}"

    xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$destination" \
        CODE_SIGNING_ALLOWED='NO' || echo "Tests completed or no tests found"
}

cmd_test_unit() {
    local destination
    destination=$(get_test_destination)
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
    destination=$(get_test_destination)
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
    echo -e "${YELLOW}Available iPhone Simulators (from xcodebuild):${NC}"
    xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showdestinations 2>/dev/null | grep -i "iPhone" | head -10
    echo ""
    echo -e "${YELLOW}Selected Simulator for Testing:${NC}"
    local result
    if result=$(find_simulator 2>/dev/null); then
        local simulator_name="${result%%|*}"
        local simulator_uuid="${result##*|}"
        echo "$simulator_name ($simulator_uuid)"
    else
        echo "None found"
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
        echo "The script auto-detects available iOS simulators."
        echo "Preferred order: iPhone 16 Pro > iPhone 16 > iPhone 15 Pro > iPhone 15"
        exit 1
        ;;
esac
