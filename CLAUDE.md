# CLAUDE.md

Guidance for Claude Code (claude.ai/code) when working in this repository.

## Coding Standards

All code changes must follow `LeavesOfBlocks/Documentation/CodingStandards.md`. That document is the source of truth for Swift formatting, naming, file organization, DocC documentation, SwiftUI conventions, error handling, and testing standards.

Rules that span languages and tooling — rather than Swift style — live in [`conventions/`](conventions/), one file per rule, indexed in [`conventions/README.md`](conventions/README.md). Read the relevant one before adding a workflow, a script, or a new enforcement mechanism. Of particular note: **no GitHub Actions workflow inlines complex scripting** ([`conventions/workflow-scripts.md`](conventions/workflow-scripts.md)), **a rule enforced in two places is defined once** ([`conventions/shared-rule-single-source.md`](conventions/shared-rule-single-source.md)), and **every review comment is addressed and resolved before a PR merges** ([`conventions/review-comments.md`](conventions/review-comments.md)).

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

## Commit Message Format (Strict)

Every commit must follow Conventional Commits. The exact rules — regex, allowed types, max subject width — live in [`scripts/check-commit-subject.sh`](scripts/check-commit-subject.sh) (the single source of truth), enforced locally by [`.githooks/commit-msg`](.githooks/commit-msg) and on every PR by [`.github/workflows/commit-lint.yml`](.github/workflows/commit-lint.yml). The format also drives changelog generation; see [`CONTRIBUTING.md`](CONTRIBUTING.md#commit-message-format) for the type→changelog mapping.

Shape:

```
<type>(<scope>): <description>
```

```
# Wrong
Update CHANGELOG and CLAUDE docs
Bump CURRENT_PROJECT_VERSION to 19

# Right
docs: Update CHANGELOG and CLAUDE docs
chore: Bump CURRENT_PROJECT_VERSION to 19
fix(grid): Resolve block placement bug
feat(game-center): Submit final score on game over
```

**Never** bypass the hook with `--no-verify` — the CI check will reject the PR anyway. The `Co-Authored-By` trailer that Claude Code appends belongs in the commit body, not the subject.

The local hook runs only if you've pointed git at the checked-in hooks directory once per clone:

```bash
git config core.hooksPath .githooks
```

## Project Overview

A SwiftUI + SpriteKit iOS puzzle game ("Leaves of Blocks") in the Block Blast genre. Players drag block shapes onto an 8×8 grid to clear lines. The game includes weighted block generation that adapts to player skill, particle effects via SpriteKit, and Core Data-backed game history.

- Bundle ID: `timothy.veil.LeavesOfBlocks`
- Deployment target: iOS 18.5+
- iPhone-only (`TARGETED_DEVICE_FAMILY = 1`)
- Xcode 26+; Swift 5
- Zero third-party runtime dependencies (system frameworks only: SwiftUI, SpriteKit, GameKit, Core Data)
- Game Center is opt-in (off by default), gated behind `GameCenterPreference`. Entitlement lives at `LeavesOfBlocks/LeavesOfBlocks.entitlements`.

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
bundle exec fastlane ios setup_game_center     # Create/verify Game Center leaderboards & achievements
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
├── LeavesOfBlocks.entitlements   # com.apple.developer.game-center
├── Services/
│   ├── Configuration/            # AppConfiguration, BuildConfiguration, GameCenterPreference
│   ├── Data/                     # CoreDataManager
│   └── Game/                     # GameService, GameCenterService (auth, score submit, achievements)
├── SpriteKit/
│   ├── GameScene.swift           # SKScene, observes GameState via withObservationTracking
│   ├── GameSceneBridge.swift     # SwiftUI ↔ SKScene drag-state bridge
│   ├── SpriteKitColorBridge.swift # SwiftUI Color ↔ SKColor helpers
│   ├── Nodes/                    # GridNode, BlockNode
│   └── Effects/                  # Particle and animation effects
├── Views/
│   ├── BaseScreenView.swift      # Foundation layout container
│   ├── ViewModifiers/            # ScreenModifiers (folkArtCard, contentCard)
│   ├── Components/               # Cross-screen UI (Cards, Buttons, Displays, WhitmanSticker, etc.)
│   ├── Game/                     # Board, SpriteKit host, overlays, game-specific components
│   ├── Home/, History/, About/, HowToPlay/, Settings/, Statistics/
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
`ContentView` owns an `AppScreen` enum and switches between `HomeView`, `BoardView` (game), `SummaryView`, `HistoryView`, `StatisticsView`, `AboutView`, `HowToPlayView`, `SettingsView`. Uses `NavigationStack` with a top-trailing menu for navigation. The launch screen shows for ~2.5s before transitioning into `ContentView`.

### State Management

`GameState` is `@Observable @MainActor` and is the single source of truth for in-flight gameplay (grid, current blocks, score, statistics, difficulty, save-overlay flag). It owns and delegates to:

- **`GameLogic`** — static, pure functions for placement validation, line clearing, scoring, game-over detection, and grid construction. No state. The right place to add new game-rule logic.
- **`GameService`** (`@Observable @MainActor`) — timer, haptics, high-score lookup, game record persistence wrapper, session lifecycle. Also forwards final scores into `GameCenterService` (no-op when off/unauthenticated).
- **`GameCenterService`** (`@MainActor @Observable` singleton, `Services/Game/GameCenterService.swift`) — GameKit wrapper. Owns auth state, score submission, achievement reporting, and dashboard presentation. All entry points short-circuit when `GameCenterPreference.isEnabled == false` or the player isn't authenticated. The pure `nonisolated static func evaluateAchievements(...)` derives `PendingAchievement`s from a `SessionMetrics` and is unit-tested.
- **`PlayerBehaviorTracker`** — per-session efficiency/fragmentation/strategic-play analytics consumed by Summary and persisted to `GameRecord`.

`BlockGenerator` is invoked from `GameState` to produce the next batch of blocks. It uses `GridAnalysis` to score the current grid and pick a difficulty tier (`diverse` / `constrained` / `minimal` / `emergency`) before sampling weighted shapes.

### SpriteKit Bridge

The visible board is an `SKScene` (`GameScene`) hosted by `SpriteView` inside `SpriteKitGameView`. `GameSceneBridge` is a small `@MainActor` glue object that:

1. Receives drag state from SwiftUI (`BoardView` / `BlockViews`).
2. Forwards previews and confirmed placements into the scene.
3. Re-registers `withObservationTracking` callbacks when `GameState.grid` or `isGameOver` change, so the scene re-renders on state mutations without polling.
4. Triggers particle effects (line clear, combo pulse, game over) declared under `SpriteKit/Effects/`.

The bridge is read-only from the SpriteKit side: SwiftUI mutates `GameState`; the scene observes.

### Game Logic Flow

1. `BlockGenerator.generateTieredBlocks(...)` samples block shapes for the current grid state and difficulty.
2. `GameLogic.canPlaceBlock(...)` validates a proposed placement against the grid.
3. `GameLogic.placeBlock(...)` mutates the grid; `GameService` fires haptic feedback.
4. `GameLogic.clearCompletedLines(...)` returns cleared rows/cols and updated grid.
5. `GameLogic.calculateBlockScore` and `calculateLineScore` compute deltas (10/cell, 100/line, +50/combo line).
6. `GameLogic.isGameOver(...)` checks whether any remaining held block can fit anywhere.
7. On game over, `PlayerBehaviorTracker.finalizeSession` produces `SessionMetrics`, which `GameService.saveGameRecord` writes via `CoreDataManager` and then forwards to `GameCenterService.shared.submitFinalScore(...)`. The submission is a no-op unless the user has opted in and authenticated.

### Difficulty Modes

`DifficultyMode` is `.easy / .moderate / .hard`, and biases block generation:
- `.easy` favors smaller blocks
- `.moderate` is balanced
- `.hard` increases the share of larger / complex shapes

### UI System

`ScreenModifiers.swift` collects shared SwiftUI styling (`folkArtCard` is the primitive; `contentCard` is the preferred wrapper for new code). `Theme.swift` orchestrates `Colors`, `Typography`, `Layout`, and `Animations`. `BaseScreenView` wraps screens with `GameBackgroundView` (full-bleed tree illustration) and a centered content container.

Reusable components live under `Views/Components/` (cross-screen) or `Views/Game/Components/` (gameplay-specific).

### Game Center

GameKit integration is opt-in. The toggle lives in `SettingsView` and persists via `GameCenterPreference` (UserDefaults key `gameCenter.enabled`, default `false`). When enabled:

- `LeavesOfBlocksApp.task` calls `GameCenterService.shared.authenticateIfEnabled()` once on launch.
- After every game-over save, `GameService.saveGameRecord(...)` calls `submitFinalScore(...)` which posts to `GKLeaderboard` and reports achievements via `GKAchievement`.
- `SettingsView` and `SummaryView` show a "View Game Center / View Leaderboard" button bound to `presentDashboard()` when authenticated.

Identifiers are centralized in two places that **must** stay in sync:
- `LeavesOfBlocks/Services/Game/GameCenterService.swift` → `enum GameCenterIDs`
- `fastlane/GameCenterConfig.rb` → `LEADERBOARDS` and `ACHIEVEMENTS`

To add or modify a leaderboard or achievement: update both files, then run `bundle exec fastlane ios setup_game_center` to apply the new entries to App Store Connect (idempotent — existing vendor identifiers are skipped).

## Persistence

Core Data persists `GameRecord` entries via `CoreDataManager` (`viewContext` only). High scores are derived from the records, not stored separately. `HistoryView` reads via the manager and refreshes on context-change notifications.

## Testing Strategy

- New unit tests should use the **Swift Testing framework** with descriptive `@Test` names and Given-When-Then structure.
- `Logic/Game/GameLogic.swift` is pure and the easiest target for new coverage.
- UI tests should drive real flows; prefer `waitForExistence(timeout:)` over `sleep()`.

## Deployment

Production deployments run through Fastlane lanes defined in `fastlane/Fastfile`. Constants and helpers live in `fastlane/Constants.rb`.

### One-time setup

Required env vars (typically loaded from `fastlane/.env`, see `.env.template`):

- `LOCAL_APP_STORE_CONNECT_API_KEY_ID` — App Store Connect API key ID
- `LOCAL_APP_STORE_CONNECT_ISSUER_ID` — issuer ID for the API key
- `LOCAL_APP_STORE_CONNECT_API_KEY_PATH` — absolute path to the `.p8` private key
- The API key role must be **App Manager** or higher to manage Game Center entries.

Then:

```bash
bundle install                                      # install fastlane + ruby gems
bundle exec fastlane ios test_api_auth              # verify the API key works
bundle exec fastlane ios setup_game_center          # one-time: register Game Center leaderboards/achievements
```

`setup_game_center` is idempotent — re-running it after editing `fastlane/GameCenterConfig.rb` only POSTs new vendor identifiers; existing entries are skipped.

### Per-release flows

```bash
bundle exec fastlane ios beta                       # bump build, archive, upload to TestFlight
bundle exec fastlane ios deploy version:patch       # bump version+build, regenerate changelog/release notes, upload binary + metadata
bundle exec fastlane ios deploy_and_submit version:patch  # deploy + automatically submit for review
bundle exec fastlane ios submit                     # submit a previously uploaded build for review
bundle exec fastlane ios metadata_only              # update App Store listing (no binary)
bundle exec fastlane ios screenshots_only           # update screenshots only
```

`deploy` and `deploy_and_submit` require a `version:` arg (`patch` / `minor` / `major` / explicit `1.2.3`). They commit the changelog + project bump and tag `vX.Y.Z` automatically.

### Game Center capability

The entitlement (`com.apple.developer.game-center`) is committed at `LeavesOfBlocks/LeavesOfBlocks.entitlements` and wired into both Debug and Release build configs. Automatic code signing typically auto-enables the capability on the App ID at first device build; if it doesn't, run `bundle exec fastlane produce --enable_services game_center` once.

## Privacy

The app is built around an opt-in privacy posture:

- **No ads, no third-party tracking, no data sold.** No third-party SDKs, no analytics frameworks, no IDFA, no ATT prompt.
- **Game Center is opt-in (off by default).** When the user leaves it disabled, the app makes no network requests and all data lives in local Core Data + bundled assets — identical to the pre-integration build.
- **When opted in**, GameKit submits the final score and achievement progress to Apple's Game Center servers. No data flows to any third party.
- `LeavesOfBlocks/Resources/PrivacyInfo.xcprivacy` declares `User ID` and `Gameplay Content` as collected, linked, **not** used for tracking.
- About-screen and App Store metadata copy is the canonical privacy statement; keep `Localizable.xcstrings` (`technical_description`), `fastlane/Constants.rb` (`APP_DESCRIPTION`), and `fastlane/AIHelper.rb` (`APP_CONTEXT`) consistent when revising.

## Open-Source Notes

- LICENSE: MIT, © Tim Veil.
- Community files: `CONTRIBUTING.md`, `SECURITY.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `.github/ISSUE_TEMPLATE/`.
- Apple Developer Team ID `85U9MWUBJL` is hardcoded in `LeavesOfBlocks.xcodeproj/project.pbxproj`. External contributors building for device need to swap their own team ID. Simulator builds require no change.
