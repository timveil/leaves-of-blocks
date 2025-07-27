# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a SwiftUI iOS game called "Leaves of Blocks" - a Block Blast-style puzzle game created with Xcode 16.4. Players drag and drop randomly generated block shapes onto an 8x8 grid to clear horizontal and vertical lines. The game features autumn-themed visuals, progressive difficulty through weighted block generation, scoring system with combo bonuses, and high score persistence.

## Build Commands

This project uses Xcode's build system. Common commands:

- **Build**: `xcodebuild -project "Leaves of Blocks.xcodeproj" -scheme "Leaves of Blocks" build`
- **Test**: `xcodebuild -project "Leaves of Blocks.xcodeproj" -scheme "Leaves of Blocks" test -destination 'platform=iOS Simulator,name=iPhone 15'`
- **UI Tests**: `xcodebuild -project "Leaves of Blocks.xcodeproj" -scheme "Leaves of Blocks" test -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:"Leaves of BlocksUITests"`
- **Clean Build**: `xcodebuild -project "Leaves of Blocks.xcodeproj" -scheme "Leaves of Blocks" clean build`
- **Run on Simulator**: `xcodebuild -project "Leaves of Blocks.xcodeproj" -scheme "Leaves of Blocks" -destination 'platform=iOS Simulator,name=iPhone 15' build && xcrun simctl boot "iPhone 15" && xcrun simctl install booted .build/Debug-iphonesimulator/Leaves\ of\ Blocks.app && xcrun simctl launch booted timothy.veil.Leaves-of-Blocks`

### CI/CD
- GitHub Actions workflows configured for automated builds and tests
- Uses Xcode 16.2 on macOS latest runner
- Automatically creates iPhone 15 simulator for testing

## Architecture

### Navigation Flow
- **App Entry**: `Leaves_of_BlocksApp.swift` - Main app with custom launch screen (2.5s)
- **Navigation Hub**: `ContentView.swift` - Enum-based screen management (Home, Game, Summary, About, History)
- **Testing**: Uses both Swift Testing framework (unit tests) and XCTest (UI tests)
- **Target Deployment**: iOS 18.5+, supports iPhone and iPad
- **Bundle ID**: `timothy.veil.Leaves-of-Blocks` (main app), `nineforty.one.Leaves-of-BlocksTests` (tests)

### Key Components

#### Core Game Files
- `GameModels.swift` - Data models: DifficultyMode, GridPosition, GridCell, BlockShape, GameState
- `GameLogic.swift` - Game mechanics: block placement, line clearing, game over detection
- `GameViews.swift` - Game UI components: grid display, block rendering, drag/drop
- `GameEnhancements.swift` - Visual effects, animations, weighted block generation

#### Supporting Systems
- `Theme.swift` - Comprehensive theming: autumn colors, typography, layout constants, animations
- `Configuration.swift` - App configuration: environment detection, feature flags, preferences
- `HighScoreManager.swift` - High score persistence using UserDefaults
- `UIComponents.swift` - Reusable UI components across the app
- `Extensions.swift` - Swift extensions for common functionality
- `TestHelpers.swift` - Testing utilities and mock implementations

## Game Architecture Details

### GameState (ObservableObject)
- Manages 8x8 grid with GridCell objects
- Tracks current blocks (up to 3), score, high score, difficulty
- Handles block placement validation and line clearing logic
- Publishes updates for reactive UI

### Block System
- 21 predefined BlockShape configurations (1-9 cells each)
- Weighted random generation based on difficulty
- Drag/drop implementation with visual preview
- Color-coded blocks with autumn theme

### Scoring System
- Block placement: 10 points per cell
- Line clearing: 100 points per line
- Combo bonuses: 50 extra points per additional line cleared simultaneously
- High score persistence across sessions

### Game Logic Flow
1. **Block Generation**: BlockGenerator creates weighted random blocks based on difficulty
2. **Placement Validation**: GameRules validates block placement against grid bounds and existing blocks
3. **Line Detection**: Checks for complete horizontal/vertical lines after placement
4. **Score Calculation**: Updates score based on placement and cleared lines
5. **Game Over Check**: Validates if any remaining blocks can be placed

### Difficulty Modes
- **Easy**: Favors smaller blocks, more forgiving generation
- **Moderate**: Balanced block distribution
- **Hard**: Increases chance of larger, complex blocks

## Development Notes

- Pure SwiftUI implementation with no external dependencies
- Uses NavigationView with StackNavigationViewStyle for consistent iPad behavior
- ObservableObject/Published pattern for state management
- Custom drag gesture implementation with visual feedback
- Comprehensive configuration system for feature flags and testing
- Swift version 5.0, modern iOS 18.5+ deployment target
- Project structure uses synchronized file groups (Xcode 16+ feature)
- Supports only iPhone (TARGETED_DEVICE_FAMILY = 1) in current configuration

## Testing Strategy

- **Unit Tests**: Uses Swift Testing framework (`@Test` attribute) in LeavesOfBlocksTests
- **UI Tests**: Uses XCTest framework for UI automation
- **Test Helpers**: MockGameState and TestDataGenerator available for testing
- **Performance Testing**: PerformanceTestHelper utility for measuring game performance