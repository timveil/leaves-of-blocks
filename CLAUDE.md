# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a SwiftUI iOS game called "Leaves of Blocks" - a Block Blast-style puzzle game created with Xcode 16.4. Players drag and drop randomly generated block shapes onto an 8x8 grid to clear horizontal and vertical lines. The game features autumn-themed visuals, progressive difficulty through weighted block generation, scoring system with combo bonuses, and high score persistence.

## Build Commands

### Main App Commands
- **Build**: `xcodebuild -project "LeavesOfBlocks.xcodeproj" -scheme "LeavesOfBlocks" build`
- **Build for Simulator**: `xcodebuild -project "LeavesOfBlocks.xcodeproj" -scheme "LeavesOfBlocks" build -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Test All**: `xcodebuild -project "LeavesOfBlocks.xcodeproj" -scheme "LeavesOfBlocks" test -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Unit Tests Only**: `xcodebuild -project "LeavesOfBlocks.xcodeproj" -scheme "LeavesOfBlocks" test -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:"LeavesOfBlocksTests"`
- **UI Tests Only**: `xcodebuild -project "LeavesOfBlocks.xcodeproj" -scheme "LeavesOfBlocks" test -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:"LeavesOfBlocksUITests"`
- **Clean Build**: `xcodebuild -project "LeavesOfBlocks.xcodeproj" -scheme "LeavesOfBlocks" clean build`
- **Archive for Release**: `xcodebuild -project "LeavesOfBlocks.xcodeproj" -scheme "LeavesOfBlocks" -destination "generic/platform=iOS" archive`
- **Run Single Test**: `xcodebuild test -project "LeavesOfBlocks.xcodeproj" -scheme "LeavesOfBlocks" -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:"LeavesOfBlocksTests/GameLogicTests/testBlockPlacement"`

### App Clip Commands
- **Build App Clip**: `xcodebuild -project "LeavesOfBlocks.xcodeproj" -scheme "LeavesOfBlocksAppClip" build`
- **Test App Clip**: `xcodebuild -project "LeavesOfBlocks.xcodeproj" -scheme "LeavesOfBlocksAppClip" test -destination 'platform=iOS Simulator,name=iPhone 16'`

