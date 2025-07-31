
[![iOS Build and Test](https://github.com/timveil/leaves-of-blocks/actions/workflows/ios.yml/badge.svg)](https://github.com/timveil/leaves-of-blocks/actions/workflows/ios.yml)
[![Xcode - Build and Analyze](https://github.com/timveil/leaves-of-blocks/actions/workflows/objective-c-xcode.yml/badge.svg)](https://github.com/timveil/leaves-of-blocks/actions/workflows/objective-c-xcode.yml)

# Leaves of Blocks

A SwiftUI iOS puzzle game inspired by Block Blast, featuring autumn-themed visuals and addictive gameplay. Players drag and drop randomly generated block shapes onto an 8x8 grid to clear horizontal and vertical lines.

## Features

### Gameplay
- 🍂 Beautiful autumn-themed design with custom animations and effects
- 🎮 Intuitive drag-and-drop block placement with visual feedback
- 📊 Progressive difficulty system (Easy, Moderate, Hard) with weighted block generation
- 🏆 High score tracking with persistent storage across game sessions
- 🎯 Advanced scoring system with combo bonuses for clearing multiple lines
- 📱 Optimized for iPhone with responsive layout and smooth 60fps animations

### User Experience  
- 📖 Interactive "How to Play" guide with detailed game instructions and pro tips
- 📈 Comprehensive game history with detailed statistics per session
- 🎨 Consistent, polished UI with unified styling system
- ♿ Accessibility features built into all interactive components
- 🚀 Fast app startup with custom launch screen (2.5s)

### Technical Excellence
- 🏗️ Modular component architecture with extensive code deduplication
- 🎨 Unified styling system with 10+ reusable view modifiers
- 📦 Pure SwiftUI implementation (no external dependencies)
- 🔧 App Clip support for instant app experiences
- 🤖 Automated CI/CD with GitHub Actions for quality assurance

## Requirements

- Xcode 16.4 or later
- iOS 18.5+ deployment target
- macOS with Xcode command line tools

## Build Instructions

### Using Xcode GUI
1. Open `LeavesOfBlocks.xcodeproj` in Xcode
2. Select your target device/simulator
3. Press ⌘+R to build and run

### Using Command Line

```bash
# Build the project
xcodebuild -project "LeavesOfBlocks.xcodeproj" -scheme "LeavesOfBlocks" build

# Clean build
xcodebuild -project "LeavesOfBlocks.xcodeproj" -scheme "LeavesOfBlocks" clean build
```

## Testing

The project includes both unit tests (Swift Testing framework) and UI tests (XCTest).

### Run All Tests
```bash
xcodebuild -project "LeavesOfBlocks.xcodeproj" -scheme "LeavesOfBlocks" test -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Run Unit Tests Only
```bash
xcodebuild -project "LeavesOfBlocks.xcodeproj" -scheme "LeavesOfBlocks" test -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:"LeavesOfBlocksTests"
```

### Run UI Tests Only
```bash
xcodebuild -project "LeavesOfBlocks.xcodeproj" -scheme "LeavesOfBlocks" test -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:"LeavesOfBlocksUITests"
```

## Deployment

### CI/CD
The project includes GitHub Actions workflows for automated builds and tests:
- **iOS Build and Test** (`ios.yml`): Builds and tests using iOS Simulator  
- **Xcode Build and Analyze** (`objective-c-xcode.yml`): Clean build with static analysis
- Uses Xcode 16.2 on macOS latest runner
- Automatically creates iPhone 16 simulator for testing
- Runs on push to main and pull requests

### Manual Deployment
1. Archive the app in Xcode: Product → Archive
2. Upload to App Store Connect through Xcode Organizer
3. Submit for review through App Store Connect

### TestFlight Deployment

TestFlight allows you to distribute beta versions of your app to internal and external testers before App Store release.

#### Prerequisites
- **Apple Developer Account** ($99/year) with Admin or App Manager role
- **App Store Connect Access** with appropriate permissions
- **Bundle ID registered** in Apple Developer Portal
- **Provisioning profiles** configured for distribution
- **App Store Connect app entry** created

#### Step-by-Step TestFlight Deployment

##### 1. Prepare Your App for Distribution

```bash
# Ensure your project builds successfully
xcodebuild -project "LeavesOfBlocks.xcodeproj" -scheme "LeavesOfBlocks" clean build -configuration Release
```

**In Xcode:**
1. Select your project in the navigator
2. Go to **Signing & Capabilities** tab
3. Set **Team** to your Apple Developer Team
4. Ensure **Bundle Identifier** matches your App Store Connect app: `timothy.veil.LeavesOfBlocks`
5. Set **Signing** to "Automatically manage signing"

##### 2. Archive Your App

**Via Xcode GUI:**
1. Select **Generic iOS Device** or **Any iOS Device** as your destination (not simulator)
2. Go to **Product → Archive** (⌘+⇧+B won't work - must use Archive)
3. Wait for the archive process to complete
4. Xcode Organizer will open automatically

**Via Command Line:**
```bash
# Archive the app for distribution
xcodebuild -project "LeavesOfBlocks.xcodeproj" \
  -scheme "LeavesOfBlocks" \
  -destination "generic/platform=iOS" \
  -archivePath "./build/LeavesOfBlocks.xcarchive" \
  archive
```

##### 3. Upload to App Store Connect

**Via Xcode Organizer:**
1. In Xcode Organizer, select your archive
2. Click **Distribute App**
3. Choose **App Store Connect**
4. Select **Upload** (not Export)
5. Choose your distribution options:
   - ✅ Upload your app's symbols
   - ✅ Manage Version and Build Number (recommended)
6. Select your **Development Team**
7. Review and click **Upload**
8. Wait for upload completion (can take 5-30 minutes)

**Via Command Line (Alternative):**
```bash
# Export for App Store
xcodebuild -exportArchive \
  -archivePath "./build/LeavesOfBlocks.xcarchive" \
  -exportPath "./build/export" \
  -exportOptionsPlist "ExportOptions.plist"

# Upload using altool (requires ExportOptions.plist)
xcrun altool --upload-app \
  --type ios \
  --file "./build/export/Leaves of Blocks.ipa" \
  --username "your-apple-id@email.com" \
  --password "app-specific-password"
```

##### 4. Configure TestFlight in App Store Connect

1. **Go to App Store Connect** (https://appstoreconnect.apple.com)
2. Navigate to **My Apps → Leaves of Blocks**
3. Click **TestFlight** tab
4. Wait for build processing (can take 10-90 minutes)
5. Once processed, your build appears under **iOS Builds**

##### 5. Set Up Testing Groups

**Internal Testing (Apple Developer Team members):**
1. Click **Internal Testing** in sidebar
2. Click **+** next to **Testers**
3. Add team members by email
4. Select your processed build
5. Click **Start Testing**

**External Testing (Public beta testers):**
1. Click **External Testing** in sidebar
2. Create a new group: **+ Add Group**
3. Name your group (e.g., "Beta Testers")
4. Add testers by email or public link
5. Select your build and add **Test Information**:
   - What to test
   - App description
   - Feedback email
   - Privacy policy URL (if required)
6. **Submit for Review** (Apple reviews external TestFlight builds)

##### 6. Distribute to Testers

**After setup:**
1. Testers receive email invitations
2. They download **TestFlight app** from App Store
3. They redeem invitation codes or click links
4. Your app appears in their TestFlight app
5. Testers can install and provide feedback

#### Version Management

**For subsequent builds:**
1. Increment **Build Number** in Xcode (CFBundleVersion)
2. Optionally update **Version Number** (CFBundleShortVersionString)
3. Repeat archive and upload process
4. New builds appear automatically in existing TestFlight groups

#### TestFlight Limits

- **Internal testers**: Up to 100 (Apple Developer team members)
- **External testers**: Up to 10,000 per app
- **Build expiry**: 90 days after upload
- **Testing groups**: Up to 100 groups
- **Apps per tester**: No limit

#### Troubleshooting Common Issues

**Build Processing Stuck:**
- Wait up to 90 minutes for initial processing
- Check App Store Connect status page
- Ensure provisioning profiles are valid

**Upload Failures:**
- Verify Bundle ID matches App Store Connect
- Check code signing certificates are valid
- Ensure deployment target matches app requirements
- Try uploading via Xcode instead of command line

**Missing Compliance:**
- Answer export compliance questions in App Store Connect
- Most games can select "No" for encryption usage

**Invalid Binary:**
- Check for missing app icons (all required sizes)
- Verify Info.plist contains required keys
- Ensure minimum iOS version compatibility

#### Command Reference

```bash
# Quick TestFlight deployment workflow
xcodebuild clean -project "LeavesOfBlocks.xcodeproj" -scheme "LeavesOfBlocks"
xcodebuild archive -project "LeavesOfBlocks.xcodeproj" -scheme "LeavesOfBlocks" -destination "generic/platform=iOS" -archivePath "./LeavesOfBlocks.xcarchive"
# Then use Xcode Organizer to upload
```

## Project Structure

```
LeavesOfBlocks.xcodeproj/           # Xcode project file
├── LeavesOfBlocks/                 # Main application source
│   ├── App/                        # Application entry and navigation
│   │   ├── LeavesOfBlocksApp.swift # App entry point with launch screen
│   │   ├── ContentView.swift       # Navigation hub with enum-based routing
│   │   └── LaunchScreen.swift      # Custom startup screen (2.5s)
│   ├── Views/                      # Modular UI architecture
│   │   ├── BaseScreenView.swift    # Foundation layout container
│   │   ├── ViewModifiers/
│   │   │   └── ScreenModifiers.swift # Unified styling system (10+ modifiers)
│   │   ├── Components/             # Reusable UI components
│   │   │   ├── Buttons/
│   │   │   │   └── GameButtons.swift # Unified button components
│   │   │   ├── Displays/
│   │   │   │   └── StatisticalDisplays.swift # Score/stats components
│   │   │   ├── Tables/
│   │   │   │   └── GameTables.swift # Table formatting components
│   │   │   ├── ErrorStateView.swift
│   │   │   ├── LoadingStateView.swift
│   │   │   └── [Other shared components]
│   │   ├── Home/                   # Home screen components
│   │   │   ├── HomeView.swift
│   │   │   └── HomeViewComponents.swift
│   │   ├── Game/                   # Game screen components
│   │   │   ├── GameViews.swift     # Main game board
│   │   │   ├── Components/
│   │   │   │   ├── GameBlockViews.swift # Block rendering & drag/drop
│   │   │   │   ├── GameGridViews.swift  # 8x8 grid display
│   │   │   │   ├── GameHeaderViews.swift # Score & status UI
│   │   │   │   └── GameBackgroundViews.swift # Themed backgrounds
│   │   │   └── Overlays/
│   │   │       ├── GameOverOverlayView.swift # Game over dialog
│   │   │       └── GameSummaryView.swift # Post-game summary
│   │   ├── History/                # Game history components
│   │   │   ├── HistoryView.swift
│   │   │   └── HistoryViewComponents.swift
│   │   ├── HowToPlay/              # Tutorial components
│   │   │   ├── HowToPlayView.swift
│   │   │   └── HowToPlayViewComponents.swift
│   │   └── About/
│   │       └── AboutView.swift
│   ├── Models/                     # Data models
│   │   ├── Game/
│   │   │   ├── GameState.swift     # Main game state (ObservableObject)
│   │   │   ├── BlockModels.swift   # Block shapes and definitions
│   │   │   ├── GridModels.swift    # Grid and position models
│   │   │   └── DifficultyMode.swift # Difficulty configurations
│   │   └── Data/                   # Core Data models
│   │       ├── GameRecord+CoreDataClass.swift
│   │       ├── GameRecord+CoreDataProperties.swift
│   │       └── LeavesOfBlocks.xcdatamodeld/
│   ├── Logic/                      # Game logic and rules
│   │   ├── Game/
│   │   │   ├── GameRules.swift     # Placement validation, line clearing
│   │   │   ├── BlockGenerator.swift # Weighted random block generation
│   │   │   ├── GamePerformance.swift # Performance optimization
│   │   │   └── GameStateValidator.swift # State validation
│   │   └── Enhancements/
│   │       └── GameEnhancements.swift # Visual effects and animations
│   ├── Services/                   # App services
│   │   ├── Configuration/
│   │   │   ├── AppConfiguration.swift # Environment & feature flags
│   │   │   └── UserPreferences.swift  # User settings
│   │   └── Data/
│   │       └── CoreDataManager.swift  # Core Data stack & high scores
│   ├── Resources/                  # App resources
│   │   ├── Theming/                # Comprehensive theme system
│   │   │   ├── Theme.swift         # Main theme orchestration
│   │   │   ├── Colors.swift        # Autumn color palette
│   │   │   ├── Typography.swift    # Font scales and text styles
│   │   │   ├── Layout.swift        # Layout constants and spacing
│   │   │   └── Animations.swift    # Animation timing and easing
│   │   └── Assets.xcassets/        # App icons and visual assets
│   ├── Extensions/                 # Swift extensions
│   │   ├── Foundation/             # Foundation framework extensions
│   │   ├── SwiftUI/               # SwiftUI framework extensions
│   │   └── UIKit/                 # UIKit framework extensions
│   └── Testing/                   # Testing utilities
│       └── Helpers/               # Test mocks and data generators
├── LeavesOfBlocksTests/           # Unit tests (Swift Testing framework)
├── LeavesOfBlocksUITests/         # UI automation tests (XCTest)
├── LeavesOfBlocksAppClip/         # App Clip target
├── LeavesOfBlocksAppClipTests/    # App Clip unit tests
├── LeavesOfBlocksAppClipUITests/  # App Clip UI tests
├── docs/                          # GitHub Pages documentation
│   └── index.html                 # Privacy policy
└── .github/workflows/             # CI/CD automation
    ├── ios.yml                    # iOS build and test
    └── objective-c-xcode.yml      # Static analysis
```

## Game Mechanics

### Navigation
- **Home Screen**: Select difficulty and start game, access how-to-play guide, view high scores, and game history
- **Game Screen**: Main gameplay with 8x8 grid and drag-and-drop blocks
- **How to Play**: Interactive guide explaining game rules, scoring, and pro tips
- **About Screen**: App information and credits
- **Game History**: View past game sessions and detailed statistics

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

### Architecture
- **Framework**: Pure SwiftUI (no external dependencies)
- **State Management**: ObservableObject/Published pattern with centralized GameState
- **UI Architecture**: Modular component system with extensive code deduplication
- **Navigation**: Enum-based screen routing with centralized ContentView hub
- **Styling System**: Unified view modifiers for consistent theming (10+ reusable modifiers)
- **Component Organization**: Feature-based directories with shared component library

### Code Quality
- **Recent Refactoring**: Eliminated 300+ lines of duplicated code through component unification
- **Reusable Components**: GameDifficultyButton, StartGameButton, GameStatChip, BaseScreenView
- **Consistent Styling**: gameContainerStyle(), game3DCardStyle(), gameGradientCardStyle() modifiers
- **Atomic Design**: Small, composable components building into complex interfaces
- **Type Safety**: Comprehensive Swift 5.0 type system with minimal optionals

### Platform Details
- **Minimum iOS**: 18.5
- **Swift Version**: 5.0
- **Target Devices**: iPhone only (TARGETED_DEVICE_FAMILY = 1)
- **Bundle ID**: `timothy.veil.LeavesOfBlocks`
- **App Clip Bundle ID**: `timothy.veil.LeavesOfBlocks.Clip`
- **Deployment**: TestFlight and App Store ready with CI/CD automation

## License

[Add your license information here]

## Author

Timothy Veil
