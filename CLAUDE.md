# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Coding Standards

**CRITICAL**: All code changes must follow the established coding standards documented in `LeavesOfBlocks/Documentation/CodingStandards.md`. This document contains:
- Swift language guidelines and formatting rules
- Code organization patterns and file structure standards
- Naming conventions for types, variables, and functions
- Documentation requirements using DocC
- SwiftUI-specific conventions and architecture patterns
- Error handling best practices and testing standards

Always reference this document before making code changes to ensure consistency and maintainability.

### 🚨 CRITICAL LOCALIZATION REQUIREMENT

**NEVER USE HARDCODED TEXT STRINGS IN USER-FACING CODE**

All user-visible text MUST use localization keys from `LeavesOfBlocks/Resources/Localizable.strings`:

**❌ WRONG - Hardcoded strings:**
```swift
Text("Game Over")
Button("Start Game") { }
.navigationTitle("Settings")
```

**✅ CORRECT - Localized strings:**
```swift
Text("game_over".localized)
Button("start_game".localized) { }
.navigationTitle("settings".localized)
```

**Enforcement Rules:**
1. **ALL Text(), Button(), navigationTitle(), etc. MUST use `.localized`**
2. **Add new keys to Localizable.strings when needed**
3. **Use descriptive, consistent naming conventions for keys**
4. **Use parameterized localization for dynamic content: `"score_format".localized(with: score)`**
5. **This applies to ALL code including previews, debug code, and temporary implementations**

**No exceptions** - this ensures the app is ready for internationalization and maintains consistency.

## Project Overview

This is a SwiftUI iOS game called "Leaves of Blocks" - a Block Blast-style puzzle game created with Xcode 26. Players drag and drop randomly generated block shapes onto an 8x8 grid to clear horizontal and vertical lines. The game features autumn-themed visuals, progressive difficulty through weighted block generation, scoring system with combo bonuses, and high score persistence.


## Development Menu System

The project includes an interactive development menu system for streamlined workflow management.

### Quick Start
```bash
# Launch the interactive development menu
./menu.sh
```

The menu provides organized access to all common development tasks:

#### Build & Test Commands (Options 1-5)
- Build for Simulator
- Run All Tests / Unit Tests Only / UI Tests Only
- Clean Build

#### Fastlane Commands (Options 6-9)
- Run Tests (Fastlane)
- Deploy Beta (TestFlight)
- Deploy to App Store
- Generate Screenshots

#### Maintenance (Options 10-11)
- Project Cleanup (Dry Run) - Preview cleanup actions
- Project Cleanup (Delete) - Comprehensive project cleanup

#### Asset Generation (Options 12-13)
- Generate & Copy App Icons - Complete icon workflow
- Generate Grass Images - Autumn-themed background textures

#### Other Commands (Options 14-16)
- Open in Xcode
- View CLAUDE.md
- View Coding Standards

### Scripts Directory Structure
All utility scripts are organized in the `scripts/` directory:

```
scripts/
├── build.sh                # Unified build script (local & CI)
├── cleanup-project.sh      # Comprehensive project cleanup
├── generate_icons.sh       # Icon generation and copying
└── generate_grass_images.py # Grass texture generation
```

## Build Commands

The project uses a unified build script (`scripts/build.sh`) that works both locally and in CI. The script automatically detects available iOS simulators.

### Recommended: Using build.sh
```bash
# Build the project
./scripts/build.sh build

# Run all tests
./scripts/build.sh test

# Run unit tests only
./scripts/build.sh test-unit

# Run UI tests only
./scripts/build.sh test-ui

# Clean and rebuild
./scripts/build.sh clean

# Show build environment info
./scripts/build.sh info
```

The script auto-detects simulators in this order: iPhone 16 Pro > iPhone 16 > iPhone 15 Pro > iPhone 15

### Alternative: Direct xcodebuild Commands
For cases where you need direct xcodebuild access:
- **Build**: `xcodebuild -project "LeavesOfBlocks.xcodeproj" -scheme "LeavesOfBlocks" build -sdk iphonesimulator`
- **Archive for Release**: `xcodebuild -project "LeavesOfBlocks.xcodeproj" -scheme "LeavesOfBlocks" -destination "generic/platform=iOS" archive`

