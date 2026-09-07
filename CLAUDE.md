# CLAUDE.md

Guidance for Claude Code (claude.ai/code) when working in this repository.

## Coding Standards

All code changes must follow `LeavesOfBlocks/Documentation/CodingStandards.md`. That document is the source of truth for Swift formatting, naming, file organization, DocC documentation, SwiftUI conventions, error handling, and testing standards.

Project-wide rules live in [`conventions/`](conventions/), one file per rule, indexed in [`conventions/README.md`](conventions/README.md). They cover engineering practice and cross-cutting rules; Swift *formatting and style* remain in `CodingStandards.md`. Read the relevant one before adding a workflow, a script, a new enforcement mechanism, or game-rule logic.

Of particular note: **write the failing test first** ([`tdd.md`](conventions/tdd.md)), **game rules live in `GameLogic` as pure functions and the SpriteKit scene never writes back** ([`game-logic-boundary.md`](conventions/game-logic-boundary.md)), **no GitHub Actions workflow inlines complex scripting** ([`workflow-scripts.md`](conventions/workflow-scripts.md)), **a rule enforced in two places is defined once** ([`shared-rule-single-source.md`](conventions/shared-rule-single-source.md)), and **every review comment is addressed and resolved before a PR merges** ([`review-comments.md`](conventions/review-comments.md)).

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

The locales the project ships are declared once in [`.locales`](.locales) — two columns, App Store locale (`en-US`) and in-app language (`en`), with `-` for "not shipped on that side". [`scripts/check-locales.sh`](scripts/check-locales.sh) holds `knownRegions`, the string catalog, `SCREENSHOT_LANGUAGES` and `fastlane/metadata/` to it, and fails any `"key".localized` lookup with no catalog entry behind it. Edit `.locales` first, then the registries. See [`conventions/localization.md`](conventions/localization.md).

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
- Deployment target: iOS 18.0+
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
- `dependabot-auto-merge.yml` enables auto-merge for minor and patch dependency updates
- Triggers on push to `main` and on PRs touching Swift / project / scripts
- Every job that runs `xcodebuild` selects its toolchain with `./scripts/xcode-version.sh --select`, which picks the newest installed Xcode meeting the floor in `.xcode-version` and exports `DEVELOPER_DIR`. Without it, jobs inherit whatever Xcode the runner image happens to default to, and that can change under you.

`.github/workflows/tooling.yml` covers the pipeline that builds the app rather than the app itself — the shell scripts and the fastlane configuration, neither of which had any coverage before. It runs [`scripts/run-script-tests.sh`](scripts/run-script-tests.sh) (every `scripts/test-*.sh`) and `bundle exec fastlane lanes`, needs no App Store Connect credentials, and finishes in about a minute. `fastlane lanes` is the cheap load check: it parses the Fastfile, Appfile and every required helper without running `before_all`.

CodeQL runs separately in `.github/workflows/codeql.yml` (Swift on macOS, Ruby and Actions on Ubuntu, plus a weekly cron):

- A `changes` job runs [`scripts/codeql-languages.sh`](scripts/codeql-languages.sh) over the PR diff and emits a matrix containing **only** the affected languages, so a fastlane-only change no longer pays for a full Swift `xcodebuild` (~20 min on macOS). Scheduled runs pass `--all` and analyze everything.
- That script is the single source of truth for the path→language mapping. When adding a file type, update it and run [`scripts/test-codeql-languages.sh`](scripts/test-codeql-languages.sh).
- Watch out for extensionless Ruby: `Fastfile`, `Deliverfile`, `Snapfile`, and `Appfile` match no `*.rb` glob and must be listed explicitly.

### Build Troubleshooting

