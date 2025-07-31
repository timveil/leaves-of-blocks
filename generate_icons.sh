#!/bin/bash

# Icon Generation Script for Leaves of Blocks
# This script generates all required iOS app icons from the SVG logo

# Check if rsvg-convert is installed
if ! command -v rsvg-convert &> /dev/null; then
    echo "rsvg-convert is required but not installed."
    echo "Install it with: brew install librsvg"
    exit 1
fi

# Create tmp directory if it doesn't exist
mkdir -p tmp

# Source SVG files
SVG_FILE="logo.svg"
TRANSPARENT_SVG_FILE="logo-transparent.svg"

if [ ! -f "$SVG_FILE" ]; then
    echo "Error: $SVG_FILE not found!"
    exit 1
fi

if [ ! -f "$TRANSPARENT_SVG_FILE" ]; then
    echo "Error: $TRANSPARENT_SVG_FILE not found!"
    exit 1
fi

echo "Generating iOS app icons from $SVG_FILE and transparent launch icons from $TRANSPARENT_SVG_FILE..."

# iOS App Icon sizes (all square with white background)
# iPhone App Icons
rsvg-convert -w 180 -h 180 "$SVG_FILE" > tmp/AppIcon-60@3x.png  # iPhone 180x180
rsvg-convert -w 120 -h 120 "$SVG_FILE" > tmp/AppIcon-60@2x.png  # iPhone 120x120
rsvg-convert -w 87 -h 87 "$SVG_FILE" > tmp/AppIcon-29@3x.png    # iPhone Settings 87x87
rsvg-convert -w 58 -h 58 "$SVG_FILE" > tmp/AppIcon-29@2x.png    # iPhone Settings 58x58
rsvg-convert -w 80 -h 80 "$SVG_FILE" > tmp/AppIcon-40@2x.png    # iPhone Spotlight 80x80
rsvg-convert -w 120 -h 120 "$SVG_FILE" > tmp/AppIcon-40@3x.png  # iPhone Spotlight 120x120
rsvg-convert -w 40 -h 40 "$SVG_FILE" > tmp/AppIcon-20@2x.png    # iPhone Notifications 40x40
rsvg-convert -w 60 -h 60 "$SVG_FILE" > tmp/AppIcon-20@3x.png    # iPhone Notifications 60x60

# iPad App Icons
rsvg-convert -w 152 -h 152 "$SVG_FILE" > tmp/AppIcon-76@2x.png  # iPad 152x152
rsvg-convert -w 76 -h 76 "$SVG_FILE" > tmp/AppIcon-76.png       # iPad 76x76
rsvg-convert -w 167 -h 167 "$SVG_FILE" > tmp/AppIcon-83.5@2x.png # iPad Pro 167x167

# Universal Settings and Spotlight
rsvg-convert -w 29 -h 29 "$SVG_FILE" > tmp/AppIcon-29.png       # Settings 29x29
rsvg-convert -w 40 -h 40 "$SVG_FILE" > tmp/AppIcon-40.png       # Spotlight 40x40

# App Store Icon (1024x1024)
rsvg-convert -w 1024 -h 1024 "$SVG_FILE" > tmp/AppIcon-1024.png

# Additional common sizes
rsvg-convert -w 512 -h 512 "$SVG_FILE" > tmp/AppIcon-512.png
rsvg-convert -w 256 -h 256 "$SVG_FILE" > tmp/AppIcon-256.png
rsvg-convert -w 128 -h 128 "$SVG_FILE" > tmp/AppIcon-128.png
rsvg-convert -w 64 -h 64 "$SVG_FILE" > tmp/AppIcon-64.png
rsvg-convert -w 32 -h 32 "$SVG_FILE" > tmp/AppIcon-32.png
rsvg-convert -w 16 -h 16 "$SVG_FILE" > tmp/AppIcon-16.png

# GitHub Pages app icon (for documentation site, transparent background)
rsvg-convert -w 256 -h 256 --background-color=transparent "$TRANSPARENT_SVG_FILE" > tmp/app-icon.png

# App Clip Icons (with white background, no transparency)
rsvg-convert -w 180 -h 180 "$SVG_FILE" > tmp/AppClipIcon-60@3x.png
rsvg-convert -w 120 -h 120 "$SVG_FILE" > tmp/AppClipIcon-60@2x.png
rsvg-convert -w 1024 -h 1024 "$SVG_FILE" > tmp/AppClipIcon-1024.png

# Launch Screen Icons (transparent background for overlay use)
rsvg-convert -w 120 -h 120 --background-color=transparent "$TRANSPARENT_SVG_FILE" > tmp/LaunchIcon@1x.png
rsvg-convert -w 240 -h 240 --background-color=transparent "$TRANSPARENT_SVG_FILE" > tmp/LaunchIcon@2x.png
rsvg-convert -w 360 -h 360 --background-color=transparent "$TRANSPARENT_SVG_FILE" > tmp/LaunchIcon@3x.png
# For dark mode, we'll use the same transparent icons
rsvg-convert -w 120 -h 120 --background-color=transparent "$TRANSPARENT_SVG_FILE" > tmp/LaunchIcon-Dark@1x.png
rsvg-convert -w 240 -h 240 --background-color=transparent "$TRANSPARENT_SVG_FILE" > tmp/LaunchIcon-Dark@2x.png
rsvg-convert -w 360 -h 360 --background-color=transparent "$TRANSPARENT_SVG_FILE" > tmp/LaunchIcon-Dark@3x.png

echo "✅ Generated all iOS app icons and launch icons successfully!"
echo "📁 Icons saved in ./tmp/ directory"
echo ""
echo "Generated icon sizes:"
ls -la tmp/ | awk '{print $9, $5}' | grep -v "^$" | sort

echo ""
echo "📱 iOS App Icon Requirements:"
echo "• iPhone App: 180x180, 120x120"
echo "• iPhone Notifications: 60x60, 40x40"
echo "• iPhone Settings: 87x87, 58x58, 29x29"
echo "• iPhone Spotlight: 120x120, 80x80, 40x40"
echo "• iPad App: 167x167, 152x152, 76x76"
echo "• App Store: 1024x1024"
echo "• Launch Screen: 120x120, 240x240, 360x360 (with dark mode variants)"
echo "• App icons have white background (Apple requirement)"
echo "• Launch screen icons are transparent for gradient overlay blending"