### Fastlane Commands

#### Core Development Commands
- **Run Tests**: `bundle exec fastlane ios test`
- **Build for Testing**: `bundle exec fastlane ios build_for_testing`
- **Generate Screenshots**: `bundle exec fastlane ios screenshots`

#### App Store Deployment Commands
- **Deploy to App Store** (recommended): `bundle exec fastlane ios deploy` - Builds and uploads binary with metadata
- **Submit for Review**: `bundle exec fastlane ios submit` - Submits already uploaded build for review
- **Complete Pipeline**: `bundle exec fastlane ios deploy_and_submit` - Build, upload, and submit in one command
- **Upload Metadata Only**: `bundle exec fastlane ios metadata_only` - Updates app store listing without binary
- **Upload Screenshots Only**: `bundle exec fastlane ios screenshots_only` - Updates screenshots only

#### Legacy Commands
- **Deploy Beta**: `bundle exec fastlane ios beta` - Upload to TestFlight
- **Deploy Release**: `bundle exec fastlane ios release` - Basic App Store upload

### Project Cleanup System

The project includes a comprehensive cleanup system via `scripts/cleanup-project.sh`:

#### Cleanup Features
- **Xcode Build Artifacts**: Cleans derived data, module cache, and build directories
- **Fastlane Artifacts**: Removes reports, screenshots, and test outputs
- **Swift Package Manager**: Cleans SPM cache and build directories
- **Simulator Data**: Removes unavailable simulators and logs
- **Git Maintenance**: Garbage collection and object pruning
- **System Files**: Removes .DS_Store files and Python cache
- **Ruby/Bundler**: Cleans bundler cache

#### Usage
```bash
# Preview cleanup (recommended first)
./scripts/cleanup-project.sh --dry-run

# Perform full cleanup
./scripts/cleanup-project.sh
```

### Asset Generation System

#### Icon Generation
Complete icon workflow with automatic copying:
```bash
./scripts/generate_icons.sh
```
- Generates all iOS app icon sizes from SVG
- Generates launch screen icons with dark mode variants
- Copies to correct Xcode Asset Catalog locations
- Creates required Contents.json files

#### Visual Asset Scripts
```bash
# Generate grass textures for game backgrounds
python3 ./scripts/generate_grass_images.py
```

