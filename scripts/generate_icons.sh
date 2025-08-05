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
echo "📱 Copying icons to iOS project..."

# Define the Assets directory paths
ASSETS_DIR="LeavesOfBlocks/Assets.xcassets/AppIcon.appiconset"
LAUNCH_ICON_DIR="LeavesOfBlocks/Assets.xcassets/LaunchIcon.imageset"

# Create directories if they don't exist
mkdir -p "$ASSETS_DIR"
mkdir -p "$LAUNCH_ICON_DIR"
mkdir -p docs

# Copy main app icons
echo "📱 Copying main app icons..."
cp tmp/AppIcon-60@3x.png "$ASSETS_DIR/AppIcon-60@3x.png"      # iPhone App 180x180
cp tmp/AppIcon-60@2x.png "$ASSETS_DIR/AppIcon-60@2x.png"      # iPhone App 120x120
cp tmp/AppIcon-40@3x.png "$ASSETS_DIR/AppIcon-40@3x.png"      # iPhone Spotlight 120x120
cp tmp/AppIcon-40@2x.png "$ASSETS_DIR/AppIcon-40@2x.png"      # iPhone/iPad Spotlight 80x80
cp tmp/AppIcon-40.png "$ASSETS_DIR/AppIcon-40.png"            # iPad Spotlight 40x40
cp tmp/AppIcon-29@3x.png "$ASSETS_DIR/AppIcon-29@3x.png"      # iPhone Settings 87x87
cp tmp/AppIcon-29@2x.png "$ASSETS_DIR/AppIcon-29@2x.png"      # iPhone/iPad Settings 58x58
cp tmp/AppIcon-29.png "$ASSETS_DIR/AppIcon-29.png"            # iPad Settings 29x29
cp tmp/AppIcon-20@3x.png "$ASSETS_DIR/AppIcon-20@3x.png"      # iPhone Notifications 60x60
cp tmp/AppIcon-20@2x.png "$ASSETS_DIR/AppIcon-20@2x.png"      # iPhone Notifications 40x40

# iPad specific icons
cp tmp/AppIcon-83.5@2x.png "$ASSETS_DIR/AppIcon-83.5@2x.png"  # iPad Pro 167x167
cp tmp/AppIcon-76@2x.png "$ASSETS_DIR/AppIcon-76@2x.png"      # iPad 152x152
cp tmp/AppIcon-76.png "$ASSETS_DIR/AppIcon-76.png"            # iPad 76x76

# App Store icon
cp tmp/AppIcon-1024.png "$ASSETS_DIR/AppIcon-1024.png"        # App Store 1024x1024

# Copy Launch Screen icons
echo "📱 Copying Launch Screen icons..."
cp tmp/LaunchIcon@1x.png "$LAUNCH_ICON_DIR/LaunchIcon@1x.png"
cp tmp/LaunchIcon@2x.png "$LAUNCH_ICON_DIR/LaunchIcon@2x.png"
cp tmp/LaunchIcon@3x.png "$LAUNCH_ICON_DIR/LaunchIcon@3x.png"
cp tmp/LaunchIcon-Dark@1x.png "$LAUNCH_ICON_DIR/LaunchIcon-Dark@1x.png"
cp tmp/LaunchIcon-Dark@2x.png "$LAUNCH_ICON_DIR/LaunchIcon-Dark@2x.png"
cp tmp/LaunchIcon-Dark@3x.png "$LAUNCH_ICON_DIR/LaunchIcon-Dark@3x.png"


# Copy GitHub Pages app icon
echo "📄 Copying GitHub Pages app icon..."
cp tmp/app-icon.png docs/app-icon.png

# Create Contents.json for the launch icon set
cat > "$LAUNCH_ICON_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "LaunchIcon@1x.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "filename" : "LaunchIcon-Dark@1x.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "LaunchIcon@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "filename" : "LaunchIcon-Dark@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "LaunchIcon@3x.png",
      "idiom" : "universal",
      "scale" : "3x"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "filename" : "LaunchIcon-Dark@3x.png",
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

# Create Contents.json for the icon set
cat > "$ASSETS_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "AppIcon-20@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "AppIcon-20@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "filename" : "AppIcon-40.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "filename" : "AppIcon-40@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "AppIcon-60@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "AppIcon-60@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "AppIcon-76.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "76x76"
    },
    {
      "filename" : "AppIcon-76@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "filename" : "AppIcon-83.5@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "filename" : "AppIcon-40@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "AppIcon-40@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "AppIcon-29.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "filename" : "AppIcon-29@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "AppIcon-29@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "AppIcon-29@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "filename" : "AppIcon-1024.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo ""
echo "✅ Icons generated and copied to iOS project successfully!"
echo "📁 App Icons location: $ASSETS_DIR"
echo "📁 Launch Icons location: $LAUNCH_ICON_DIR"
echo "📁 GitHub Pages Icon location: docs/app-icon.png"
echo ""
echo "🚀 Next steps:"
echo "1. Open your Xcode project"
echo "2. Navigate to Assets.xcassets"
echo "3. The AppIcon should now show all your new green-themed icons"
echo "4. The LaunchIcon should show your new launch screen icon"
echo "5. Build and test your app to see the new icons!"
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