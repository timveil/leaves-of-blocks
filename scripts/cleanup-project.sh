#!/bin/bash
#
# cleanup-project.sh
# Comprehensive cleanup script for iOS/Xcode projects
# Cleans build artifacts, caches, and ignored files
# Usage: ./cleanup-project.sh [--dry-run]
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
            echo "This script performs comprehensive cleanup of your iOS project including:"
            echo "  - Xcode build artifacts and derived data"
            echo "  - Fastlane artifacts"
            echo "  - Swift Package Manager cache"
            echo "  - Simulator data and caches"
            echo "  - Git maintenance and optimization"
            echo "  - Ignored files in project root"
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

echo -e "${BLUE}=== Project Cleanup Utility ===${NC}"
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
    echo -e "${BLUE}Running comprehensive cleanup commands...${NC}"

    # 1. Clean Xcode build artifacts
    if ls *.xcodeproj 1> /dev/null 2>&1 || ls *.xcworkspace 1> /dev/null 2>&1; then
        echo "- Cleaning Xcode build artifacts..."
        xcodebuild clean -quiet 2>/dev/null || true
    fi

    # 2. Clean Fastlane artifacts
    if [ -f "fastlane/Fastfile" ]; then
        echo "- Cleaning Fastlane artifacts..."
        # Remove common Fastlane generated files manually since the action has parameter issues
        rm -rf fastlane/report.xml 2>/dev/null || true
        rm -rf fastlane/Preview.html 2>/dev/null || true
        rm -rf fastlane/test_output 2>/dev/null || true
        rm -rf fastlane/screenshots/*.png 2>/dev/null || true
        rm -rf *.ipa 2>/dev/null || true
        rm -rf *.dSYM.zip 2>/dev/null || true
    fi

    # 3. Remove local build directories
    if [ -d "build/" ]; then
        echo "- Removing build directory..."
        rm -rf build/ 2>/dev/null || true
    fi

    if [ -d "DerivedData/" ]; then
        echo "- Removing local DerivedData directory..."
        rm -rf DerivedData/ 2>/dev/null || true
    fi

    # 4. Clean system-wide Xcode data
    echo "- Cleaning system Xcode derived data..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true
    
    echo "- Cleaning Xcode module cache..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/* 2>/dev/null || true
    
    echo "- Cleaning old iOS device support files..."
    find ~/Library/Developer/Xcode/iOS\ DeviceSupport -name "*.Symbols" -mtime +30 -exec rm -rf {} + 2>/dev/null || true

    # 5. Clean Swift Package Manager cache
    if [ -d ".build" ]; then
        echo "- Removing Swift Package Manager build directory..."
        rm -rf .build 2>/dev/null || true
    fi
    
    echo "- Cleaning Swift Package Manager cache..."
    rm -rf ~/Library/Caches/org.swift.swiftpm/* 2>/dev/null || true
    rm -rf ~/Library/Developer/Xcode/DerivedData/*-*/SourcePackages/* 2>/dev/null || true

    # 6. Clean simulator data (old simulators)
    echo "- Cleaning unavailable simulators..."
    xcrun simctl delete unavailable 2>/dev/null || true
    
    echo "- Cleaning simulator logs..."
    rm -rf ~/Library/Logs/CoreSimulator/* 2>/dev/null || true

    # 7. Clean Ruby/Bundler cache
    if [ -f "Gemfile" ] && command -v bundle > /dev/null 2>&1; then
        echo "- Cleaning bundler cache..."
        bundle clean --force 2>/dev/null || true
    fi

    # 8. Clean Python cache
    echo "- Removing Python cache files..."
    find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.pyc" -delete 2>/dev/null || true

    # 9. Git maintenance
    echo "- Running Git garbage collection..."
    git gc --quiet 2>/dev/null || true
    
    echo "- Pruning Git objects..."
    git prune --quiet 2>/dev/null || true

    # 10. Clean macOS system files
    echo "- Removing .DS_Store files..."
    find . -name ".DS_Store" -delete 2>/dev/null || true
    
    echo "- Cleaning thumbnail cache..."
    rm -rf ~/.Trash/.DS_Store 2>/dev/null || true
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

# Additional manual cleanup suggestions
echo ""
echo -e "${BLUE}Additional manual cleanup options:${NC}"
echo "1. Clean Xcode archives: rm -rf ~/Library/Developer/Xcode/Archives"
echo "2. Reset all simulators: xcrun simctl erase all"
echo "3. Clear Xcode documentation: rm -rf ~/Library/Developer/Shared/Documentation"
echo "4. Clear system logs: sudo rm -rf /var/log/system.log*"
echo "5. Empty Trash completely"

exit 0