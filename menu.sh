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

# Wait for any key. Branches that go through run_command get this for free;
# the standalone helpers (status check, ruby setup, etc.) call this directly.
pause() {
    echo -e "${GREEN}Press any key to continue...${NC}"
    read -n 1 -s
}

# Prompt for y/N. Returns 0 on y/Y, 1 otherwise. Pass $RED as the second
# arg for destructive actions (deploy, delete); default color is $YELLOW
# for routine confirmations.
confirm() {
    local msg=$1
    local color=${2:-$YELLOW}
    echo -e "${color}${msg} (y/N)${NC}"
    local reply
    read -n 1 -r reply
    echo
    [[ $reply =~ ^[Yy]$ ]]
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
    pause
}

# Reset state before a test run.
#
# Local test runs occasionally fail with "Application failed preflight checks"
# when a previous run left a simulator booted with a stale install, or when
# DerivedData has stale cached metadata about the bundle. This makes every
# test run start from a known-clean state:
#
# 1. Shut down all booted simulators.
# 2. Erase global DerivedData (the default xcodebuild location).
# 3. Erase project-local build/DerivedData — scripts/build.sh passes
#    `-derivedDataPath build/DerivedData`, and the XCBuildData manifests
#    inside bake in absolute paths, so a repo move (e.g. ~/Documents/...
#    → ~/Code/...) leaves stale paths that trip Xcode 26's "located
#    outside of the allowed root paths" check.
prepare_test_environment() {
    echo -e "${CYAN}Preparing test environment...${NC}"

    if xcrun simctl list devices booted 2>/dev/null | grep -q "(Booted)"; then
        echo -e "${YELLOW}  Shutting down booted simulator(s)...${NC}"
        xcrun simctl shutdown all 2>/dev/null || true
    else
        echo -e "${YELLOW}  No booted simulators.${NC}"
    fi

    local derived_pattern="$HOME/Library/Developer/Xcode/DerivedData/LeavesOfBlocks-*"
    if compgen -G "$derived_pattern" > /dev/null; then
        echo -e "${YELLOW}  Removing stale global DerivedData...${NC}"
        rm -rf $derived_pattern
    else
        echo -e "${YELLOW}  No stale global DerivedData.${NC}"
    fi

    if [ -d "$PROJECT_ROOT/build/DerivedData" ]; then
        echo -e "${YELLOW}  Removing stale project-local DerivedData...${NC}"
        rm -rf "$PROJECT_ROOT/build/DerivedData"
    else
        echo -e "${YELLOW}  No stale project-local DerivedData.${NC}"
    fi

    echo -e "${GREEN}  Environment ready.${NC}"
    echo ""
}

# Print a status report on the current development environment: macOS,
# Xcode, Ruby, Bundler, Homebrew, Fastlane, gem health, simulators, AI key.
show_env_status() {
    echo -e "${BLUE}=== Development Environment Status ===${NC}"
    echo ""

    echo -e "${CYAN}macOS Version:${NC}"
    sw_vers
    echo ""

    echo -e "${CYAN}Xcode Version:${NC}"
    if command -v xcodebuild &> /dev/null; then
        xcodebuild -version
        echo -e "${GREEN}✓ Xcode installed${NC}"
    else
        echo -e "${RED}✗ Xcode not found${NC}"
    fi
    echo ""

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

    echo -e "${CYAN}Bundler:${NC}"
    if command -v bundle &> /dev/null; then
        bundle --version
        echo -e "${GREEN}✓ Bundler installed${NC}"
    else
        echo -e "${RED}✗ Bundler not found${NC}"
    fi
    echo ""

    echo -e "${CYAN}Homebrew:${NC}"
    if command -v brew &> /dev/null; then
        echo "Homebrew $(brew --version | head -1)"
        echo -e "${GREEN}✓ Homebrew installed${NC}"
    else
        echo -e "${YELLOW}⚠ Homebrew not found (optional but recommended)${NC}"
    fi
    echo ""

    echo -e "${CYAN}Fastlane:${NC}"
    if bundle exec fastlane --version &> /dev/null 2>&1; then
        bundle exec fastlane --version 2>/dev/null | head -3
        echo -e "${GREEN}✓ Fastlane available via Bundler${NC}"
    else
        echo -e "${RED}✗ Fastlane not available (run 'bundle install')${NC}"
    fi
    echo ""

    echo -e "${CYAN}Ruby Gems Status:${NC}"
    local broken_gems
    broken_gems=$(gem list 2>&1 | grep -c "extensions are not built" || true)
    if [ "$broken_gems" -gt 0 ]; then
        echo -e "${RED}✗ Found gems with broken extensions${NC}"
        echo -e "${YELLOW}  Run option 21 'Repair Ruby Gems' to fix${NC}"
    else
        echo -e "${GREEN}✓ No broken gem extensions detected${NC}"
    fi
    echo ""

    echo -e "${CYAN}iOS Simulators (iPhone 17 variants):${NC}"
    xcrun simctl list devices available 2>/dev/null | grep "iPhone 17" || echo "No iPhone 17 simulators found"
    echo ""

    echo -e "${CYAN}AI Release Notes:${NC}"
    load_env
    if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
        echo -e "${GREEN}✓ ANTHROPIC_API_KEY configured${NC}"
        echo "  Key prefix: ${ANTHROPIC_API_KEY:0:10}..."
    else
        echo -e "${YELLOW}⚠ ANTHROPIC_API_KEY not set${NC}"
        echo "  AI release notes disabled (using template fallback)"
        echo "  Run option 22 to configure"
    fi
    echo ""

    pause
}