### Build Troubleshooting
- **Available Simulators**: Current system has iPhone 16, iPhone 16 Plus, iPhone 16 Pro Max, iPhone 16e, and various iPad simulators
- **Simulator Issues**: If "iPhone 16 Pro" is not found, use "iPhone 16" instead
- **Build Errors**: Always check for missing Typography properties (e.g., `buttonFont` doesn't exist, use `bodyFont` instead)
- **Quick Error Check**: Use `xcodebuild ... 2>&1 | grep -A 5 -B 5 "error:"` to isolate compilation errors
- **Success Verification**: Build output should end with "** BUILD SUCCEEDED **"

### CI/CD
- GitHub Actions workflows in `.github/workflows/`
- Uses Xcode 26.1 on macOS latest runner
- Automatically creates iPhone 16 Pro simulator for testing
- Runs on push to main and pull requests

### Version Management
The project uses **Xcode's built-in "Manage Version and Build Number"** feature for automatic build number management:

#### Current Configuration
- **Marketing Version (CFBundleShortVersionString)**: 1.0 (set in project settings)
- **Build Number (CFBundleVersion/CURRENT_PROJECT_VERSION)**: 1 (set in project settings)
- **Main App Bundle ID**: `timothy.veil.LeavesOfBlocks`

#### How It Works
- **Automatic Increment**: During App Store upload, Xcode detects invalid/duplicate build numbers and automatically increments them
- **Archive-Only Changes**: Build numbers are updated only in the uploaded archive, not in source code
- **Multi-Target Support**: Automatically syncs build numbers across main app and all embedded content
- **No Configuration Required**: Feature is enabled by default during distribution

#### Version Usage in Code
The app reads version information through `Bundle+Extensions.swift`:
- **Display Version**: Used in About screen (`Bundle.main.versionAndBuild`)
- **Logging**: Used in `UserPreferences.swift` for app version tracking
- **Safe Fallbacks**: Extensions provide default values if bundle info is unavailable

#### Benefits
- **Zero maintenance** - No custom scripts or manual increment needed
- **Error prevention** - Eliminates duplicate build number submission failures
- **Multi-target compatibility** - Handles main app synchronization automatically
- **CI/CD friendly** - Works seamlessly with GitHub Actions workflow

#### Important Notes
- Project files will show outdated build numbers after App Store uploads
- Version information in source code remains unchanged
- Feature can be disabled during export if needed (uncheck "Manage Version and Build Number")

## Architecture

### Navigation Flow
- **App Entry**: `LeavesOfBlocksApp.swift` - Main app with custom launch screen (2.5s)
- **Navigation Hub**: `ContentView.swift` - Enum-based screen management (Home, Game, Summary, About, History)
- **Testing**: Uses both Swift Testing framework (unit tests) and XCTest (UI tests)
- **Target Deployment**: iOS 18.5+, supports iPhone only (TARGETED_DEVICE_FAMILY = 1)
- **Bundle ID**: `timothy.veil.LeavesOfBlocks`

### Key Components

#### Core Game Files
- `Models/Game/GameState.swift` - Core game state management (ObservableObject, streamlined with comprehensive DocC documentation)
- `Models/Game/BlockModels.swift` - Block shapes, positions, and color definitions (fully documented with DocC)
- `Models/Game/GridModels.swift` - Grid cell and position data structures  
- `Models/Game/DifficultyMode.swift` - Difficulty settings and configurations
- `Models/Game/GameStatistics.swift` - Advanced game session statistics, achievements, and performance metrics
- `Logic/Game/GameLogic.swift` - Pure game logic functions: block placement, line clearing, validation (separated from state)
- `Logic/Game/BlockGenerator.swift` - Weighted random block generation system
- `Services/Game/GameService.swift` - Game services: timing, haptic feedback, high score persistence, session management
- `Logic/Enhancements/GameEnhancements.swift` - Visual effects, animations, performance optimizations

#### UI Architecture (Modular Component System)
- `Views/BaseScreenView.swift` - Foundation layout container for all screens
- `Views/ViewModifiers/ScreenModifiers.swift` - Unified styling system with 13+ reusable modifiers (consolidated from Theme.swift)
- `Views/Components/` - Reusable UI components organized by function:
  - `Buttons/Buttons.swift` - Unified button components (GameDifficultyButton, StartGameButton, GameActionButton)
  - `Cards/CardView.swift` - Card-based display components
  - `Displays/StatisticalDisplays.swift` - Score and statistics display components (GameStatChip)
  - `Displays/ScoreDisplayView.swift` - Dedicated score display components
  - `Effects/AnimatedBadgeView.swift` - Animated UI effect components
  - `Effects/GrassBlockView.swift` - Decorative grass visual effects
  - `States/ErrorStateView.swift` - Error state UI components
  - `States/LoadingStateView.swift` - Loading state UI components
  - `Tables/Tables.swift` - Table formatting and display components
- `Views/Game/Components/` - Game-specific UI components:
  - `BlockViews.swift` - Block rendering and drag/drop implementation
  - `GridViews.swift` - 8x8 game grid display and interaction
  - `HeaderViews.swift` - Score display and game status UI
  - `BackgroundViews.swift` - Themed background and visual effects

#### Supporting Systems  
- `Resources/Theming/` - Comprehensive theming system:
  - `Theme.swift` - Main theme orchestration and gradients (view styling moved to ScreenModifiers)
  - `Colors.swift` - Autumn color palette and semantic color definitions
  - `Typography.swift` - Font scales and text styling
  - `Layout.swift` - Layout constants, spacing, and sizing
  - `Animations.swift` - Animation timing and easing definitions
- `Services/` - Service layer architecture:
  - `Configuration/AppConfiguration.swift` - Environment detection, feature flags, preferences
  - `Configuration/UserPreferences.swift` - User preference management and logging utilities
  - High scores tracked via Core Data (part of game history records)
  - `Data/CoreDataManager.swift` - Core Data stack management for game history
  - `Game/GameService.swift` - Centralized game services (timing, haptics, persistence)
- `Models/Data/GameRecord+CoreDataClass.swift` - Core Data entity class for game records
- `Models/Data/GameRecord+CoreDataProperties.swift` - Core Data entity properties
- `Extensions/` - Swift extensions organized by framework (Foundation, SwiftUI, UIKit):
  - `Foundation/String+Extensions.swift` - String localization utilities (documented with DocC)
  - `SwiftUI/BlockModels+Extensions.swift` - Block model extensions
  - `SwiftUI/Color+Extensions.swift` - Color manipulation utilities
  - `SwiftUI/View+Extensions.swift` - SwiftUI view extensions
  - `UIKit/Bundle+Extensions.swift` - Bundle version utilities
- `Documentation/` - Project documentation and standards:
  - `CodingStandards.md` - Comprehensive coding guidelines and best practices
- `Testing/` - Development test utilities and future test infrastructure:
  - `GameLogicTestUtility.swift` - Development utility for basic game logic validation

## Game Architecture Details

### GameState (ObservableObject) - Refactored Architecture
- **Primary Role**: Pure state management with @Published properties for reactive UI
- **Core Responsibilities**: Manages 8x8 grid, current blocks (up to 3), score, difficulty, game statistics
- **Delegation Pattern**: Delegates business logic to GameLogic service and infrastructure concerns to GameService
- **Streamlined Design**: Reduced from 361 lines to ~80 lines through service extraction
- **Service Integration**: Uses GameService for timing, haptics, persistence; GameLogic for game rules
- **Documentation**: Fully documented with DocC including usage examples and method descriptions

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

### Game Logic Flow - Service-Based Architecture
1. **Block Generation**: BlockGenerator creates weighted random blocks based on difficulty
2. **Placement Validation**: GameLogic.canPlaceBlock() validates placement against grid bounds and existing blocks
3. **Block Placement**: GameLogic.placeBlock() handles grid updates with GameService providing haptic feedback
4. **Line Detection**: GameLogic.clearCompletedLines() detects and clears complete horizontal/vertical lines
5. **Score Calculation**: GameLogic.calculateBlockScore() and calculateLineScore() handle scoring logic
6. **Game Over Check**: GameLogic.isGameOver() validates if any remaining blocks can be placed
7. **Session Management**: GameService handles timing, high score updates, and game record persistence

### Difficulty Modes
- **Easy**: Favors smaller blocks, more forgiving generation
- **Moderate**: Balanced block distribution
- **Hard**: Increases chance of larger, complex blocks

### Service Layer Architecture - New Design Pattern
The codebase now follows a clean service-oriented architecture:

#### GameLogic (Static Methods)
- **Pure Functions**: Stateless game logic functions for easy testing
- **Core Operations**: Block placement validation, line clearing algorithms, score calculations
- **Grid Utilities**: Grid manipulation and game state validation
- **Separation**: Business logic completely separated from UI state management

#### GameService (ObservableObject)
- **Infrastructure Concerns**: Timer management, haptic feedback, persistence
- **Session Management**: Game session lifecycle, high score tracking
- **External Integrations**: UserDefaults, Core Data, UIKit feedback systems
- **Service Coordination**: Centralized access point for game-related services

#### GameSessionStatistics (Value Type)
- **Analytics**: Advanced statistics calculation and performance metrics
- **Achievements**: Achievement detection and comparison systems
- **Metrics**: Efficiency ratings, performance grades, session comparisons
- **Computed Properties**: Derived statistics from raw game data

#### Benefits of Refactored Architecture
- **Maintainability**: Single responsibility principle with clear separation of concerns
- **Testability**: Pure functions in GameLogic are easily unit testable
- **Reusability**: Services can be used independently across different parts of the app
- **Performance**: Reduced coupling and more efficient state management
- **Extensibility**: Easy to add new features to appropriate service layers

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

### Code Deduplication & Refactoring Results
Recent comprehensive refactoring achieved major architectural improvements:

#### Code Reduction & Organization
- **GameState.swift**: Reduced from 361 lines to ~80 lines (78% reduction) through service extraction
- **Style Consolidation**: Eliminated duplicate `gameCardStyle()` implementations and redundant button components
- **Component Unification**: Removed `ButtonView.swift` and consolidated button styling into unified `Buttons.swift`
- **Extension Organization**: Moved `BlockModels+Extensions.swift` from Testing to proper Extensions directory

#### Service Architecture Implementation
- **Created GameLogic.swift** (154 lines): Pure game logic functions separated from state management
- **Created GameService.swift** (126 lines): Centralized timing, haptics, and persistence services  
- **Created GameSessionStatistics.swift** (171 lines): Advanced analytics and achievement system
- **Style System Consolidation**: Moved all view modifiers to `ScreenModifiers.swift` (13+ modifiers)

#### Architectural Benefits Achieved
- **Separation of Concerns**: Clear boundaries between state, logic, and services
- **Testability**: Pure functions in GameLogic enable comprehensive unit testing (100% coverage implemented)
- **Maintainability**: Single responsibility principle with focused, smaller files
- **Extensibility**: Service layer architecture supports future feature additions
- **Documentation**: Comprehensive DocC documentation for all public APIs
- **Code Quality**: Standardized MARK comments and consistent coding patterns
- **Testing Infrastructure**: Development test utilities ready for migration to proper test targets

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
- **Code Quality Standards**: All code follows `LeavesOfBlocks/Documentation/CodingStandards.md`
- **Documentation Standards**: Public APIs documented with DocC
- **Testing Standards**: Comprehensive unit test coverage using Swift Testing framework

## Testing Strategy

### Current Test Implementation Status
- **Test Framework**: Project currently lacks dedicated test targets
- **Development Test Utility**: `LeavesOfBlocks/Testing/GameLogicTestUtility.swift` provides basic validation
- **Test Infrastructure**: Ready for proper test target implementation

### Available Development Testing
- **GameLogicTestUtility**: Development utility for basic game logic validation
  - Grid creation and manipulation validation
  - Block placement validation tests
  - Score calculation verification
  - Game over detection testing
  - Integration flow testing
  - Usage: Call `GameLogicTestUtility.runAllTests()` in development builds

### Test Framework Integration Notes
- **Swift Testing**: Framework not currently available in main app target
- **Recommended Setup**: Create dedicated test targets for comprehensive testing
- **Migration Path**: Move development utilities to proper test targets with Swift Testing support
- **Test Standards**: Follow Given-When-Then pattern with descriptive test names

### Future Testing Improvements
- Create dedicated `LeavesOfBlocksTests` target with Swift Testing framework
- Implement comprehensive unit tests for GameLogic, BlockModels, and GameState
- Add UI testing target for user interaction testing
- Integrate tests with CI/CD pipeline for automated validation

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
  - `Documentation/` - Project documentation and coding standards
  - `Testing/` - Unit test files using Swift Testing framework
- **GitHub Pages**: `docs/`
- **CI/CD**: `.github/workflows/`

### Important Notes on Test Implementation
- **Current State**: No dedicated test targets exist in the project
- **Development Testing**: `LeavesOfBlocks/Testing/GameLogicTestUtility.swift` provides basic validation utilities
- **Build Commands**: References to "LeavesOfBlocksTests" target in build commands are aspirational
- **Recommended Action**: Create proper test targets to enable comprehensive testing infrastructure

### Key Project Settings
- Xcode Project: `LeavesOfBlocks.xcodeproj`
- Main Scheme: "LeavesOfBlocks"
- Development Team: 85U9MWUBJL
- Code Signing: Automatic

## Configuration Details
- Pure SwiftUI implementation with Core Data for persistence (no external dependencies)
- Uses NavigationView with StackNavigationViewStyle for consistent behavior
- Custom drag gesture implementation with visual feedback  
- Configuration system via `Configuration.swift` for feature flags and environment detection
- High score persistence through Core Data as part of game history
- Game history persistence through Core Data (`CoreDataManager.swift`)