- Simulator choice is constrained by which runtimes are installed, not by the deployment target. Older iPhone models are typically paired with older runtimes; use the iPhone 17 family on an iOS 26 runtime for builds and screenshots. `./scripts/simulator-runtime.sh --list` shows what is available.
- The **simulator runtime** for screenshots is derived, not pinned: [`scripts/simulator-runtime.sh`](scripts/simulator-runtime.sh) picks the newest installed runtime at or above the app's `IPHONEOS_DEPLOYMENT_TARGET`, read from the project file. If it fails, install a runtime via Xcode → Settings → Components. Note `simctl` reports two versions per runtime — the label (`iOS 26.4`) and the point version (`26.4.1`) — and xcodebuild's `-destination` matches the point version; `FastlaneCoreDevicePointVersionFix` in `Constants.rb` makes fastlane's device list agree. Device *names* (`IOS_SIMULATOR`, `SCREENSHOT_DEVICES`) stay pinned on purpose, since App Store screenshots are submitted at chosen display sizes.
- The Xcode requirement is a **minimum**, declared once in `.xcode-version` and enforced by [`scripts/xcode-version.sh`](scripts/xcode-version.sh). `bundle exec fastlane` runs `--check` in `before_all`; if it fails, either install a newer Xcode or point at one you have with `sudo xcode-select -s /Applications/Xcode.app`. Raise the floor only when the project genuinely needs a newer toolchain — it was previously an exact pin, and every Xcode auto-update broke every lane until someone edited the constant.
- Quickly isolate compile failures: `xcodebuild ... 2>&1 | grep -B 2 -A 5 "error:"`
- Successful builds end with `** BUILD SUCCEEDED **`.

### Version Management

Two numbers, two different owners:

- **`MARKETING_VERSION`** (`CFBundleShortVersionString`) is owned by the repo. `deploy` / `deploy_and_submit` bump it via `bump_marketing_version` (`fastlane/release_helpers.rb`) from the `version:` argument, write it across every build configuration of the `LeavesOfBlocks` target, and commit `project.pbxproj` as `chore: Release vX.Y.Z`.
- **`CURRENT_PROJECT_VERSION`** (`CFBundleVersion`) is owned by App Store Connect. `next_build_number` asks ASC for the most recent upload and returns that plus one; `app_store_build_app` hands it to xcodebuild as a setting override at archive time. It is **never** written to `project.pbxproj` — the value checked in there is stale by design and is not the build number any uploaded binary carries.

That split is deliberate. It means `beta` leaves a clean working tree (no bump to commit or reset before the next `deploy` passes its `ensure_git_status_clean` pre-flight), and a build number can never collide with one App Store Connect already has — regardless of what is in the repo, which machine archives, or whether a previous release run was undone.

`Bundle+Extensions.swift` reads both via `Bundle.main` for the About screen and logging. In a local Debug build the build number is whatever `project.pbxproj` still says; only archives carry the resolved value.

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

