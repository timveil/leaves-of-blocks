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
- Xcode 16.4+
- iOS 18.5+
- macOS with Xcode command line tools

### Build & Run
```bash
# Clone the repository
git clone https://github.com/timveil/leaves-of-blocks.git
cd leaves-of-blocks

# Build and run
xcodebuild -project "LeavesOfBlocks.xcodeproj" -scheme "LeavesOfBlocks" build
```

Or open `LeavesOfBlocks.xcodeproj` in Xcode and press ⌘+R.

### Testing
```bash
# Run all tests
xcodebuild -project "LeavesOfBlocks.xcodeproj" -scheme "LeavesOfBlocks" test -destination 'platform=iOS Simulator,name=iPhone 16'
```

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
- **Framework**: Pure SwiftUI (zero external dependencies)
- **State Management**: ObservableObject pattern with service layer architecture
- **Persistence**: Core Data for game history and analytics
- **Performance**: Optimized with <2ms grid analysis and <10ms block generation

### Code Organization
```
LeavesOfBlocks/
├── App/                    # Application entry and navigation
├── Views/                  # Modular UI components
│   ├── Components/         # Reusable UI elements
│   ├── Game/              # Game-specific views
│   └── History/           # Analytics and history
├── Models/                # Data models and game state
├── Logic/                 # Game algorithms and rules
│   ├── Game/              # Core game logic
│   └── Analytics/         # Player behavior analysis
├── Services/              # Infrastructure services
└── Resources/             # Themes, assets, localization
```

### Key Innovations
- **Grid State Analysis**: Real-time evaluation of player performance
- **Tiered Block Generation**: Context-aware difficulty adjustment
- **Solvability Validation**: Recursive backtracking ensures puzzle solvability
- **Behavior Tracking**: Comprehensive analytics without performance impact

## Deployment

### CI/CD
Automated builds and testing via GitHub Actions:
- Builds on every push and PR
- Comprehensive test suite execution
- Static analysis and code quality checks

### Fastlane Commands
```bash
# Setup Fastlane
bundle install

# Run tests
bundle exec fastlane ios test

# Clean build artifacts
bundle exec fastlane ios clean

# Deploy to TestFlight
bundle exec fastlane ios beta

# Deploy to App Store
bundle exec fastlane ios deploy

# Submit for review
bundle exec fastlane ios submit

# Update changelog
bundle exec fastlane ios update_changelog version:1.0.4

# Generate screenshots
bundle exec fastlane ios screenshots
```

### TestFlight Distribution
1. Archive in Xcode: `Product → Archive`
2. Upload via Xcode Organizer to App Store Connect
3. Configure TestFlight groups and distribute to testers

See [CLAUDE.md](./CLAUDE.md) for detailed build commands and deployment procedures.

## Documentation

- **[CLAUDE.md](./CLAUDE.md)**: Comprehensive development guide and coding standards
- **[IMPLEMENTATION_REPORT.md](./IMPLEMENTATION_REPORT.md)**: Detailed report on player analytics system
- **[Coding Standards](./LeavesOfBlocks/Documentation/CodingStandards.md)**: Swift style guide and best practices

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

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**Timothy Veil**
- GitHub: [@timveil](https://github.com/timveil)
- Email: timothy.veil@example.com

---

<div align="center">
  <hr>
  <img src="docs/app-icon.png" alt="Leaves of Blocks" width="60" height="60" />
  <p><strong>Leaves of Blocks</strong> - Where autumn meets intelligent puzzle design</p>
  <p><em>Built with SwiftUI • Powered by advanced algorithms • Designed for delight</em></p>
</div>