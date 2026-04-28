# CLAUDE.md

Guidance for Claude Code (claude.ai/code) when working in this repository.

## Coding Standards

All code changes must follow `LeavesOfBlocks/Documentation/CodingStandards.md`. That document is the source of truth for Swift formatting, naming, file organization, DocC documentation, SwiftUI conventions, error handling, and testing standards.

### Localization Rule (Strict)

User-visible text must use the `.localized` lookup pattern from `String+Extensions.swift`, backed by `LeavesOfBlocks/Resources/Localizable.xcstrings`.

```swift
// Wrong
Text("Game Over")
.navigationTitle("Settings")

// Right
Text("game_over".localized)
.navigationTitle("settings".localized)
// Parameterized:
Text("score_format".localized(with: score))
```

This applies to `Text`, `Button`, `navigationTitle`, accessibility labels, and previews. Add new keys via Xcode's String Catalog editor.

## Project Overview

A SwiftUI + SpriteKit iOS puzzle game ("Leaves of Blocks") in the Block Blast genre. Players drag block shapes onto an 8×8 grid to clear lines. The game includes weighted block generation that adapts to player skill, autumn-themed visuals, particle effects via SpriteKit, and Core Data-backed game history.

- Bundle ID: `timothy.veil.LeavesOfBlocks`
- Deployment target: iOS 18.5+
- iPhone-only (`TARGETED_DEVICE_FAMILY = 1`)
- Xcode 26+; Swift 5
- Zero external runtime dependencies

## Build & Test

The unified entry point is `scripts/build.sh`, which auto-detects the first available iPhone simulator. The interactive `./menu.sh` exposes the same commands in a menu.

```bash
./scripts/build.sh build              # Build for simulator
./scripts/build.sh test               # Full suite, parallel
./scripts/build.sh test-unit          # Unit tests only
./scripts/build.sh test-ui            # UI tests only
./scripts/build.sh clean              # Clean and rebuild
./scripts/build.sh info               # Show build environment

# CI-optimized (build once, test separately)
./scripts/build.sh build-for-testing
./scripts/build.sh test-without-building
./scripts/build.sh test-unit-without-building
./scripts/build.sh test-ui-without-building
```

Direct xcodebuild also works:
```bash
xcodebuild -project "LeavesOfBlocks.xcodeproj" -scheme "LeavesOfBlocks" build -sdk iphonesimulator
xcodebuild -project "LeavesOfBlocks.xcodeproj" -scheme "LeavesOfBlocks" -destination "generic/platform=iOS" archive
```

### Fastlane

```bash
bundle exec fastlane ios test                  # Run tests
bundle exec fastlane ios build_for_testing     # Build artifacts
bundle exec fastlane ios screenshots           # Generate App Store screenshots

bundle exec fastlane ios beta                  # TestFlight upload
bundle exec fastlane ios deploy                # App Store binary + metadata
bundle exec fastlane ios submit                # Submit uploaded build for review
bundle exec fastlane ios deploy_and_submit     # Build, upload, submit in one
bundle exec fastlane ios metadata_only         # Update App Store listing only
bundle exec fastlane ios screenshots_only      # Update screenshots only
```

### CI

GitHub Actions in `.github/workflows/ios.yml`:
- 3-job graph: `build` → (`unit-tests`, `ui-tests`) running in parallel
- Builds use `actions/cache@v4` keyed on `project.pbxproj`
- Test artifacts uploaded via `actions/upload-artifact@v4`
- Triggers on push to `main` and on PRs touching Swift / project / scripts

### Build Troubleshooting

- iPhone 16 and earlier only have iOS 18.5 runtimes; not compatible with iOS 26.x builds. Use the iPhone 17 family on iOS 26+.
- Quickly isolate compile failures: `xcodebuild ... 2>&1 | grep -B 2 -A 5 "error:"`
- Successful builds end with `** BUILD SUCCEEDED **`.

### Version Management

The project uses Xcode's built-in **Manage Version and Build Number** (enabled by default during distribution). Build numbers auto-increment in the uploaded archive on App Store upload; source files are not modified. `Bundle+Extensions.swift` reads version info via `Bundle.main` for the About screen and logging.

## Project Structure

```
LeavesOfBlocks/
├── App/                          # Entry point, navigation hub, launch screen
│   ├── LeavesOfBlocksApp.swift
│   ├── ContentView.swift
│   └── LaunchScreen.swift
├── Models/
│   ├── Game/                     # Game state, blocks, grid, difficulty, statistics
│   └── Data/                     # Core Data entity (GameRecord)
├── Logic/Game/                   # Pure game logic (placement, line clearing, generation, analysis)
├── Services/
│   ├── Configuration/            # AppConfiguration, BuildConfiguration (logging)
│   ├── Data/                     # CoreDataManager
│   └── Game/                     # GameService (timing, haptics, persistence wrapper)
├── SpriteKit/
│   ├── GameScene.swift           # SKScene, observes GameState via withObservationTracking
│   ├── GameSceneBridge.swift     # SwiftUI ↔ SKScene drag-state bridge
│   ├── Nodes/                    # GridNode, BlockNode
│   └── Effects/                  # Particle and animation effects
├── Views/
│   ├── BaseScreenView.swift      # Foundation layout container
│   ├── ViewModifiers/            # ScreenModifiers (folkArtCard, etc.)
│   ├── Components/               # Cross-screen UI (Cards, Buttons, Displays, Effects, Tables)
│   ├── Game/                     # Board, SpriteKit host, overlays, game-specific components
│   ├── Home/, History/, About/, HowToPlay/, Settings/
├── Extensions/
│   ├── Foundation/               # Date, Int, String (.localized)
│   ├── SwiftUI/                  # BlockModels+, View+
│   └── UIKit/                    # Bundle+
├── Resources/
│   ├── Theming/                  # Theme.swift + Colors, Typography, Layout, Animations
│   ├── Localizable.xcstrings     # String Catalog
│   └── PrivacyInfo.xcprivacy
└── Documentation/CodingStandards.md
```