conventions/                      # Project-wide rules, one file per rule
scripts/                          # Build, CI and release logic, each with a test-*.sh
├── build.sh                      # Build/test entry point
├── check-commit-subject.sh       # Commit format — source of truth
├── check-pr-title.sh             # The subject a squash merge will produce
├── check-docs-versions.sh        # Docs vs. IPHONEOS_DEPLOYMENT_TARGET
├── check-locales.sh              # Locale registries vs. .locales
├── codeql-languages.sh           # Path -> CodeQL language mapping
├── lint-commit-range.sh          # Commit-range iteration for CI
├── simulator-runtime.sh          # Newest installed runtime >= deployment target
├── xcode-version.sh              # Xcode floor from .xcode-version
└── run-script-tests.sh           # Runs every test-*.sh; what CI calls
fastlane/
├── Fastfile, Constants.rb, release_helpers.rb, GameCenterConfig.rb
└── test/release_helpers_test.rb  # Ruby suite, run via scripts/test-release-helpers.sh
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
bundle exec fastlane ios preflight                  # read-only: can a release run right now?
bundle exec fastlane ios beta                       # bump build, archive, upload to TestFlight
bundle exec fastlane ios deploy                     # ship the version the project states; changelog, binary + metadata
bundle exec fastlane ios deploy_and_submit          # deploy + automatically submit for review
bundle exec fastlane ios deploy version:minor       # change train first, then ship
bundle exec fastlane ios submit                     # submit a previously uploaded build for review
bundle exec fastlane ios metadata_only              # update App Store listing (no binary)
bundle exec fastlane ios screenshots_only           # update screenshots only
```

`MARKETING_VERSION` states **the version under development**, so `deploy` ships what the project already says and `version:` is only needed to change train (`minor`, `major`, or an explicit `1.2.3`). Each lane commits the changelog, tags `vX.Y.Z`, attempts a GitHub Release from that version's CHANGELOG section, and then — after the tag — moves the project to the next patch and pushes `chore: Begin development on vX.Y.Z+1`.

That trailing bump is not cosmetic. App Store Connect refuses further builds under an approved version, so a project left on the just-shipped number makes `beta` unusable from approval until the next release. Moving on immediately means TestFlight builds go out as the next version, which is also what the next `deploy` will ship.

**Check before releasing.** `preflight` runs every read-only check the release path depends on — Xcode floor, clean tree, branch, simulator runtime, App Store Connect auth and next build number, target version, tag and version availability, CHANGELOG section, TestFlight notes, and `gh` — and reports them as a table. It writes nothing, anywhere.

It cannot cover signing, archiving, upload, submission, phased rollout, or the `gh` call itself; those first execute during a real run. The sequence that de-risks a release is **`preflight` → `beta` → `deploy`**: `beta` exercises signing, the archive, the App Store Connect build number and the TestFlight notes without touching the App Store listing.

**One version identifies the whole release.** The target version is resolved once at the start of `_release_core` and passed everywhere — `MARKETING_VERSION`, the App Store submission, the git tag, and the GitHub Release all carry the same string, and `bump_marketing_version` reads the project back to prove the write took before anything is archived. The build number is resolved once from App Store Connect and recorded in the release body, so `2.0.7 (28)` on the GitHub Release is the binary in App Store Connect.

Publishing the GitHub Release soft-fails: it runs after `deliver` has succeeded and the tag is already public, so a missing `gh` or an API error logs a warning with a one-line manual fix rather than failing a lane whose binary has already shipped.

### Phased release

`fastlane/Deliverfile` sets `phased_release(true)` and `automatic_release(true)`, so an approved version releases itself and then rolls out gradually:

1. On approval the version goes live without waiting for a manual push.
2. Apple rolls it out to auto-updating users over 7 days — roughly 1% / 2% / 5% / 10% / 20% / 50% / 100%. Users who manually check for updates get it immediately regardless.

The safety net is the rollout, not a human remembering to press a button: the update reaches ~1% on day one, and pausing is available throughout.

This is the only production rollout safety net: the app ships no third-party SDKs, so crash data comes solely from Xcode Organizer, which lags by hours.

**If a regression shows up mid-rollout**, in App Store Connect → the version → *Phased Release for Automatic Updates*:

- **Pause** — halts the rollout at its current percentage. Use this first; it is instant and reversible, and buys time to confirm whether Organizer's crash spike is real.
- **Resume** — continues from where it paused.
- **Release to All Users** — skips the remaining phases and goes to 100%. Only for a rollout you're confident in.

Pausing does **not** remove the update from users who already have it. To actually stop the bleeding you still need to ship a fixed build (`deploy`) and, if the regression is severe, request an expedited review.

### Submitting

`submit` sends the version App Store Connect is holding, not the one in the project file — after a release the project has already moved on, so those differ. It resolves the pending version from App Store Connect, waits for a build of that version to finish processing, and attaches it, which is what previously required choosing a build from a dropdown.

Age rating answers live in [`fastlane/metadata/app_rating_config.json`](fastlane/metadata/app_rating_config.json) and are applied by `deliver` through `app_rating_config_path`. That includes the social-media questions App Store Connect added for September 2026 (`socialMedia`, `socialMediaAgeRestricted`, `messagingAndChat`, `userGeneratedContent`). Keeping them in the repository means a submission cannot go out with stale answers, and a change to them is reviewable. **They are declarations to Apple about the app's behavior — change them deliberately, not to make a check pass.**

`preflight` covers both: that the config exists and answers the social-media questions, and which version and build are ready to submit.

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
