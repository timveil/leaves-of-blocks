# Screenshot Setup Guide for Leaves of Blocks

This guide explains how to set up automated screenshot capture using Fastlane for your iOS app.

## Current Status

❌ **Screenshot capture is not currently working** because the project lacks UI test targets.

## Quick Solution: Manual Screenshots

For immediate screenshot needs, use the manual approach:

```bash
# Build the app and get instructions for manual screenshots
fastlane ios manual_screenshots
```

This will:
1. Build your app for simulator
2. Provide step-by-step instructions for manual screenshot capture
3. Guide you through the process of taking screenshots in iOS Simulator

## Complete Solution: Automated Screenshots

To enable fully automated screenshot capture, you need to add UI tests to your project.

### Step 1: Add UI Test Target

1. **Open Xcode** and select your `LeavesOfBlocks.xcodeproj`
2. **Add UI Test Target**:
   - File → New → Target
   - Choose "UI Testing Bundle"
   - Product Name: `LeavesOfBlocksUITests`
   - Target to be Tested: `LeavesOfBlocks`
   - Click Finish

### Step 2: Configure UI Test Target

1. **Select the new UI test target** in project settings
2. **Set the same deployment target** as your main app (iOS 18.5)
3. **Ensure proper signing** (same team as main app)

### Step 3: Create Screenshot UI Tests

Replace the contents of `LeavesOfBlocksUITests/LeavesOfBlocksUITests.swift` with:

```swift
import XCTest
import SnapshotHelper  // This will be added by Fastlane

final class LeavesOfBlocksUITests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }
    
    func testTakeScreenshots() throws {
        let app = XCUIApplication()
        
        // Home Screen
        snapshot("01-HomeScreen")
        
        // Navigate to How to Play
        app.buttons["How to Play"].tap()
        snapshot("02-HowToPlay")
        
        // Go back to home
        app.navigationBars.buttons.element(boundBy: 0).tap()
        
        // Start a game (Easy difficulty)
        app.buttons["Easy"].tap()
        app.buttons["Start Game"].tap()
        
        // Game Screen
        snapshot("03-GameScreen-Easy")
        
        // Game over scenario (you may need to adjust this based on your UI)
        // This is a placeholder - adjust based on your actual game flow
        
        // Navigate to Game History
        app.buttons["History"].tap()
        snapshot("04-GameHistory")
        
        // Navigate to About
        app.buttons["About"].tap()
        snapshot("05-AboutScreen")
    }
}
```

### Step 4: Add Snapshot Helper

1. **Run Fastlane setup** to add the snapshot helper:
   ```bash
   cd fastlane
   fastlane snapshot init
   ```

2. **Add SnapshotHelper to UI test target**:
   - In Xcode, right-click your UI test target
   - Add Files → Select `fastlane/SnapshotHelper.swift`
   - Ensure it's added to the UI test target only

### Step 5: Update Fastfile

Once UI tests are set up, update the screenshots lane in `Fastfile`:

```ruby
desc "Generate new localized screenshots"
lane :screenshots do
  # Build for testing first
  build_for_testing
  
  # Capture screenshots using snapshot
  snapshot
end
```

### Step 6: Test the Setup

```bash
# Test that UI tests work
xcodebuild test -project "LeavesOfBlocks.xcodeproj" -scheme "LeavesOfBlocks" -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:"LeavesOfBlocksUITests"

# Run screenshot capture
fastlane ios screenshots
```

## Configuration Options

The `Snapfile` is already configured with:
- Multiple device sizes (iPhone 16 Pro Max, iPhone 16 Pro, iPhone 16, iPhone SE, iPad Pro)
- Clean status bar (9:41 AM, full battery)
- Launch arguments for testing mode
- Organized output directory

## Troubleshooting

### Common Issues

**"No such module 'SnapshotHelper'"**
- Ensure `SnapshotHelper.swift` is added to your UI test target
- Run `fastlane snapshot init` if the file is missing

**"Cannot find UI elements"**
- Add accessibility identifiers to your SwiftUI views
- Use the Accessibility Inspector to verify element names
- Test your UI tests manually first

**"Simulator not found"**
- Ensure the device names in `Snapfile` match your available simulators
- Run `xcrun simctl list devices` to see available devices

**"Build failed"**
- Ensure UI test target has the same deployment target as main app
- Check that all required frameworks are linked

### Adding Accessibility Identifiers

To make UI tests more reliable, add accessibility identifiers to your SwiftUI views:

```swift
Button("Start Game") {
    // action
}
.accessibilityIdentifier("startGameButton")

Text("High Score: \\(score)")
    .accessibilityIdentifier("highScoreLabel")
```

Then reference them in tests:
```swift
app.buttons["startGameButton"].tap()
app.staticTexts["highScoreLabel"].waitForExistence(timeout: 5)
```

## Benefits of Automated Screenshots

Once set up, automated screenshots provide:
- ✅ Consistent screenshots across all device sizes
- ✅ Automatic App Store Connect upload preparation
- ✅ Localized screenshots for multiple languages
- ✅ Integration with CI/CD for automated releases
- ✅ Time savings for App Store submissions

## Next Steps

1. Follow Step 1-3 above to add UI test target
2. Create basic UI tests for your app's main screens
3. Test manually with Xcode
4. Run `fastlane ios screenshots` to generate automated screenshots
5. Find your screenshots in `fastlane/screenshots/`

For more advanced configuration, see the [Fastlane Snapshot documentation](https://docs.fastlane.tools/actions/snapshot/).