Tests live outside the app target:
- `LeavesOfBlocksTests/` — Swift Testing framework (preferred for new tests) and XCTest
- `LeavesOfBlocksUITests/` — XCTest, plus Fastlane `SnapshotHelper.swift`
- `TestPlan.xctestplan` — drives both targets

## Architecture

### Navigation
`ContentView` owns an `AppScreen` enum and switches between `HomeView`, `BoardView` (game), `SummaryView`, `HistoryView`, `AboutView`, `HowToPlayView`, `SettingsView`. Uses `NavigationStack` with a top-trailing menu for navigation. The launch screen shows for ~2.5s before transitioning into `ContentView`.

### State Management

`GameState` is `@Observable @MainActor` and is the single source of truth for in-flight gameplay (grid, current blocks, score, statistics, difficulty, save-overlay flag). It owns and delegates to:

- **`GameLogic`** — static, pure functions for placement validation, line clearing, scoring, game-over detection, and grid construction. No state. The right place to add new game-rule logic.
- **`GameService`** (`@Observable @MainActor`) — timer, haptics, high-score lookup, game record persistence wrapper, session lifecycle.
- **`PlayerBehaviorTracker`** — per-session efficiency/fragmentation/strategic-play analytics consumed by Summary and persisted to `GameRecord`.

`BlockGenerator` is invoked from `GameState` to produce the next batch of blocks. It uses `GridAnalysis` to score the current grid and pick a difficulty tier (`diverse` / `constrained` / `minimal` / `emergency`) before sampling weighted shapes.

### SpriteKit Bridge

The visible board is an `SKScene` (`GameScene`) hosted by `SpriteView` inside `SpriteKitGameView`. `GameSceneBridge` is a small `@MainActor` glue object that:

1. Receives drag state from SwiftUI (`BoardView` / `BlockViews`).
2. Forwards previews and confirmed placements into the scene.
3. Re-registers `withObservationTracking` callbacks when `GameState.grid` or `isGameOver` change, so the scene re-renders on state mutations without polling.
4. Triggers particle effects (line clear, combo pulse, game over, falling leaves) declared under `SpriteKit/Effects/`.

The bridge is read-only from the SpriteKit side: SwiftUI mutates `GameState`; the scene observes.

### Game Logic Flow

1. `BlockGenerator.generateTieredBlocks(...)` samples block shapes for the current grid state and difficulty.
2. `GameLogic.canPlaceBlock(...)` validates a proposed placement against the grid.
3. `GameLogic.placeBlock(...)` mutates the grid; `GameService` fires haptic feedback.
4. `GameLogic.clearCompletedLines(...)` returns cleared rows/cols and updated grid.
5. `GameLogic.calculateBlockScore` and `calculateLineScore` compute deltas (10/cell, 100/line, +50/combo line).
6. `GameLogic.isGameOver(...)` checks whether any remaining held block can fit anywhere.
7. On game over, `PlayerBehaviorTracker.finalizeSession` produces `SessionMetrics`, which `GameService.saveGameRecord` writes via `CoreDataManager`.

### Difficulty Modes

`DifficultyMode` is `.easy / .moderate / .hard`, and biases block generation:
- `.easy` favors smaller blocks
- `.moderate` is balanced
- `.hard` increases the share of larger / complex shapes

### UI System

`ScreenModifiers.swift` collects shared SwiftUI styling (e.g. `folkArtCard`). `Theme.swift` orchestrates `Colors`, `Typography`, `Layout`, and `Animations`. `BaseScreenView` provides a consistent background + grass decoration + content layout container that all screens use.

Reusable components live under `Views/Components/` (cross-screen) or `Views/Game/Components/` (gameplay-specific).

## Persistence

Core Data persists `GameRecord` entries via `CoreDataManager` (`viewContext` only). High scores are derived from the records, not stored separately. `HistoryView` reads via the manager and refreshes on context-change notifications.

## Testing Strategy

- New unit tests should use the **Swift Testing framework** with descriptive `@Test` names and Given-When-Then structure.
- `Logic/Game/GameLogic.swift` is pure and the easiest target for new coverage.
- UI tests should drive real flows; prefer `waitForExistence(timeout:)` over `sleep()`.

## GitHub Pages / docs/

`docs/` contains assets used by the README (`app-icon.png`) and is also the GitHub Pages source for the privacy-policy site. Privacy: no data collection, no networking, local-only Core Data + bundled assets.

## Open-Source Notes

- LICENSE: MIT, © Tim Veil.
- Community files: `CONTRIBUTING.md`, `SECURITY.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `.github/ISSUE_TEMPLATE/`.
- Apple Developer Team ID `85U9MWUBJL` is hardcoded in `LeavesOfBlocks.xcodeproj/project.pbxproj`. External contributors building for device need to swap their own team ID. Simulator builds require no change.
