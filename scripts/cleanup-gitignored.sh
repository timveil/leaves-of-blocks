#!/bin/bash
#
# cleanup-gitignored.sh
# Removes ignored files from the project root directory only
# Subdirectories are cleaned by Xcode and Fastlane commands
# Usage: ./cleanup-gitignored.sh [--dry-run]
#

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DRY_RUN=false
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run, -n    Show what would be deleted without actually deleting"
            echo "  --verbose, -v    Show detailed output"
            echo "  --help, -h       Show this help message"
            echo ""
            echo "This script removes ignored files from the project root directory only."
            echo "Subdirectories are cleaned using Xcode and Fastlane commands."
            echo "It respects your .gitignore patterns and Git's ignore rules."
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check if we're in a Git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a Git repository${NC}"
    exit 1
fi

# Function to format file size
format_size() {
    local size=$1
    if [ $size -ge 1048576 ]; then
        echo "$(( size / 1048576 ))MB"
    elif [ $size -ge 1024 ]; then
        echo "$(( size / 1024 ))KB"
    else
        echo "${size}B"
    fi
}

# Function to get file/directory size
get_size() {
    local path=$1
    if [ -d "$path" ]; then
        # For directories, use du
        if command -v gdu > /dev/null 2>&1; then
            # Use GNU du if available (macOS with coreutils)
            gdu -sb "$path" 2>/dev/null | cut -f1 | grep -o '^[0-9]*' || echo 0
        else
            # Fall back to BSD du - get first field and ensure it's numeric
            du -sk "$path" 2>/dev/null | awk '{print $1}' | grep -o '^[0-9]*' | awk '{print $1 * 1024}' || echo 0
        fi
    else
        # For files, use stat
        if stat -f%z "$path" 2>/dev/null; then
            # BSD stat (macOS)
            stat -f%z "$path" | grep -o '^[0-9]*' || echo 0
        else
            # GNU stat
            stat -c%s "$path" | grep -o '^[0-9]*' || echo 0
        fi
    fi
}

echo -e "${BLUE}=== Git Ignored Files Cleanup ===${NC}"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}DRY RUN MODE: No files will be deleted${NC}"
else
    echo -e "${RED}WARNING: This will DELETE ignored files permanently!${NC}"
    echo -e "${RED}Consider running with --dry-run first to preview changes.${NC}"
    read -p "Are you sure you want to continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

# Run clean commands only if not in dry-run mode
if [ "$DRY_RUN" = false ]; then
    echo ""
    echo -e "${BLUE}Running Xcode and Fastlane clean commands...${NC}"

    # Clean Xcode build artifacts
    if ls *.xcodeproj 1> /dev/null 2>&1 || ls *.xcworkspace 1> /dev/null 2>&1; then
        echo "- Cleaning Xcode build artifacts..."
        xcodebuild clean -quiet 2>/dev/null || true
    fi

    # Clean Fastlane artifacts
    if [ -f "fastlane/Fastfile" ]; then
        echo "- Cleaning Fastlane artifacts..."
        if command -v bundle > /dev/null 2>&1 && [ -f "Gemfile" ]; then
            bundle exec fastlane run clean_build_artifacts skip_package_ipa:true 2>/dev/null || true
        elif command -v fastlane > /dev/null 2>&1; then
            fastlane run clean_build_artifacts skip_package_ipa:true 2>/dev/null || true
        fi
    fi

    # Remove derived data if in project directory
    if [ -d "build/" ]; then
        echo "- Removing build directory..."
        rm -rf build/ 2>/dev/null || true
    fi

    if [ -d "DerivedData/" ]; then
        echo "- Removing DerivedData directory..."
        rm -rf DerivedData/ 2>/dev/null || true
    fi
fi

echo ""
echo -e "${BLUE}Scanning for ignored files in project root directory only...${NC}"

# Get list of ignored files from Git - only in root directory
# Use git ls-files to find ignored files that exist, then filter for root-level only
ignored_files=$(git ls-files --others --ignored --exclude-standard 2>/dev/null | grep -v '/' || true)

# Also check for ignored directories in root only using git clean
# git clean -ndX shows ignored files/dirs that would be removed
ignored_dirs=$(git clean -ndX -d . 2>/dev/null | sed 's/^Would remove //' | grep -v '/' || true)