### Build Troubleshooting
- **Available Simulators**: Current system has iPhone 16, iPhone 16 Plus, iPhone 16 Pro Max, iPhone 16e, and various iPad simulators
- **Simulator Issues**: If "iPhone 16 Pro" is not found, use "iPhone 16" instead
- **Build Errors**: Always check for missing Typography properties (e.g., `buttonFont` doesn't exist, use `bodyFont` instead)
- **Quick Error Check**: Use `xcodebuild ... 2>&1 | grep -A 5 -B 5 "error:"` to isolate compilation errors
- **Success Verification**: Build output should end with "** BUILD SUCCEEDED **"

### CI/CD
- GitHub Actions workflows in `.github/workflows/`
- Uses Xcode 16.2 on macOS latest runner
- Automatically creates iPhone 16 Pro simulator for testing
- Runs on push to main and pull requests

## Architecture

### Navigation Flow
- **App Entry**: `LeavesOfBlocksApp.swift` - Main app with custom launch screen (2.5s)
- **Navigation Hub**: `ContentView.swift` - Enum-based screen management (Home, Game, Summary, About, History)
- **Testing**: Uses both Swift Testing framework (unit tests) and XCTest (UI tests)
- **Target Deployment**: iOS 18.5+, supports iPhone only (TARGETED_DEVICE_FAMILY = 1)
- **Bundle ID**: `timothy.veil.LeavesOfBlocks`
- **App Clip Bundle ID**: `timothy.veil.LeavesOfBlocks.Clip`

### Key Components

#### Core Game Files
- `Models/Game/GameState.swift` - Main game state management (ObservableObject)
- `Models/Game/BlockModels.swift` - Block shapes, positions, and color definitions
- `Models/Game/GridModels.swift` - Grid cell and position data structures  
- `Models/Game/DifficultyMode.swift` - Difficulty settings and configurations
- `Logic/Game/GameRules.swift` - Game mechanics: block placement, line clearing, validation
- `Logic/Game/BlockGenerator.swift` - Weighted random block generation system
- `Logic/Enhancements/GameEnhancements.swift` - Visual effects, animations, performance optimizations

#### UI Architecture (Modular Component System)
- `Views/BaseScreenView.swift` - Foundation layout container for all screens
- `Views/ViewModifiers/ScreenModifiers.swift` - Unified styling system with 10+ reusable modifiers
- `Views/Components/` - Reusable UI components organized by function:
  - `Buttons/GameButtons.swift` - Unified button components (GameDifficultyButton, StartGameButton)
  - `Displays/StatisticalDisplays.swift` - Score and statistics display components (GameStatChip) 
  - `Tables/GameTables.swift` - Table formatting and display components
- `Views/Game/Components/` - Game-specific UI components:
  - `GameBlockViews.swift` - Block rendering and drag/drop implementation
  - `GameGridViews.swift` - 8x8 game grid display and interaction
  - `GameHeaderViews.swift` - Score display and game status UI
  - `GameBackgroundViews.swift` - Themed background and visual effects

#### Supporting Systems  
- `Resources/Theming/` - Comprehensive theming system:
  - `Theme.swift` - Main theme orchestration
  - `Colors.swift` - Autumn color palette and semantic color definitions
  - `Typography.swift` - Font scales and text styling
  - `Layout.swift` - Layout constants, spacing, and sizing
  - `Animations.swift` - Animation timing and easing definitions
- `Services/Configuration/AppConfiguration.swift` - Environment detection, feature flags, preferences
- `Services/Data/HighScoreManager.swift` - High score persistence using UserDefaults
- `Services/Data/CoreDataManager.swift` - Core Data stack management for game history
- `Models/Data/GameRecord+CoreDataClass.swift` - Core Data entity class for game records
- `Models/Data/GameRecord+CoreDataProperties.swift` - Core Data entity properties
- `Extensions/` - Swift extensions organized by framework (Foundation, SwiftUI, UIKit)
- `Testing/Helpers/` - Testing utilities, mocks, and test data generators

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

## UI Architecture & Styling System

### Unified Component System
The app follows a modular component architecture with extensive code deduplication:

#### View Modifiers (`Views/ViewModifiers/ScreenModifiers.swift`)
- **gameContainerStyle()** - Consistent background, border, and shadow styling for containers
- **game3DCardStyle()** - Elevated card styling with multiple shadow layers for depth
- **gameGradientCardStyle()** - Gradient background cards with customizable styling
- **gameBadgeStyle()** - Unified badge/pill styling for difficulty modes and status indicators
- **gameTableHeaderStyle()** - Consistent table header formatting across components
- **Typography Modifiers** - gameTitleStyle(), gameHeadlineStyle(), gameBodyStyle(), gameCaptionStyle()
- **Navigation Modifiers** - Standard navigation bar and screen transition styling

#### Reusable Components
- **GameDifficultyButton** - Unified difficulty selection with compact/expanded modes
- **StartGameButton** - Consistent game start button with accessibility features
- **GameStatChip** - Statistical display component for scores, blocks placed, lines cleared
- **BaseScreenView** - Foundation layout providing background, grass decoration, and content structure

#### Component Organization
- **Feature-based directories** - Components grouped by app section (Home/, Game/, History/, etc.)
- **Shared components** - Common UI elements in Views/Components/ for cross-screen usage
- **Atomic design principles** - Small, composable components that build into larger interfaces

### Code Deduplication Results
Recent refactoring eliminated ~300+ lines of duplicated styling code by:
- Consolidating button variations into unified components
- Replacing complex ZStack shadow patterns with reusable modifiers
- Standardizing card, container, and badge styling across all screens
- Unifying typography and spacing through centralized theme system

## Development Notes

- Pure SwiftUI implementation with Core Data for persistence (no external dependencies)
- Uses NavigationView with StackNavigationViewStyle for consistent iPad behavior
- ObservableObject/Published pattern for state management
- Custom drag gesture implementation with visual feedback
- Modular component architecture with extensive view modifier system
- Comprehensive configuration system for feature flags and testing
- Swift version 5.0, modern iOS 18.5+ deployment target
- Project structure uses synchronized file groups (Xcode 16+ feature)
- Supports only iPhone (TARGETED_DEVICE_FAMILY = 1) in current configuration

## Testing Strategy

- **Unit Tests**: Uses Swift Testing framework (`@Test` attribute) in LeavesOfBlocksTests
- **UI Tests**: Uses XCTest framework for UI automation in LeavesOfBlocksUITests  
- **Test Helpers**: MockGameState and TestDataGenerator available for testing
- **Performance Testing**: PerformanceTestHelper utility for measuring game performance
- **Test Structure**: Basic test templates exist; tests need implementation for game logic

## App Clip Support

The project includes a fully integrated App Clip target:

### App Clip Details
- **Bundle ID**: `timothy.veil.LeavesOfBlocks.Clip`
- **Entry Point**: `LeavesOfBlocksAppClip/LeavesOfBlocksAppClipApp.swift`
- **UI**: Currently uses main app's `ContentView.swift` (can be customized)
- **Info.plist**: Configured with NSAppClip keys for notifications and location
- **Entitlements**: Parent app association configured
- **Size Limit**: Must stay under 10MB
- **Minimum iOS**: 14.0+ (App Clips requirement)

### App Clip Testing
- Test targets created: `LeavesOfBlocksAppClipTests` and `LeavesOfBlocksAppClipUITests`
- Share code files between main app and App Clip targets as needed
- Configure associated domains for App Clip invocation

## GitHub Pages Site

The project hosts documentation at the repository's GitHub Pages URL:

### Site Content
- **Privacy Policy**: `docs/index.html` - Styled HTML privacy policy with autumn theme matching the app
- **CNAME Files**: Domain configuration in both `docs/CNAME` and root `CNAME`

### Privacy Policy Highlights
- No data collection or transmission
- Local-only storage (UserDefaults and Core Data)
- COPPA compliant
- Ready for App Store privacy labels

### Site Styling Guidelines
- Uses autumn-themed colors from `Theme.swift` (deep browns, golden ambers, burnt oranges)
- Professional, clean design without decorative emojis
- Responsive layout optimized for all devices
- Card-based design with rounded corners and gradients

## Project File Structure

### Directory Layout
- **Main App**: `LeavesOfBlocks/`
- **App Clip**: `LeavesOfBlocksAppClip/`
- **Unit Tests**: `LeavesOfBlocksTests/`
- **UI Tests**: `LeavesOfBlocksUITests/`
- **App Clip Tests**: `LeavesOfBlocksAppClipTests/`, `LeavesOfBlocksAppClipUITests/`
- **GitHub Pages**: `docs/`
- **CI/CD**: `.github/workflows/`

### Key Project Settings
- Xcode Project: `LeavesOfBlocks.xcodeproj`
- Main Scheme: "LeavesOfBlocks"
- App Clip Scheme: "LeavesOfBlocksAppClip"
- Development Team: 85U9MWUBJL
- Code Signing: Automatic

## Configuration Details
- Pure SwiftUI implementation with Core Data for persistence (no external dependencies)
- Uses NavigationView with StackNavigationViewStyle for consistent behavior
- Custom drag gesture implementation with visual feedback  
- Configuration system via `Configuration.swift` for feature flags and environment detection
- High score persistence through `HighScoreManager.swift` using UserDefaults
- Game history persistence through Core Data (`CoreDataManager.swift`)
- App Clip ready with simplified experience option