# Interactive Ruby setup via asdf: plugin install, version install + select,
# Bundler, bundle install, Overcommit hooks. Each step is gated on confirm.
setup_ruby_with_asdf() {
    echo -e "${BLUE}=== Ruby Setup with asdf ===${NC}"
    echo ""

    if ! command -v asdf &> /dev/null; then
        echo -e "${RED}asdf is not installed.${NC}"
        echo -e "${YELLOW}Install asdf first:${NC}"
        echo "  brew install asdf"
        echo "  Then add 'source \$(brew --prefix asdf)/libexec/asdf.sh' to your shell profile."
        echo ""
        pause
        return
    fi

    echo -e "${GREEN}✓ asdf is installed${NC}"
    echo "asdf version: $(asdf --version)"
    echo ""

    if ! asdf plugin list 2>/dev/null | grep -q "^ruby$"; then
        if confirm "asdf ruby plugin not installed. Install it now?"; then
            asdf plugin add ruby
            echo -e "${GREEN}✓ asdf ruby plugin installed${NC}"
        else
            echo "Skipping ruby plugin installation."
            pause
            return
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

    if confirm "Install a Ruby version?"; then
        echo -e "${CYAN}Enter Ruby version to install (e.g. 4.0.1, or 'latest'):${NC}"
        local ruby_version
        read -r ruby_version
        if [[ -n "$ruby_version" ]]; then
            echo -e "${BLUE}Installing Ruby $ruby_version (this may take a few minutes)...${NC}"
            asdf install ruby "$ruby_version"
            echo -e "${GREEN}✓ Ruby $ruby_version installed${NC}"

            echo ""
            if confirm "Set Ruby $ruby_version as the local version for this project?"; then
                asdf set ruby "$ruby_version"
                echo -e "${GREEN}✓ Set Ruby $ruby_version as local version${NC}"
            fi
        fi
    fi

    echo ""
    if confirm "Install/update Bundler?"; then
        gem install bundler
        echo -e "${GREEN}✓ Bundler installed${NC}"
    fi

    echo ""
    if confirm "Run 'bundle install' to install project dependencies?"; then
        bundle install
    fi

    echo ""
    if confirm "Install Overcommit git hooks for conventional commits?"; then
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
    pause
}