# Combine and deduplicate root-level items only
all_ignored=$(echo -e "$ignored_files\n$ignored_dirs" | sort -u | grep -v '^$' || true)

if [ -z "$all_ignored" ]; then
    echo -e "${GREEN}No ignored files found. Project is clean!${NC}"
    exit 0
fi

# Count and calculate total size
file_count=0
dir_count=0
total_size=0
files_to_delete=()

echo ""
echo -e "${BLUE}Found ignored items:${NC}"
echo ""

while IFS= read -r item; do
    if [ -e "$item" ]; then
        size=$(get_size "$item")
        # Ensure size is a valid number
        if ! [[ "$size" =~ ^[0-9]+$ ]]; then
            size=0
        fi
        total_size=$((total_size + size))
        formatted_size=$(format_size $size)
        
        if [ -d "$item" ]; then
            dir_count=$((dir_count + 1))
            echo -e "${YELLOW}📁 Directory:${NC} $item ${BLUE}($formatted_size)${NC}"
            if [ "$VERBOSE" = true ]; then
                # Show directory contents
                find "$item" -type f 2>/dev/null | head -10 | sed 's/^/    /'
                file_count_in_dir=$(find "$item" -type f 2>/dev/null | wc -l | tr -d ' ')
                if [ "$file_count_in_dir" -gt 10 ]; then
                    echo "    ... and $((file_count_in_dir - 10)) more files"
                fi
            fi
        else
            file_count=$((file_count + 1))
            echo -e "${YELLOW}📄 File:${NC} $item ${BLUE}($formatted_size)${NC}"
        fi
        files_to_delete+=("$item")
    fi
done <<< "$all_ignored"

# Summary
echo ""
echo -e "${BLUE}Summary:${NC}"
echo "- Files: $file_count"
echo "- Directories: $dir_count"
echo "- Total size: $(format_size $total_size)"

# Special warnings for common important files
important_patterns=(
    ".env"
    "fastlane/report.xml"
    "*.ipa"
    "*.dSYM"
    "xcuserdata"
)

found_important=false
for pattern in "${important_patterns[@]}"; do
    for item in "${files_to_delete[@]}"; do
        if [[ "$item" == *"$pattern"* ]]; then
            if [ "$found_important" = false ]; then
                echo ""
                echo -e "${YELLOW}⚠️  Important files detected:${NC}"
                found_important=true
            fi
            echo -e "  - $item"
        fi
    done
done

# Perform deletion if not dry run
if [ "$DRY_RUN" = false ]; then
    echo ""
    echo -e "${RED}Deleting files...${NC}"
    
    deleted_count=0
    failed_count=0
    
    for item in "${files_to_delete[@]}"; do
        if [ -e "$item" ]; then
            if rm -rf "$item" 2>/dev/null; then
                deleted_count=$((deleted_count + 1))
                [ "$VERBOSE" = true ] && echo -e "${GREEN}✓${NC} Deleted: $item"
            else
                failed_count=$((failed_count + 1))
                echo -e "${RED}✗ Failed to delete:${NC} $item"
            fi
        fi
    done
    
    echo ""
    echo -e "${GREEN}Cleanup complete!${NC}"
    echo "- Deleted: $deleted_count items"
    if [ $failed_count -gt 0 ]; then
        echo -e "${RED}- Failed: $failed_count items${NC}"
    fi
    echo "- Freed: $(format_size $total_size)"
else
    echo ""
    echo -e "${YELLOW}Dry run complete. No files were deleted.${NC}"
    echo -e "Run without --dry-run to actually delete these files."
fi

# Additional cleanup suggestions
echo ""
echo -e "${BLUE}Additional cleanup suggestions:${NC}"
echo "1. Run 'git gc' to optimize the Git repository"
echo "2. Clear Xcode derived data: rm -rf ~/Library/Developer/Xcode/DerivedData"
echo "3. Clear Xcode device support: rm -rf ~/Library/Developer/Xcode/iOS\\ DeviceSupport"
echo "4. Clear simulator caches: xcrun simctl delete unavailable"

exit 0