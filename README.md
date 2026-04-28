<div align="center">
  <img src="docs/app-icon.png" alt="Leaves of Blocks App Icon" width="120" height="120" />
  
  # Leaves of Blocks
  
  [![iOS Build and Test](https://github.com/timveil/leaves-of-blocks/actions/workflows/ios.yml/badge.svg)](https://github.com/timveil/leaves-of-blocks/actions/workflows/ios.yml)
  
  **A SwiftUI iOS puzzle game with autumn-themed visuals and intelligent difficulty balancing**
  
  Players drag and drop block shapes onto an 8x8 grid to clear lines while the game adapts to their skill level
</div>

---

## Table of Contents

- [Key Features](#key-features)
- [Quick Start](#quick-start)
- [Game Mechanics](#game-mechanics)
- [Architecture](#architecture)
- [Documentation](#documentation)
- [Deployment](#deployment)
- [Configuration](#configuration)
- [Future Enhancements](#future-enhancements)
- [License](#license)

## Key Features

### Intelligent Gameplay
- **Smart Difficulty System**: Advanced tiered block generation that responds to player skill
- **Player Analytics**: Comprehensive efficiency metrics and performance tracking
- **Solvability Guarantee**: Advanced algorithms ensure every puzzle is solvable
- **Progressive Challenge**: Consequence-based difficulty that maintains engagement

### Beautiful Design
- **Autumn Theme**: Stunning seasonal visuals with custom animations
- **Intuitive Controls**: Smooth drag-and-drop with haptic feedback
- **Responsive UI**: Optimized for all iPhone sizes with 60fps performance
- **Accessibility**: Full accessibility support built-in

### Rich Analytics
- **Performance Grades**: A+ through D efficiency ratings
- **Strategic Analysis**: Master through Beginner skill classifications
- **Historical Tracking**: Detailed game history with trend analysis
- **Achievement System**: Track improvement over time

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
- **Framework**: SwiftUI + SpriteKit (zero external runtime dependencies)
- **State Management**: iOS 17+ `@Observable` macro with `@MainActor` isolation
- **Persistence**: Core Data for game history and analytics

### Code Organization
```
LeavesOfBlocks/
├── App/                    # Application entry and navigation
├── Views/                  # Modular UI components
│   ├── Components/         # Reusable UI elements
│   ├── Game/              # Game-specific views
│   └── History/           # Analytics and history
├── Models/                # Data models and game state
├── Logic/                 # Game algorithms, grid analysis, behavior tracking
├── Services/              # Infrastructure services (Core Data, timing, haptics)
├── SpriteKit/             # GameScene, nodes, particle effects
├── Resources/             # Themes, assets, localization
└── Documentation/         # Project documentation

scripts/                   # Development utilities
├── cleanup-project.sh     # Comprehensive project cleanup
├── generate_icons.sh      # Icon generation and copying
└── generate_grass_images.py # Grass texture generation

menu.sh                    # Interactive development menu
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

For advanced users, direct Fastlane commands are available:

```bash
# Setup (one-time)
bundle install

# Core deployment commands
bundle exec fastlane ios beta          # TestFlight
bundle exec fastlane ios deploy        # App Store
bundle exec fastlane ios submit        # Submit for review
```

See [CLAUDE.md](./CLAUDE.md) for comprehensive build commands and deployment procedures.

## Documentation

- **[CONTRIBUTING.md](./CONTRIBUTING.md)**: How to set up the project, run tests, and submit changes
- **[CHANGELOG.md](./CHANGELOG.md)**: Release notes and version history
- **[Coding Standards](./LeavesOfBlocks/Documentation/CodingStandards.md)**: Swift style guide and conventions
- **[SECURITY.md](./SECURITY.md)**: How to report security issues

## Configuration

The game includes a flexible configuration system for:
- **Feature Flags**: Enable/disable experimental features
- **Performance Tuning**: Adjust algorithm parameters
- **Debug Options**: Enhanced logging and development tools
- **Difficulty Balance**: Fine-tune tier thresholds and weights

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

## Future Enhancements

### Short-term
- [ ] Advanced configuration system for difficulty tuning
- [ ] Enhanced logging and analytics dashboard
- [ ] Achievement system with unlockable content
- [ ] Export functionality for performance data

### Long-term
- [ ] Machine learning-based adaptive difficulty
- [ ] Social features and leaderboards
- [ ] AI-powered coaching and suggestions
- [ ] Cross-platform synchronization

## License

This project is licensed under the [MIT License](LICENSE).

## Author

**Tim Veil** — [@timveil](https://github.com/timveil)

For questions, bugs, or feature requests, please [open an issue](https://github.com/timveil/leaves-of-blocks/issues).

---

<div align="center">
  <hr>
  <img src="docs/app-icon.png" alt="Leaves of Blocks" width="60" height="60" />
  <p><strong>Leaves of Blocks</strong> - Where autumn meets intelligent puzzle design</p>
  <p><em>Built with SwiftUI • Powered by advanced algorithms • Designed for delight</em></p>
</div>