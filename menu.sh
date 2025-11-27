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
    echo "  9) Deploy & Submit for Review"
    echo " 10) Generate Screenshots"
    echo ""
    
    echo -e "${BLUE}Advanced Fastlane:${NC}"
    echo " 11) Test App Store Connect API Auth"
    echo " 12) Submit for Review (existing build)"
    echo " 13) Upload Metadata Only"
    echo " 14) Upload Screenshots Only"
    echo ""
    
    echo -e "${BLUE}Maintenance:${NC}"
    echo " 15) Project Cleanup (Dry Run)"
    echo " 16) Project Cleanup (Delete)"
    echo ""
    
    echo -e "${BLUE}Asset Generation:${NC}"
    echo " 17) Generate & Copy App Icons"
    echo " 18) Generate Grass Images"
    echo ""
    
    echo -e "${BLUE}Development Environment:${NC}"
    echo " 19) Check Environment Status"
    echo " 20) Setup Ruby (rbenv)"
    echo " 21) Repair Ruby Gems"
    echo ""

    echo -e "${BLUE}Other:${NC}"
    echo " 22) Open in Xcode"
    echo " 23) View CLAUDE.md"
    echo " 24) View Coding Standards"
    echo ""

    echo -e "${RED}  0) Exit${NC}"
    echo ""
    
    read -p "Select an option: " choice
    
    case $choice in
        1)
            run_command "./scripts/build.sh build" \
                       "Build for Simulator"
            ;;
        2)
            run_command "./scripts/build.sh test" \
                       "Run All Tests"
            ;;
        3)
            run_command "./scripts/build.sh test-unit" \
                       "Run Unit Tests Only"
            ;;
        4)
            run_command "./scripts/build.sh test-ui" \
                       "Run UI Tests Only"
            ;;
        5)
            run_command "./scripts/build.sh clean" \
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
            echo -e "${RED}This will deploy to the App Store with a new patch version! Continue? (y/N)${NC}"
            read -n 1 -r confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                run_command "bundle exec fastlane ios deploy version:patch" \
                           "Deploy to App Store (version bump: patch)"
            fi
            ;;
        9)
            echo -e "${RED}This will deploy AND submit for App Store review with a new patch version! Continue? (y/N)${NC}"
            read -n 1 -r confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                run_command "bundle exec fastlane ios deploy_and_submit version:patch" \
                           "Deploy & Submit for App Store Review (version bump: patch)"
            fi
            ;;
        10)
            run_command "bundle exec fastlane ios screenshots" \
                       "Generate Screenshots"
            ;;
        11)
            run_command "bundle exec fastlane ios test_api_auth" \
                       "Test App Store Connect API Authentication"
            ;;
        12)
            echo -e "${RED}This will submit an existing build for App Store review! Continue? (y/N)${NC}"
            read -n 1 -r confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                run_command "bundle exec fastlane ios submit" \
                           "Submit Existing Build for Review"
            fi
            ;;
        13)
            echo -e "${YELLOW}This will upload metadata only (no binary). Continue? (y/N)${NC}"
            read -n 1 -r confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                run_command "bundle exec fastlane ios metadata_only" \
                           "Upload Metadata Only"
            fi
            ;;
        14)
            echo -e "${YELLOW}This will upload screenshots only. Continue? (y/N)${NC}"
            read -n 1 -r confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                run_command "bundle exec fastlane ios screenshots_only" \
                           "Upload Screenshots Only"
            fi
            ;;
        15)
            run_command "./scripts/cleanup-project.sh --dry-run" \
                       "Preview Project Cleanup (Dry Run)"
            ;;
        16)
            echo -e "${RED}This will perform comprehensive cleanup and DELETE files! Continue? (y/N)${NC}"
            read -n 1 -r confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                run_command "./scripts/cleanup-project.sh" \
                           "Full Project Cleanup (includes Fastlane clean)"
            fi
            ;;
        17)
            run_command "./scripts/generate_icons.sh" \
                       "Generate & Copy App Icons"
            ;;
        18)
            run_command "python3 ./scripts/generate_grass_images.py" \
                       "Generate Grass Images"
            ;;
        19)
            # Environment Status Check
            echo -e "${BLUE}=== Development Environment Status ===${NC}"
            echo ""

            # macOS version
            echo -e "${CYAN}macOS Version:${NC}"
            sw_vers
            echo ""

            # Xcode version
            echo -e "${CYAN}Xcode Version:${NC}"
            if command -v xcodebuild &> /dev/null; then
                xcodebuild -version
                echo -e "${GREEN}✓ Xcode installed${NC}"
            else
                echo -e "${RED}✗ Xcode not found${NC}"
            fi
            echo ""

            # Ruby version and type
            echo -e "${CYAN}Ruby Environment:${NC}"
            echo -n "Ruby version: "
            ruby --version
            echo -n "Ruby path: "
            which ruby
            if [[ "$(which ruby)" == "/usr/bin/ruby" ]]; then
                echo -e "${YELLOW}⚠ Using system Ruby (not recommended)${NC}"
                echo -e "${YELLOW}  Consider using rbenv for better compatibility${NC}"
            elif command -v rbenv &> /dev/null; then
                echo -e "${GREEN}✓ Using rbenv-managed Ruby${NC}"
                echo "rbenv version: $(rbenv --version)"
            else
                echo -e "${GREEN}✓ Using non-system Ruby${NC}"
            fi
            echo ""

            # Bundler
            echo -e "${CYAN}Bundler:${NC}"
            if command -v bundle &> /dev/null; then
                bundle --version
                echo -e "${GREEN}✓ Bundler installed${NC}"
            else
                echo -e "${RED}✗ Bundler not found${NC}"
            fi
            echo ""

            # Homebrew
            echo -e "${CYAN}Homebrew:${NC}"
            if command -v brew &> /dev/null; then
                echo "Homebrew $(brew --version | head -1)"
                echo -e "${GREEN}✓ Homebrew installed${NC}"
            else
                echo -e "${YELLOW}⚠ Homebrew not found (optional but recommended)${NC}"
            fi
            echo ""

            # Fastlane
            echo -e "${CYAN}Fastlane:${NC}"
            if bundle exec fastlane --version &> /dev/null 2>&1; then
                bundle exec fastlane --version 2>/dev/null | head -3
                echo -e "${GREEN}✓ Fastlane available via Bundler${NC}"
            else
                echo -e "${RED}✗ Fastlane not available (run 'bundle install')${NC}"
            fi
            echo ""

            # Check for broken gems
            echo -e "${CYAN}Ruby Gems Status:${NC}"
            broken_gems=$(gem list 2>&1 | grep -c "extensions are not built" || true)
            if [ "$broken_gems" -gt 0 ]; then
                echo -e "${RED}✗ Found gems with broken extensions${NC}"
                echo -e "${YELLOW}  Run option 21 'Repair Ruby Gems' to fix${NC}"
            else
                echo -e "${GREEN}✓ No broken gem extensions detected${NC}"
            fi
            echo ""

            # iOS Simulators
            echo -e "${CYAN}iOS Simulators (iPhone 16 variants):${NC}"
            xcrun simctl list devices available 2>/dev/null | grep "iPhone 16" || echo "No iPhone 16 simulators found"
            echo ""

            echo -e "${GREEN}Press any key to continue...${NC}"
            read -n 1 -s
            ;;
        20)
            # Setup Ruby with rbenv
            echo -e "${BLUE}=== Ruby Setup with rbenv ===${NC}"
            echo ""

            # Check if Homebrew is installed
            if ! command -v brew &> /dev/null; then
                echo -e "${RED}Homebrew is required but not installed.${NC}"
                echo -e "${YELLOW}Install Homebrew first:${NC}"
                echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
                echo ""
                echo -e "${GREEN}Press any key to continue...${NC}"
                read -n 1 -s
                continue
            fi

            # Check if rbenv is already installed
            if command -v rbenv &> /dev/null; then
                echo -e "${GREEN}✓ rbenv is already installed${NC}"
                rbenv --version
                echo ""
                echo "Current Ruby versions installed:"
                rbenv versions
                echo ""
            else
                echo -e "${YELLOW}rbenv is not installed. Install it now? (y/N)${NC}"
                read -n 1 -r confirm
                echo
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    echo -e "${BLUE}Installing rbenv and ruby-build...${NC}"
                    brew install rbenv ruby-build

                    echo ""
                    echo -e "${YELLOW}Adding rbenv to shell profile...${NC}"

                    # Detect shell and add to appropriate profile
                    if [[ "$SHELL" == *"zsh"* ]]; then
                        PROFILE="$HOME/.zshrc"
                    else
                        PROFILE="$HOME/.bash_profile"
                    fi

                    if ! grep -q 'rbenv init' "$PROFILE" 2>/dev/null; then
                        echo '' >> "$PROFILE"
                        echo '# rbenv' >> "$PROFILE"
                        echo 'eval "$(rbenv init -)"' >> "$PROFILE"
                        echo -e "${GREEN}Added rbenv init to $PROFILE${NC}"
                    else
                        echo -e "${GREEN}rbenv init already in $PROFILE${NC}"
                    fi

                    # Initialize rbenv for current session
                    eval "$(rbenv init -)"
                else
                    echo "Skipping rbenv installation."
                    echo -e "${GREEN}Press any key to continue...${NC}"
                    read -n 1 -s
                    continue
                fi
            fi

            # Offer to install Ruby 3.3.x
            echo -e "${YELLOW}Install Ruby 3.3.6 (recommended for this project)? (y/N)${NC}"
            read -n 1 -r confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                echo -e "${BLUE}Installing Ruby 3.3.6 (this may take a few minutes)...${NC}"
                rbenv install 3.3.6 --skip-existing

                echo ""
                echo -e "${YELLOW}Set Ruby 3.3.6 as the local version for this project? (y/N)${NC}"
                read -n 1 -r confirm2
                echo
                if [[ $confirm2 =~ ^[Yy]$ ]]; then
                    rbenv local 3.3.6
                    echo -e "${GREEN}✓ Set Ruby 3.3.6 as local version${NC}"
                fi
            fi

            # Rehash and install bundler
            echo ""
            echo -e "${BLUE}Rehashing rbenv shims...${NC}"
            rbenv rehash

            echo ""
            echo -e "${YELLOW}Install/update Bundler? (y/N)${NC}"
            read -n 1 -r confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                gem install bundler
                echo -e "${GREEN}✓ Bundler installed${NC}"
            fi

            # Run bundle install
            echo ""
            echo -e "${YELLOW}Run 'bundle install' to install project dependencies? (y/N)${NC}"
            read -n 1 -r confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                bundle install
            fi

            echo ""
            echo -e "${GREEN}Ruby setup complete!${NC}"
            echo -e "${YELLOW}Note: You may need to restart your terminal for changes to take effect.${NC}"
            echo ""
            echo -e "${GREEN}Press any key to continue...${NC}"
            read -n 1 -s
            ;;
        21)
            # Repair Ruby Gems
            echo -e "${BLUE}=== Repair Ruby Gems ===${NC}"
            echo ""
            echo -e "${YELLOW}This will attempt to rebuild gems with broken native extensions.${NC}"
            echo ""

            # List broken gems
            echo -e "${CYAN}Checking for broken gems...${NC}"
            broken_output=$(gem list 2>&1)
            if echo "$broken_output" | grep -q "extensions are not built"; then
                echo -e "${RED}Found gems with broken extensions:${NC}"
                echo "$broken_output" | grep "extensions are not built"
                echo ""
            else
                echo -e "${GREEN}No broken gems detected!${NC}"
                echo ""
                echo -e "${GREEN}Press any key to continue...${NC}"
                read -n 1 -s
                continue
            fi

            echo -e "${YELLOW}Attempt to repair these gems? (y/N)${NC}"
            read -n 1 -r confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                echo -e "${BLUE}Repairing gems...${NC}"
                echo ""

                # Try to repair common problematic gems
                for gem_info in "digest-crc:0.7.0" "json:2.7.6" "nkf:0.2.0" "sysrandom:1.0.5" "unf:0.2.0"; do
                    gem_name="${gem_info%%:*}"
                    gem_version="${gem_info##*:}"

                    if gem list "$gem_name" 2>&1 | grep -q "extensions are not built"; then
                        echo -e "${YELLOW}Repairing $gem_name $gem_version...${NC}"
                        gem pristine "$gem_name" --version "$gem_version" 2>/dev/null || true
                    fi
                done

                # Also try repairing all gems
                echo ""
                echo -e "${YELLOW}Run 'gem pristine --all' to repair all gems? (y/N)${NC}"
                echo -e "${YELLOW}(This may require sudo for system Ruby)${NC}"
                read -n 1 -r confirm2
                echo
                if [[ $confirm2 =~ ^[Yy]$ ]]; then
                    if [[ "$(which ruby)" == "/usr/bin/ruby" ]]; then
                        echo -e "${YELLOW}Using system Ruby - running with sudo...${NC}"
                        sudo gem pristine --all
                    else
                        gem pristine --all
                    fi
                fi

                echo ""
                echo -e "${GREEN}Gem repair complete!${NC}"
                echo ""

                # Suggest bundle install
                echo -e "${YELLOW}Run 'bundle install' now? (y/N)${NC}"
                read -n 1 -r confirm3
                echo
                if [[ $confirm3 =~ ^[Yy]$ ]]; then
                    bundle install
                fi
            fi

            echo ""
            echo -e "${GREEN}Press any key to continue...${NC}"
            read -n 1 -s
            ;;
        22)
            echo -e "${BLUE}Opening project in Xcode...${NC}"
            open "LeavesOfBlocks.xcodeproj"
            ;;
        23)
            run_command "cat 'CLAUDE.md' | less" \
                       "View CLAUDE.md"
            ;;
        24)
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