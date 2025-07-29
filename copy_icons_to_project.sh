#!/bin/bash

# Script to copy generated icons to iOS project structure

# Define the Assets directory path
ASSETS_DIR="LeavesOfBlocks/Assets.xcassets/AppIcon.appiconset"

echo "📱 Copying icons to iOS project..."

# Create the AppIcon.appiconset directory if it doesn't exist
mkdir -p "$ASSETS_DIR"

# Copy main app icons
cp icons/AppIcon-60@3x.png "$ASSETS_DIR/AppIcon-60@3x.png"      # iPhone App 180x180
cp icons/AppIcon-60@2x.png "$ASSETS_DIR/AppIcon-60@2x.png"      # iPhone App 120x120
cp icons/AppIcon-40@3x.png "$ASSETS_DIR/AppIcon-40@3x.png"      # iPhone Spotlight 120x120
cp icons/AppIcon-40@2x.png "$ASSETS_DIR/AppIcon-40@2x.png"      # iPhone/iPad Spotlight 80x80
cp icons/AppIcon-40.png "$ASSETS_DIR/AppIcon-40.png"            # iPad Spotlight 40x40
cp icons/AppIcon-29@3x.png "$ASSETS_DIR/AppIcon-29@3x.png"      # iPhone Settings 87x87
cp icons/AppIcon-29@2x.png "$ASSETS_DIR/AppIcon-29@2x.png"      # iPhone/iPad Settings 58x58
cp icons/AppIcon-29.png "$ASSETS_DIR/AppIcon-29.png"            # iPad Settings 29x29
cp icons/AppIcon-20@3x.png "$ASSETS_DIR/AppIcon-20@3x.png"      # iPhone Notifications 60x60
cp icons/AppIcon-20@2x.png "$ASSETS_DIR/AppIcon-20@2x.png"      # iPhone Notifications 40x40

# iPad specific icons
cp icons/AppIcon-83.5@2x.png "$ASSETS_DIR/AppIcon-83.5@2x.png"  # iPad Pro 167x167
cp icons/AppIcon-76@2x.png "$ASSETS_DIR/AppIcon-76@2x.png"      # iPad 152x152
cp icons/AppIcon-76.png "$ASSETS_DIR/AppIcon-76.png"            # iPad 76x76

# App Store icon
cp icons/AppIcon-1024.png "$ASSETS_DIR/AppIcon-1024.png"        # App Store 1024x1024

# Copy Launch Screen icons
LAUNCH_ICON_DIR="LeavesOfBlocks/Assets.xcassets/LaunchIcon.imageset"
echo "📱 Copying Launch Screen icons..."
mkdir -p "$LAUNCH_ICON_DIR"

cp icons/LaunchIcon@2x.png "$LAUNCH_ICON_DIR/LaunchIcon@2x.png"
cp icons/LaunchIcon@3x.png "$LAUNCH_ICON_DIR/LaunchIcon@3x.png"
cp icons/LaunchIcon-Dark@2x.png "$LAUNCH_ICON_DIR/LaunchIcon-Dark@2x.png"
cp icons/LaunchIcon-Dark@3x.png "$LAUNCH_ICON_DIR/LaunchIcon-Dark@3x.png"

# Create Contents.json for the launch icon set
cat > "$LAUNCH_ICON_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "LaunchIcon@2x.png",
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
      "filename" : "LaunchIcon-Dark@2x.png",
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

echo "✅ Icons copied to iOS project successfully!"
echo "📁 App Icons location: $ASSETS_DIR"
echo "📁 Launch Icons location: $LAUNCH_ICON_DIR"
echo ""
echo "🚀 Next steps:"
echo "1. Open your Xcode project"
echo "2. Navigate to Assets.xcassets"
echo "3. The AppIcon should now show all your new green-themed icons"
echo "4. The LaunchIcon should show your new launch screen icon"
echo "5. Build and test your app to see the new icons!"

# List the copied files
echo ""
echo "📋 Copied App Icon files:"
ls -la "$ASSETS_DIR"
echo ""
echo "📋 Copied Launch Icon files:"
ls -la "$LAUNCH_ICON_DIR"