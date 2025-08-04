#!/bin/bash
#
# menu.sh
# Interactive menu for Leaves of Blocks development commands
#

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR"

# Change to project root
cd "$PROJECT_ROOT"

# Function to display menu header
show_header() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}     ${GREEN}🍂 Leaves of Blocks Dev Menu 🍂${NC}      ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo ""
}

# Function to run command and wait for user
run_command() {
    local cmd=$1
    local desc=$2
    
    echo -e "${BLUE}Running: ${desc}${NC}"
    echo -e "${YELLOW}Command: ${cmd}${NC}"
    echo ""
    
    # Run the command
    eval "$cmd"
    
    echo ""
    echo -e "${GREEN}Press any key to continue...${NC}"
    read -n 1 -s
}

# Main menu loop
while true; do
    show_header
    
    echo -e "${BLUE}Build & Test Commands:${NC}"
    echo "  1) Build for Simulator"
    echo "  2) Run All Tests"
    echo "  3) Run Unit Tests Only"
    echo "  4) Run UI Tests Only"
    echo "  5) Clean Build"
    echo ""
    
    echo -e "${BLUE}Fastlane Commands:${NC}"
    echo "  6) Run Tests (fastlane)"
    echo "  7) Deploy Beta (TestFlight)"
    echo "  8) Deploy to App Store"
    echo "  9) Generate Screenshots"
    echo " 10) Update Changelog"
    echo ""
    
    echo -e "${BLUE}Maintenance:${NC}"
    echo " 11) Project Cleanup (Dry Run)"
    echo " 12) Project Cleanup (Delete)"
    echo ""
    
    echo -e "${BLUE}Asset Generation:${NC}"
    echo " 13) Generate & Copy App Icons"
    echo " 14) Generate Grass Images"
    echo " 15) Create App Clip Header"
    echo ""
    
    echo -e "${BLUE}Other:${NC}"
    echo " 16) Open in Xcode"
    echo " 17) View CLAUDE.md"
    echo " 18) View Coding Standards"
    echo ""
    
    echo -e "${RED}  0) Exit${NC}"
    echo ""
    
    read -p "Select an option: " choice
    
    case $choice in
        1)
            run_command "xcodebuild -project 'LeavesOfBlocks.xcodeproj' -scheme 'LeavesOfBlocks' build -destination 'platform=iOS Simulator,name=iPhone 16'" \
                       "Build for iPhone 16 Simulator"
            ;;
        2)
            run_command "xcodebuild -project 'LeavesOfBlocks.xcodeproj' -scheme 'LeavesOfBlocks' test -destination 'platform=iOS Simulator,name=iPhone 16'" \
                       "Run All Tests"
            ;;
        3)
            run_command "xcodebuild -project 'LeavesOfBlocks.xcodeproj' -scheme 'LeavesOfBlocks' test -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:'LeavesOfBlocksTests'" \
                       "Run Unit Tests Only"
            ;;
        4)
            run_command "xcodebuild -project 'LeavesOfBlocks.xcodeproj' -scheme 'LeavesOfBlocks' test -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:'LeavesOfBlocksUITests'" \
                       "Run UI Tests Only"
            ;;
        5)
            run_command "xcodebuild -project 'LeavesOfBlocks.xcodeproj' -scheme 'LeavesOfBlocks' clean build" \
                       "Clean Build"
            ;;
        6)
            run_command "bundle exec fastlane ios test" \
                       "Run Tests via Fastlane"
            ;;
        7)
            echo -e "${YELLOW}This will deploy to TestFlight. Continue? (y/N)${NC}"
            read -n 1 -r confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                run_command "bundle exec fastlane ios beta" \
                           "Deploy Beta to TestFlight"
            fi
            ;;
        8)
            echo -e "${RED}This will deploy to the App Store! Continue? (y/N)${NC}"
            read -n 1 -r confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                run_command "bundle exec fastlane ios deploy" \
                           "Deploy to App Store"
            fi
            ;;
        9)
            run_command "bundle exec fastlane ios screenshots" \
                       "Generate Screenshots"
            ;;
        10)
            read -p "Enter version number (e.g., 1.0.4): " version
            run_command "bundle exec fastlane ios update_changelog version:$version" \
                       "Update Changelog for version $version"
            ;;
        11)
            run_command "./scripts/cleanup-project.sh --dry-run" \
                       "Preview Project Cleanup (Dry Run)"
            ;;
        12)
            echo -e "${RED}This will perform comprehensive cleanup and DELETE files! Continue? (y/N)${NC}"
            read -n 1 -r confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                run_command "./scripts/cleanup-project.sh" \
                           "Full Project Cleanup"
            fi
            ;;
        13)
            run_command "./scripts/generate_icons.sh" \
                       "Generate & Copy App Icons"
            ;;
        14)
            run_command "python3 ./scripts/generate_grass_images.py" \
                       "Generate Grass Images"
            ;;
        15)
            run_command "python3 ./scripts/create_app_clip_header.py" \
                       "Create App Clip Header"
            ;;
        16)
            echo -e "${BLUE}Opening project in Xcode...${NC}"
            open "LeavesOfBlocks.xcodeproj"
            ;;
        17)
            run_command "cat 'CLAUDE.md' | less" \
                       "View CLAUDE.md"
            ;;
        18)
            run_command "cat 'LeavesOfBlocks/Documentation/CodingStandards.md' | less" \
                       "View Coding Standards"
            ;;
        0)
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            echo "Press any key to continue..."
            read -n 1 -s
            ;;
    esac
done