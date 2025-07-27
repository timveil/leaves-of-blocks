[![iOS Build and Test](https://github.com/timveil/leaves-of-blocks/actions/workflows/ios.yml/badge.svg)](https://github.com/timveil/leaves-of-blocks/actions/workflows/ios.yml)
[![Xcode - Build and Analyze](https://github.com/timveil/leaves-of-blocks/actions/workflows/objective-c-xcode.yml/badge.svg)](https://github.com/timveil/leaves-of-blocks/actions/workflows/objective-c-xcode.yml)

# Leaves of Blocks

A SwiftUI iOS puzzle game inspired by Block Blast, featuring autumn-themed visuals and addictive gameplay. Players drag and drop randomly generated block shapes onto an 8x8 grid to clear horizontal and vertical lines.

## Features

- 🍂 Beautiful autumn-themed design with custom animations
- 🎮 Drag-and-drop gameplay with visual feedback
- 📊 Progressive difficulty system (Easy, Moderate, Hard)
- 🏆 High score tracking with persistent storage
- 🎯 Combo scoring system for clearing multiple lines
- 📱 Optimized for iPhone and iPad (iOS 18.5+)

## Requirements

- Xcode 16.4 or later
- iOS 18.5+ deployment target
- macOS with Xcode command line tools

## Build Instructions

### Using Xcode GUI
1. Open `Leaves of Blocks.xcodeproj` in Xcode
2. Select your target device/simulator
3. Press ⌘+R to build and run

### Using Command Line

```bash
# Build the project
xcodebuild -project "Leaves of Blocks.xcodeproj" -scheme "Leaves of Blocks" build

# Clean build
xcodebuild -project "Leaves of Blocks.xcodeproj" -scheme "Leaves of Blocks" clean build

# Build and run on iPhone 15 simulator
xcodebuild -project "Leaves of Blocks.xcodeproj" -scheme "Leaves of Blocks" -destination 'platform=iOS Simulator,name=iPhone 15' build && \
xcrun simctl boot "iPhone 15" && \
xcrun simctl install booted .build/Debug-iphonesimulator/Leaves\ of\ Blocks.app && \
xcrun simctl launch booted timothy.veil.Leaves-of-Blocks
```

## Testing

The project includes both unit tests (Swift Testing framework) and UI tests (XCTest).

### Run All Tests
```bash
xcodebuild -project "Leaves of Blocks.xcodeproj" -scheme "Leaves of Blocks" test -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Run UI Tests Only
```bash
xcodebuild -project "Leaves of Blocks.xcodeproj" -scheme "Leaves of Blocks" test -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:"Leaves of BlocksUITests"
```

## Deployment

### CI/CD
The project includes GitHub Actions workflows for automated builds and tests:
- Uses Xcode 16.2 on macOS latest runner
- Automatically creates iPhone 15 simulator for testing
- Runs on push and pull requests

### Manual Deployment
1. Archive the app in Xcode: Product → Archive
2. Upload to App Store Connect through Xcode Organizer
3. Submit for review through App Store Connect

### TestFlight
1. Archive and upload to App Store Connect
2. Configure external testing groups
3. Distribute builds to testers

## Project Structure

```
Leaves of Blocks/
├── Core Game Logic/
│   ├── GameModels.swift      # Data models and game state
│   ├── GameLogic.swift       # Game mechanics and rules
│   ├── GameViews.swift       # Game UI components
│   └── GameEnhancements.swift # Visual effects and animations
├── Supporting Files/
│   ├── Theme.swift           # Autumn theme and styling
│   ├── Configuration.swift   # App configuration and feature flags
│   ├── HighScoreManager.swift # Score persistence
│   ├── UIComponents.swift    # Reusable UI components
│   └── Extensions.swift      # Swift extensions
├── Navigation/
│   ├── Leaves_of_BlocksApp.swift # App entry point
│   └── ContentView.swift     # Navigation hub
└── Tests/
    ├── LeavesOfBlocksTests/  # Unit tests
    └── LeavesOfBlocksUITests/ # UI automation tests
```

## Game Mechanics

### Gameplay
- Drag blocks from the bottom container to the 8x8 grid
- Complete horizontal or vertical lines to clear them
- Game ends when no blocks can be placed

### Scoring
- **Block Placement**: 10 points per cell
- **Line Clear**: 100 points per line
- **Combo Bonus**: +50 points for each additional line cleared simultaneously

### Difficulty Modes
- **Easy**: More small blocks (1-3 cells)
- **Moderate**: Balanced block distribution
- **Hard**: More large and complex blocks

## Technical Details

- **Framework**: Pure SwiftUI (no external dependencies)
- **Architecture**: ObservableObject/Published pattern for state management
- **Minimum iOS**: 18.5
- **Swift Version**: 5.0
- **Bundle ID**: `timothy.veil.Leaves-of-Blocks`

## License

[Add your license information here]

## Author

Timothy Veil
