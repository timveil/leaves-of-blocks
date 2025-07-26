# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a SwiftUI iOS game called "Leaves of Blocks" - a Block Blast-style puzzle game created with Xcode 16.4. Players drag and drop randomly generated block shapes onto a 10x10 grid to clear horizontal and vertical lines. The game features no ads, progressive difficulty through weighted block generation, scoring system, and high score persistence.

## Build Commands

This project uses Xcode's build system. Common commands:

- **Build**: `xcodebuild -project "Leaves of Blocks.xcodeproj" -scheme "Leaves of Blocks" build`
- **Test**: `xcodebuild -project "Leaves of Blocks.xcodeproj" -scheme "Leaves of Blocks" test -destination 'platform=iOS Simulator,name=iPhone 15'`
- **UI Tests**: `xcodebuild -project "Leaves of Blocks.xcodeproj" -scheme "Leaves of Blocks" test -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:"Leaves of BlocksUITests"`

## Architecture

- **App Entry Point**: `Leaves_of_BlocksApp.swift` - Main app struct with `@main` attribute
- **Main View**: `ContentView.swift` - Primary SwiftUI view showing the app content
- **Testing**: Uses both Swift Testing framework (unit tests) and XCTest (UI tests)
- **Target Deployment**: iOS 18.5+, supports iPhone and iPad
- **Bundle ID**: `nineforty.one.Leaves-of-Blocks`

## Key Files

- `Leaves of Blocks/Leaves_of_BlocksApp.swift` - App entry point
- `Leaves of Blocks/ContentView.swift` - Main view that hosts the game
- `Leaves of Blocks/GameModels.swift` - Core game data models (GameState, BlockShape, GridCell)
- `Leaves of Blocks/GameViews.swift` - SwiftUI views for game board, blocks, and drag/drop
- `Leaves of Blocks/GameEnhancements.swift` - Visual effects, animations, and weighted block generation
- `Leaves of Blocks/HighScoreManager.swift` - High score persistence using UserDefaults
- `Leaves of BlocksTests/Leaves_of_BlocksTests.swift` - Unit tests using Swift Testing
- `Leaves of BlocksUITests/Leaves_of_BlocksUITests.swift` - UI tests using XCTest

## Game Architecture

- **GameState**: ObservableObject managing 10x10 grid, current blocks, scoring, and game state
- **BlockShape**: Represents different block configurations with positions and colors
- **Drag & Drop**: Custom SwiftUI implementation with visual feedback and preview positioning
- **Scoring**: Points for block placement (10 per cell) + line clearing bonuses (100 per line + combo multipliers)
- **Block Generation**: Weighted random system favoring smaller blocks, with 21 different shapes
- **Line Clearing**: Detects and clears complete horizontal/vertical lines simultaneously

## Development Notes

- Uses SwiftUI with drag/drop gestures and animations
- Swift version 5.0, iOS 18.5+ deployment target
- ObservableObject pattern for reactive UI updates
- UserDefaults for high score persistence
- No external dependencies - pure SwiftUI implementation
- Supports both iPhone and iPad orientations