# Detect gems with unbuilt native extensions and offer rebuild paths
# (targeted gem pristine, then optional global gem pristine --all).
repair_ruby_gems() {
    echo -e "${BLUE}=== Repair Ruby Gems ===${NC}"
    echo ""
    echo -e "${YELLOW}This will attempt to rebuild gems with broken native extensions.${NC}"
    echo ""

    echo -e "${CYAN}Checking for broken gems...${NC}"
    local broken_output
    broken_output=$(gem list 2>&1)
    if echo "$broken_output" | grep -q "extensions are not built"; then
        echo -e "${RED}Found gems with broken extensions:${NC}"
        echo "$broken_output" | grep "extensions are not built"
        echo ""
    else
        echo -e "${GREEN}No broken gems detected!${NC}"
        echo ""
        pause
        return
    fi

    if confirm "Attempt to repair these gems?"; then
        echo -e "${BLUE}Repairing gems...${NC}"
        echo ""

        local gem_info gem_name gem_version
        for gem_info in "digest-crc:0.7.0" "json:2.7.6" "nkf:0.2.0" "sysrandom:1.0.5" "unf:0.2.0"; do
            gem_name="${gem_info%%:*}"
            gem_version="${gem_info##*:}"

            if gem list "$gem_name" 2>&1 | grep -q "extensions are not built"; then
                echo -e "${YELLOW}Repairing $gem_name $gem_version...${NC}"
                gem pristine "$gem_name" --version "$gem_version" 2>/dev/null || true
            fi
        done

        echo ""
        echo -e "${YELLOW}(This may require sudo for system Ruby)${NC}"
        if confirm "Run 'gem pristine --all' to repair all gems?"; then
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

        if confirm "Run 'bundle install' now?"; then
            bundle install
        fi
    fi

    echo ""
    pause
}

