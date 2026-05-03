<div align="center">
  <img src="LeavesOfBlocks/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png" alt="Leaves of Blocks App Icon" width="120" height="120" />
  
  # Leaves of Blocks
  
  [![iOS Build and Test](https://github.com/timveil/leaves-of-blocks/actions/workflows/ios.yml/badge.svg)](https://github.com/timveil/leaves-of-blocks/actions/workflows/ios.yml)
  
  **An ad-free SwiftUI iOS block puzzle game — a privacy-first Block Blast alternative with intelligent difficulty balancing**
  
  Players drag and drop block shapes onto an 8x8 grid to clear lines while the game adapts to their skill level

  [Website](https://www.leavesofblocks.com/) · [Play in browser](https://www.leavesofblocks.com/play/) · [vs. Block Blast](https://www.leavesofblocks.com/vs/) · [Support](https://www.leavesofblocks.com/support/)
</div>

---

## Table of Contents

- [Key Features](#key-features)
- [Why Leaves of Blocks?](#why-leaves-of-blocks)
- [Quick Start](#quick-start)
- [Game Mechanics](#game-mechanics)
- [Architecture](#architecture)
- [Documentation](#documentation)
- [Deployment](#deployment)
- [Configuration](#configuration)
- [License](#license)

## Key Features

### Intelligent Gameplay
- **Smart Difficulty System**: Advanced tiered block generation that responds to player skill
- **Player Analytics**: Comprehensive efficiency metrics and performance tracking
- **Solvability Guarantee**: Advanced algorithms ensure every puzzle is solvable
- **Progressive Challenge**: Consequence-based difficulty that maintains engagement

### Polished Design
- **Custom Animations**: Hand-crafted visuals and particle effects
- **Intuitive Controls**: Smooth drag-and-drop with haptic feedback
- **Responsive UI**: Optimized for all iPhone sizes with 60fps performance
- **Accessibility**: Full accessibility support built-in

### Rich Analytics
- **Performance Grades**: A+ through D efficiency ratings
- **Strategic Analysis**: Master through Beginner skill classifications
- **Historical Tracking**: Detailed game history with trend analysis
- **Game Center (opt-in)**: Apple Game Center leaderboard and achievements, off by default — your data stays on the device until you opt in

### Privacy by Default
- **No ads, no third-party tracking, no data sold**
- **Offline-first**: gameplay never requires a network connection
- **Local persistence**: history and high scores live in Core Data on the device
- **Opt-in Game Center**: leaderboard and achievement sync to Apple only when the user explicitly enables it in Settings

## Why Leaves of Blocks?

Built as a privacy-respecting alternative to ad-heavy puzzle games in the same genre. The full pitch — including a try-it-now web build — lives at [leavesofblocks.com](https://www.leavesofblocks.com/). The headline:

> **Zero ads. Zero data collected. Zero in-app purchases. The puzzle is the puzzle.**

### vs. Block Blast

|                          | Leaves of Blocks                                                  | Block Blast                                                              |
|--------------------------|-------------------------------------------------------------------|--------------------------------------------------------------------------|
| **Ads**                  | None — no banners, no interstitials, no rewarded video            | Banners, interstitials, and rewarded video between rounds                |
| **In-app purchases**     | None                                                              | Yes                                                                      |
| **Data collection**      | None in-app — no analytics, no ad identifiers                     | Tracks device, gameplay, and ad interactions; shared with ad partners    |
| **Network required**     | No — fully offline; Game Center is opt-in                         | Yes                                                                      |
| **Developer**            | One independent developer (USA)                                   | Hungry Studio (Hong Kong / Singapore / Beijing)                          |

For the full side-by-side (and a less serious version of the comparison), see [leavesofblocks.com/vs](https://www.leavesofblocks.com/vs/).

## Quick Start

### Requirements
- Xcode 26+
- iOS 18.5+
- macOS with Xcode command line tools

### Build & Run
```bash
# Clone the repository
git clone https://github.com/timveil/leaves-of-blocks.git
cd leaves-of-blocks

# Use the interactive development menu (recommended)
./menu.sh

# Or build manually
xcodebuild -project "LeavesOfBlocks.xcodeproj" -scheme "LeavesOfBlocks" build
```

Or open `LeavesOfBlocks.xcodeproj` in Xcode and press ⌘+R.

### Interactive Development Menu

The project includes a comprehensive development menu for streamlined workflow:

```bash
./menu.sh
```

**Features:**
- **Build & Test Commands** - All Xcode build and test operations
- **Fastlane Integration** - TestFlight and App Store deployment
- **Project Cleanup** - Comprehensive cleanup with dry-run preview
- **Asset Generation** - Complete icon and visual asset workflows
- **Development Tools** - Quick access to documentation and project files

All utility scripts are organized in the `scripts/` directory for advanced users.

## Game Mechanics

### Core Gameplay
1. **Drag & Drop**: Move block shapes from the bottom panel to the 8x8 grid
2. **Line Clearing**: Complete horizontal or vertical lines to clear them and score points
3. **Strategic Planning**: Manage limited space while maximizing scoring opportunities
4. **Adaptive Challenge**: Game difficulty responds to your performance

### Scoring System
- **Block Placement**: 10 points per cell
- **Line Clearing**: 100 points per line
- **Combo Bonuses**: +50 points for multiple simultaneous clears
- **Efficiency Bonuses**: Better grid management leads to higher scores

### Difficulty Tiers
- **Diverse**: Complex shapes with high variety (skilled players)
- **Constrained**: Medium complexity with some limitations
- **Minimal**: Smaller, simpler shapes for learning
- **Emergency**: Guaranteed solvable blocks as safety net

## Architecture

### Technical Stack
- **Framework**: SwiftUI + SpriteKit + GameKit + Core Data (system frameworks only — zero third-party runtime dependencies)
- **State Management**: iOS 17+ `@Observable` macro with `@MainActor` isolation
- **Persistence**: Core Data for game history and analytics; Game Center leaderboards/achievements when the user opts in

### Code Organization
```
LeavesOfBlocks/
├── App/                    # Application entry and navigation
├── Views/                  # SwiftUI screens and components
│   ├── Components/         # Cross-screen reusable UI
│   ├── Game/               # Board, overlays, game-specific UI
│   ├── History/            # Game history and analytics
│   ├── Statistics/         # Aggregate stats screens
│   ├── Home/, About/, HowToPlay/, Settings/
│   └── ViewModifiers/      # Shared style modifiers
├── Models/                 # Game state and Core Data entities
├── Logic/                  # Game algorithms, grid analysis, behavior tracking
├── Services/               # Configuration, Core Data, GameKit, gameplay services
├── SpriteKit/              # GameScene, nodes, particle effects
├── Extensions/             # Foundation, SwiftUI, UIKit extensions
├── Resources/              # Themes, Localizable.xcstrings, PrivacyInfo
└── Documentation/          # Coding standards and project docs

scripts/                    # Development utilities
├── build.sh                # Unified build/test entry point
├── cleanup-project.sh      # Comprehensive project cleanup
└── generate_icons.sh       # Icon generation and copying

menu.sh                     # Interactive development menu
```

### Key Innovations
- **Grid State Analysis**: Real-time evaluation of player performance
- **Tiered Block Generation**: Context-aware difficulty adjustment
- **Solvability Validation**: Recursive backtracking ensures puzzle solvability
- **Behavior Tracking**: Comprehensive analytics without performance impact

## Deployment

### CI/CD
Automated builds and testing via GitHub Actions (`.github/workflows/ios.yml`):
- Builds on every push to `main` and pull request
- Unit and UI test suites run in parallel after a shared build job
- Derived-data caching for faster subsequent runs

### Quick Deployment

Use the interactive menu for streamlined deployment:

```bash
./menu.sh
# Select option 7: Deploy Beta (TestFlight)
# Select option 8: Deploy to App Store
```

### Manual Deployment Commands

For advanced users, direct Fastlane commands are available.

#### One-time setup

The Fastlane lanes that talk to App Store Connect (TestFlight, App Store, Game Center) need an API key. Set these env vars (typically in `fastlane/.env` — see `.env.template`):

```bash
LOCAL_APP_STORE_CONNECT_API_KEY_ID=...
LOCAL_APP_STORE_CONNECT_ISSUER_ID=...
LOCAL_APP_STORE_CONNECT_API_KEY_PATH=/abs/path/to/AuthKey_XXX.p8
```

The API key role must be **App Manager** or higher to manage Game Center entries.

```bash
bundle install                                      # install fastlane + gems
bundle exec fastlane ios test_api_auth              # smoke-test the API key
bundle exec fastlane ios setup_game_center          # register Game Center leaderboards & achievements (idempotent)
```

`setup_game_center` reads from `fastlane/GameCenterConfig.rb` and POSTs any missing leaderboard or achievement entries to App Store Connect. Re-run it any time you add or rename entries in that file.

#### Per-release deployment

```bash
bundle exec fastlane ios beta                              # TestFlight upload
bundle exec fastlane ios deploy version:patch              # App Store binary + metadata (also: minor, major, or 1.2.3)
bundle exec fastlane ios deploy_and_submit version:patch   # deploy and submit for review in one shot
bundle exec fastlane ios submit                            # submit a previously-uploaded build for review
bundle exec fastlane ios metadata_only                     # listing changes only (no binary)
bundle exec fastlane ios screenshots_only                  # screenshots only
```

`deploy` and `deploy_and_submit` regenerate the changelog from your commits, bump the marketing version, increment the build number, commit those changes, and tag `vX.Y.Z` before uploading. For the daily TestFlight loop, `beta` is enough.

See [CLAUDE.md](./CLAUDE.md) for full lane internals and deployment procedures.

## Documentation

- **[Public website](https://www.leavesofblocks.com/)**: Marketing site, in-browser demo, and FAQ
- **[CONTRIBUTING.md](./CONTRIBUTING.md)**: How to set up the project, run tests, and submit changes
- **[CHANGELOG.md](./CHANGELOG.md)**: Release notes and version history
- **[Coding Standards](./LeavesOfBlocks/Documentation/CodingStandards.md)**: Swift style guide and conventions
- **[SECURITY.md](./SECURITY.md)**: How to report security issues

## Configuration

Build-time tuning lives in `Services/Configuration/`:
- **`AppConfiguration`** — feature flags, performance constants (e.g. animation frame rate), and runtime flags driven by launch arguments (UI testing, screenshot mode)
- **`BuildConfiguration`** — compile-time DEBUG/RELEASE detection
- **`GameCenterPreference`** — UserDefaults-backed opt-in toggle (`gameCenter.enabled`, default `false`)

## Design Philosophy

### Player-Centric Design
- **Natural Consequences**: Poor decisions lead to harder grids, not easier blocks
- **Skill Recognition**: Better players get more challenging and rewarding puzzles
- **Clear Feedback**: Comprehensive analytics help players understand and improve
- **Respectful Challenge**: Difficult but always fair and solvable

### Technical Excellence
- **Performance First**: Smooth 60fps gameplay with minimal battery impact
- **Code Quality**: Extensive documentation, comprehensive testing, clean architecture
- **Maintainability**: Modular design enables easy feature additions and modifications
- **Future-Ready**: Extensible systems support planned enhancements

## License

This project is licensed under the [MIT License](LICENSE).

## Author

**Tim Veil** — [@timveil](https://github.com/timveil)

For questions, bugs, or feature requests, please [open an issue](https://github.com/timveil/leaves-of-blocks/issues).

---

<div align="center">
  <img src="LeavesOfBlocks/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png" alt="Leaves of Blocks" width="60" height="60" />
  <p><strong>Leaves of Blocks</strong> - An ad-free, privacy-first Block Blast alternative</p>
  <p><em>Built with SwiftUI • Powered by advanced algorithms • Designed for delight</em></p>
</div>