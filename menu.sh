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

# Load environment variables from .env files
load_env() {
    # Load fastlane/.env if exists (contains API keys)
    if [ -f "$PROJECT_ROOT/fastlane/.env" ]; then
        echo -e "${CYAN}Loading fastlane/.env...${NC}"
        set -a  # automatically export all variables
        source "$PROJECT_ROOT/fastlane/.env"
        set +a
    fi
}

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
    echo " 15) Test AI Release Notes"
    echo ""
    
    echo -e "${BLUE}Maintenance:${NC}"
    echo " 16) Project Cleanup (Dry Run)"
    echo " 17) Project Cleanup (Delete)"
    echo ""

    echo -e "${BLUE}Asset Generation:${NC}"
    echo " 18) Generate & Copy App Icons"
    echo " 19) Generate Grass Images"
    echo ""

    echo -e "${BLUE}Development Environment:${NC}"
    echo " 20) Check Environment Status"
    echo " 21) Setup Ruby (asdf)"
    echo " 22) Repair Ruby Gems"
    echo " 23) Configure AI API Key"
    echo ""

    echo -e "${BLUE}Other:${NC}"
    echo " 24) Open in Xcode"
    echo " 25) Run in Simulator (without Xcode)"
    echo " 26) View CLAUDE.md"
    echo " 27) View Coding Standards"
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
            load_env
            run_command "bundle exec fastlane ios test" \
                       "Run Tests via Fastlane"
            ;;
        7)
            echo -e "${YELLOW}This will deploy to TestFlight. Continue? (y/N)${NC}"
            read -n 1 -r confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                load_env
                run_command "bundle exec fastlane ios beta" \
                           "Deploy Beta to TestFlight"
            fi
            ;;
        8)
            echo -e "${RED}This will deploy to the App Store with a new patch version! Continue? (y/N)${NC}"
            read -n 1 -r confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                load_env
                run_command "bundle exec fastlane ios deploy version:patch" \
                           "Deploy to App Store (version bump: patch)"
            fi
            ;;
        9)
            echo -e "${RED}This will deploy AND submit for App Store review with a new patch version! Continue? (y/N)${NC}"
            read -n 1 -r confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                load_env
                run_command "bundle exec fastlane ios deploy_and_submit version:patch" \
                           "Deploy & Submit for App Store Review (version bump: patch)"
            fi
            ;;
        10)
            load_env
            run_command "bundle exec fastlane ios screenshots" \
                       "Generate Screenshots"
            ;;
        11)
            load_env
            run_command "bundle exec fastlane ios test_api_auth" \
                       "Test App Store Connect API Authentication"
            ;;
        12)
            echo -e "${RED}This will submit an existing build for App Store review! Continue? (y/N)${NC}"
            read -n 1 -r confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                load_env
                run_command "bundle exec fastlane ios submit" \
                           "Submit Existing Build for Review"
            fi
            ;;
        13)
            echo -e "${YELLOW}This will upload metadata only (no binary). Continue? (y/N)${NC}"
            read -n 1 -r confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                load_env
                run_command "bundle exec fastlane ios metadata_only" \
                           "Upload Metadata Only"
            fi
            ;;
        14)
            echo -e "${YELLOW}This will upload screenshots only. Continue? (y/N)${NC}"
            read -n 1 -r confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                load_env
                run_command "bundle exec fastlane ios screenshots_only" \
                           "Upload Screenshots Only"
            fi
            ;;
        15)
            load_env
            run_command "bundle exec fastlane ios test_ai" \
                       "Test AI Release Notes Generation"
            ;;
        16)
            run_command "./scripts/cleanup-project.sh --dry-run" \
                       "Preview Project Cleanup (Dry Run)"
            ;;
        17)
            echo -e "${RED}This will perform comprehensive cleanup and DELETE files! Continue? (y/N)${NC}"
            read -n 1 -r confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                run_command "./scripts/cleanup-project.sh" \
                           "Full Project Cleanup (includes Fastlane clean)"
            fi
            ;;
        18)
            run_command "./scripts/generate_icons.sh" \
                       "Generate & Copy App Icons"
            ;;
        19)
            run_command "python3 ./scripts/generate_grass_images.py" \
                       "Generate Grass Images"
            ;;
        20)
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
                echo -e "${YELLOW}  Consider using asdf for better compatibility${NC}"
            elif command -v asdf &> /dev/null && asdf current ruby &> /dev/null 2>&1; then
                echo -e "${GREEN}✓ Using asdf-managed Ruby${NC}"
                echo "asdf version: $(asdf --version)"
                echo "Active Ruby: $(asdf current ruby 2>/dev/null)"
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

            # AI Release Notes Configuration
            echo -e "${CYAN}AI Release Notes:${NC}"
            load_env
            if [ -n "$ANTHROPIC_API_KEY" ]; then
                echo -e "${GREEN}✓ ANTHROPIC_API_KEY configured${NC}"
                echo "  Key prefix: ${ANTHROPIC_API_KEY:0:10}..."
            else
                echo -e "${YELLOW}⚠ ANTHROPIC_API_KEY not set${NC}"
                echo "  AI release notes disabled (using template fallback)"
                echo "  Run option 23 to configure"
            fi
            echo ""

            echo -e "${GREEN}Press any key to continue...${NC}"
            read -n 1 -s
            ;;
        21)
            # Setup Ruby with asdf
            echo -e "${BLUE}=== Ruby Setup with asdf ===${NC}"
            echo ""

            # Check if asdf is installed
            if ! command -v asdf &> /dev/null; then
                echo -e "${RED}asdf is not installed.${NC}"
                echo -e "${YELLOW}Install asdf first:${NC}"
                echo "  brew install asdf"
                echo "  Then add 'source \$(brew --prefix asdf)/libexec/asdf.sh' to your shell profile."
                echo ""
                echo -e "${GREEN}Press any key to continue...${NC}"
                read -n 1 -s
                continue
            fi

            echo -e "${GREEN}✓ asdf is installed${NC}"
            echo "asdf version: $(asdf --version)"
            echo ""

            # Check if ruby plugin is installed
            if ! asdf plugin list 2>/dev/null | grep -q "^ruby$"; then
                echo -e "${YELLOW}asdf ruby plugin not installed. Install it now? (y/N)${NC}"
                read -n 1 -r confirm
                echo
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    asdf plugin add ruby
                    echo -e "${GREEN}✓ asdf ruby plugin installed${NC}"
                else
                    echo "Skipping ruby plugin installation."
                    echo -e "${GREEN}Press any key to continue...${NC}"
                    read -n 1 -s
                    continue
                fi
            else
                echo -e "${GREEN}✓ asdf ruby plugin installed${NC}"
            fi

            echo ""
            echo "Currently installed Ruby versions:"
            asdf list ruby 2>/dev/null || echo "  (none)"
            echo ""
            echo "Active Ruby: $(asdf current ruby 2>/dev/null)"
            echo ""

            # Offer to install a Ruby version
            echo -e "${YELLOW}Install a Ruby version? (y/N)${NC}"
            read -n 1 -r confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                echo -e "${CYAN}Enter Ruby version to install (e.g. 4.0.1, or 'latest'):${NC}"
                read -r ruby_version
                if [[ -n "$ruby_version" ]]; then
                    echo -e "${BLUE}Installing Ruby $ruby_version (this may take a few minutes)...${NC}"
                    asdf install ruby "$ruby_version"
                    echo -e "${GREEN}✓ Ruby $ruby_version installed${NC}"

                    echo ""
                    echo -e "${YELLOW}Set Ruby $ruby_version as the local version for this project? (y/N)${NC}"
                    read -n 1 -r confirm2
                    echo
                    if [[ $confirm2 =~ ^[Yy]$ ]]; then
                        asdf set ruby "$ruby_version"
                        echo -e "${GREEN}✓ Set Ruby $ruby_version as local version${NC}"
                    fi
                fi
            fi

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

            # Install Overcommit git hooks
            echo ""
            echo -e "${YELLOW}Install Overcommit git hooks for conventional commits? (y/N)${NC}"
            read -n 1 -r confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                echo -e "${BLUE}Installing Overcommit hooks...${NC}"
                bundle exec overcommit --install
                bundle exec overcommit --sign
                echo -e "${GREEN}✓ Overcommit hooks installed${NC}"
                echo ""
                echo -e "${CYAN}Commit messages must now follow Conventional Commits format:${NC}"
                echo "  feat: Add new feature"
                echo "  fix: Fix a bug"
                echo "  docs: Update documentation"
                echo "  refactor: Refactor code"
                echo "  chore: Maintenance tasks"
            fi

            echo ""
            echo -e "${GREEN}Ruby setup complete!${NC}"
            echo -e "${YELLOW}Note: You may need to restart your terminal for changes to take effect.${NC}"
            echo ""
            echo -e "${GREEN}Press any key to continue...${NC}"
            read -n 1 -s
            ;;
        22)
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
        23)
            # Configure AI API Key
            echo -e "${BLUE}=== Configure AI API Key ===${NC}"
            echo ""
            echo -e "${CYAN}This configures the Anthropic API key for AI-powered release notes.${NC}"
            echo ""

            ENV_FILE="$PROJECT_ROOT/fastlane/.env"

            # Check current status
            load_env
            if [ -n "$ANTHROPIC_API_KEY" ] && [ "$ANTHROPIC_API_KEY" != "your_anthropic_api_key_here" ]; then
                echo -e "${GREEN}Current status: API key is configured${NC}"
                echo "  Key prefix: ${ANTHROPIC_API_KEY:0:10}..."
                echo ""
                echo -e "${YELLOW}Do you want to update the API key? (y/N)${NC}"
                read -n 1 -r confirm
                echo
                if [[ ! $confirm =~ ^[Yy]$ ]]; then
                    echo "Keeping existing configuration."
                    echo -e "${GREEN}Press any key to continue...${NC}"
                    read -n 1 -s
                    continue
                fi
            else
                echo -e "${YELLOW}Current status: API key not configured${NC}"
            fi

            echo ""
            echo -e "${CYAN}Enter your Anthropic API key:${NC}"
            echo "(Get one at https://console.anthropic.com/)"
            echo -n "> "
            read -r api_key

            if [ -z "$api_key" ]; then
                echo -e "${RED}No key entered. Configuration cancelled.${NC}"
                echo -e "${GREEN}Press any key to continue...${NC}"
                read -n 1 -s
                continue
            fi

            # Create or update .env file
            if [ -f "$ENV_FILE" ]; then
                # Update existing file
                if grep -q "^ANTHROPIC_API_KEY=" "$ENV_FILE"; then
                    # Replace existing key
                    sed -i '' "s/^ANTHROPIC_API_KEY=.*/ANTHROPIC_API_KEY=$api_key/" "$ENV_FILE"
                else
                    # Add new key
                    echo "" >> "$ENV_FILE"
                    echo "# Anthropic API Key for AI-powered release notes" >> "$ENV_FILE"
                    echo "ANTHROPIC_API_KEY=$api_key" >> "$ENV_FILE"
                fi
            else
                # Create new file from example
                if [ -f "$PROJECT_ROOT/fastlane/.env.example" ]; then
                    cp "$PROJECT_ROOT/fastlane/.env.example" "$ENV_FILE"
                    sed -i '' "s/^ANTHROPIC_API_KEY=.*/ANTHROPIC_API_KEY=$api_key/" "$ENV_FILE"
                else
                    # Create minimal file
                    echo "# Anthropic API Key for AI-powered release notes" > "$ENV_FILE"
                    echo "ANTHROPIC_API_KEY=$api_key" >> "$ENV_FILE"
                fi
            fi

            echo ""
            echo -e "${GREEN}✓ API key saved to fastlane/.env${NC}"
            echo ""

            # Test the key
            echo -e "${YELLOW}Test the AI release notes now? (y/N)${NC}"
            read -n 1 -r confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                load_env
                run_command "bundle exec fastlane ios test_ai" \
                           "Test AI Release Notes Generation"
            fi

            echo -e "${GREEN}Press any key to continue...${NC}"
            read -n 1 -s
            ;;
        24)
            echo -e "${BLUE}Opening project in Xcode...${NC}"
            open "LeavesOfBlocks.xcodeproj"
            ;;
        25)
            run_command "./scripts/build.sh run" \
                       "Run in Simulator (without Xcode)"
            ;;
        26)
            run_command "cat 'CLAUDE.md' | less" \
                       "View CLAUDE.md"
            ;;
        27)
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