# Configure (or update) the Anthropic API key in fastlane/.env, used by
# the AI release-notes generator.
configure_ai_key() {
    echo -e "${BLUE}=== Configure AI API Key ===${NC}"
    echo ""
    echo -e "${CYAN}This configures the Anthropic API key for AI-powered release notes.${NC}"
    echo ""

    local env_file="$PROJECT_ROOT/fastlane/.env"

    load_env
    if [ -n "${ANTHROPIC_API_KEY:-}" ] && [ "$ANTHROPIC_API_KEY" != "your_anthropic_api_key_here" ]; then
        echo -e "${GREEN}Current status: API key is configured${NC}"
        echo "  Key prefix: ${ANTHROPIC_API_KEY:0:10}..."
        echo ""
        if ! confirm "Do you want to update the API key?"; then
            echo "Keeping existing configuration."
            pause
            return
        fi
    else
        echo -e "${YELLOW}Current status: API key not configured${NC}"
    fi

    echo ""
    echo -e "${CYAN}Enter your Anthropic API key:${NC}"
    echo "(Get one at https://console.anthropic.com/)"
    echo -n "> "
    local api_key
    read -r api_key

    if [ -z "$api_key" ]; then
        echo -e "${RED}No key entered. Configuration cancelled.${NC}"
        pause
        return
    fi

    if [ -f "$env_file" ]; then
        if grep -q "^ANTHROPIC_API_KEY=" "$env_file"; then
            sed -i '' "s/^ANTHROPIC_API_KEY=.*/ANTHROPIC_API_KEY=$api_key/" "$env_file"
        else
            echo "" >> "$env_file"
            echo "# Anthropic API Key for AI-powered release notes" >> "$env_file"
            echo "ANTHROPIC_API_KEY=$api_key" >> "$env_file"
        fi
    else
        if [ -f "$PROJECT_ROOT/fastlane/.env.template" ]; then
            cp "$PROJECT_ROOT/fastlane/.env.template" "$env_file"
            sed -i '' "s/^ANTHROPIC_API_KEY=.*/ANTHROPIC_API_KEY=$api_key/" "$env_file"
        else
            echo "# Anthropic API Key for AI-powered release notes" > "$env_file"
            echo "ANTHROPIC_API_KEY=$api_key" >> "$env_file"
        fi
    fi

    echo ""
    echo -e "${GREEN}✓ API key saved to fastlane/.env${NC}"
    echo ""

    if confirm "Test the AI release notes now?"; then
        load_env
        run_command "bundle exec fastlane ios test_ai" "Test AI Release Notes Generation"
    fi

    pause
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
    echo " 18) Generate App Icons (light + dark + tinted)"
    echo ""

    echo -e "${BLUE}Development Environment:${NC}"
    echo " 19) Check Environment Status"
    echo " 20) Setup Ruby (asdf)"
    echo " 21) Repair Ruby Gems"
    echo " 22) Configure AI API Key"
    echo ""

    echo -e "${BLUE}Other:${NC}"
    echo " 23) Open in Xcode"
    echo " 24) Run in Simulator (without Xcode)"
    echo " 25) View CLAUDE.md"
    echo " 26) View Coding Standards"
    echo ""

    echo -e "${RED}  0) Exit${NC}"
    echo ""

    read -p "Select an option: " choice

    case $choice in
        1)
            run_command "./scripts/build.sh build" "Build for Simulator"
            ;;
        2)
            prepare_test_environment
            run_command "./scripts/build.sh test" "Run All Tests"
            ;;
        3)
            prepare_test_environment
            run_command "./scripts/build.sh test-unit" "Run Unit Tests Only"
            ;;
        4)
            prepare_test_environment
            run_command "./scripts/build.sh test-ui" "Run UI Tests Only"
            ;;
        5)
            run_command "./scripts/build.sh clean" "Clean Build"
            ;;
        6)
            prepare_test_environment
            load_env
            run_command "bundle exec fastlane ios test" "Run Tests via Fastlane"
            ;;
        7)
            if confirm "This will deploy to TestFlight."; then
                load_env
                run_command "bundle exec fastlane ios beta" "Deploy Beta to TestFlight"
            fi
            ;;
        8)
            if confirm "This will deploy to the App Store with a new patch version!" "$RED"; then
                load_env
                run_command "bundle exec fastlane ios deploy version:patch" \
                            "Deploy to App Store (version bump: patch)"
            fi
            ;;
        9)
            if confirm "This will deploy AND submit for App Store review with a new patch version!" "$RED"; then
                load_env
                run_command "bundle exec fastlane ios deploy_and_submit version:patch" \
                            "Deploy & Submit for App Store Review (version bump: patch)"
            fi
            ;;
        10)
            load_env
            run_command "bundle exec fastlane ios screenshots" "Generate Screenshots"
            ;;
        11)
            load_env
            run_command "bundle exec fastlane ios test_api_auth" \
                        "Test App Store Connect API Authentication"
            ;;
        12)
            if confirm "This will submit an existing build for App Store review!" "$RED"; then
                load_env
                run_command "bundle exec fastlane ios submit" "Submit Existing Build for Review"
            fi
            ;;
        13)
            if confirm "This will upload metadata only (no binary)."; then
                load_env
                run_command "bundle exec fastlane ios metadata_only" "Upload Metadata Only"
            fi
            ;;
        14)
            if confirm "This will upload screenshots only."; then
                load_env
                run_command "bundle exec fastlane ios screenshots_only" "Upload Screenshots Only"
            fi
            ;;
        15)
            load_env
            run_command "bundle exec fastlane ios test_ai" "Test AI Release Notes Generation"
            ;;
        16)
            run_command "./scripts/cleanup-project.sh --dry-run" "Preview Project Cleanup (Dry Run)"
            ;;
        17)
            if confirm "This will perform comprehensive cleanup and DELETE files!" "$RED"; then
                run_command "./scripts/cleanup-project.sh" "Full Project Cleanup (includes Fastlane clean)"
            fi
            ;;
        18)
            run_command "./scripts/generate_icons.sh" \
                        "Generate App Icons from whitman-logo.svg (light + dark + tinted)"
            ;;
        19)
            show_env_status
            ;;
        20)
            setup_ruby_with_asdf
            ;;
        21)
            repair_ruby_gems
            ;;
        22)
            configure_ai_key
            ;;
        23)
            echo -e "${BLUE}Opening project in Xcode...${NC}"
            open "LeavesOfBlocks.xcodeproj"
            ;;
        24)
            run_command "./scripts/build.sh run" "Run in Simulator (without Xcode)"
            ;;
        25)
            run_command "cat 'CLAUDE.md' | less" "View CLAUDE.md"
            ;;
        26)
            run_command "cat 'LeavesOfBlocks/Documentation/CodingStandards.md' | less" "View Coding Standards"
            ;;
        0)
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            pause
            ;;
    esac
done
