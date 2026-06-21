# Changelog

All notable changes to Leaves of Blocks will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

### Fixed

## [2.0.6] - 2026-06-20

### Added
- Per-game Undo and Hint assists, reachable mid-game and from the game-over overlay
- View Board peek on the game-over overlay to review your final grid

### Changed
- Stop the `metadata_only` lane from re-uploading screenshots (prevents duplicate App Store screenshots)
- Drop the python3 dependency from `build.sh` simulator discovery

### Fixed
- Taper drag lift near the top of the board so top-row cells are placeable
- Eagerly initialize the SpriteKit scene bridge so the grid mounts on first render
- Tighten assist-bar spacing in the board's top cluster
- Resolve Swift 6 actor-isolation and unused-`try?` build warnings

## [2.0.5] - 2026-05-17

### Added
- SpriteKit scene now suspends and resumes on app background/foreground
- `fastlane/AchievementPrompts.md` — Recraft prompt set for generating Game Center achievement icons
- Release lanes fail fast via `ensure_version_available_on_app_store!` when the target version already exists in App Store Connect
- Add background audio mixing so your music keeps playing while you enjoy the game
- Add automatic retry for Game Center score and achievement submissions so your progress is always recorded

### Changed
- Refreshed README: link to public website, vs. Block Blast comparison, and updated project structure
- Refreshed and corrected `CHANGELOG.md`
- Extracted Fastlane release helpers and hardened the release flow
- Removed `bump_marketing_version` from the beta lane (TestFlight builds no longer touch the marketing version)
- Improve Game Center integration for more reliable leaderboard and achievement updates

### Fixed
- Fix an issue where dragging blocks near the edge of the board could cause unexpected behavior
- Fix a bug where removing a placed block could affect the wrong piece on the board
- Fix decorative icons so VoiceOver focuses only on meaningful content, improving accessibility
- Fix an issue where game history stats could be calculated incorrectly in certain sessions
- Fix a rare puzzle generation edge case to ensure the board always has a valid solution

### Removed
- Falling-leaves SpriteKit effect
- `scripts/generate_grass_images.py` (orphaned since the texture-based grass background was retired in 2.0.1)

## [2.0.3] - 2026-05-03

### Changed
- Re-publish of 2.0.2 with a marketing version bump (no functional changes)

## [2.0.2] - 2026-05-03

### Added
- Line-clear drag preview and combo banner refinements
- `PressDarken` button style applied across primary buttons
- UI haptics on additional interactions
- Single 1024-pt App Icon with dark and tinted variants

### Changed
- Combo banner moved from SwiftUI to SpriteKit for smoother animation
- Fastlane changelog generation relaxed; release flow fails fast if the target tag already exists

### Fixed
- Timezone-dependent date constants in `ExtendedStatisticsTests`

## [2.0.1] - 2026-05-02

### Added
- Optional, opt-in Game Center integration: leaderboards, achievements, and dashboard presentation gated behind `GameCenterPreference`
- In-progress game persistence with resume UI (`ContinueGameCard`)
- Statistics screen and menu entry, with extended statistics components (`CompactStatCard`, etc.)
- SpriteKit game grid renderer (Phase 1), visual effects and drag ghost (Phase 2), ambient leaves, game-over sweep, and high-score celebration (Phase 3)
- Slide-down menu, top bar, and acorn asset (later replaced by a toolbar `Menu`)
- `GoldHeaderCard`, `CompactGoldHeaderCard`, `contentCard` modifier, and `headerBand` color tokens — unified folk-art card styling
- `WhitmanSticker` component and Whitman portrait theming
- SwiftUI previews for UI components
- Accessibility labels and localized strings across screens
- Subtitle and compact stat tiles on the home screen
- Top spacer and points caption to the game header

### Changed
- Refreshed visual theme with a paper/ink palette and Whitman portrait
- Replaced grass/ground textures with a full tree background image
- Redesigned About screen and `QuoteView`
- Revamped HowToPlay and Settings UI and localizations
- Refactored History UI and added Past Games localizations
- Replaced save/exit buttons with circular icons
- Switched from slide-down overlay to a toolbar `Menu`
- Modernized launch screen (removed old square LaunchIcon, aligned Home/Board to the top)
- Adjusted theme accent and button text colors
- Bolder grid lines, content-node layout, and removed shadows
- `GameTheme` colors applied to SpriteKit effects
- Layout corner radii and history row UI updates
- Combo notification UI revamp and faster animations
- Allowed preview highlights to override filled cells
- Reduced drag offset above the finger
- Injected `GameState` and cleaned up `GameScene`
- Switched async sleeps to Swift `Task` and added a geometry helper
- Open-source readiness pass: documentation, dead code removal, DRY, accessibility
- P2 polish: code coverage, accessibility, `os.Logger`, expanded tests
- P2 round 2: Core Data `perform`, layering, more tests
- Manual App Store signing; `.env.template` for Fastlane; export options
- Snapshot device mappings extended for newer iPhones
- Fastlane config, simulator selection, and tooling updates
- App icons and `logo.svg` refresh
- Block colors and dim overlay tuning
- Tree assets, UI colors, and demo score tweaks

### Fixed
- Block accessibility identifiers cascading from container
- Swift 6 isolation warnings in `ScreenshotFixtures`
- `testNavigationFlow` on iOS 26 toolbar `Menu`
- Environment-aware simulator detection in the build script
- Missing localizations and Game Center config sanitization

### Removed
- Legacy SwiftUI grid views and the SpriteKit feature flag
- Unused extensions and dev utilities
- GitHub Pages `docs/` folder and `CNAME` (moved to standalone marketing site)
- Empty string entry from `Localizable.xcstrings`

## [1.0.10] - 2025-11-27

### Added
- Version information and developer links on the About screen for better transparency

### Changed
- Improved App Store discoverability with enhanced Games category metadata

## [1.0.9] - 2025-11-27

### Fixed
- Include build number increment in release commit

## [1.0.8] - 2025-11-27

### Added
- Automated changelog and conventional commit enforcement

## [1.0.7] - 2025-11-27

### Added
- Spanish localization support
- Simulator run script for Xcode-free development

### Changed
- Improved iPhone simulator selection in build scripts

## [1.0.6] - 2025-11-20

### Added
- Unified build script for local and CI environments
- Dependabot auto-merge workflow

### Changed
- Updated to Xcode 26.1
- Improved iOS simulator selection for CI/CD
- Refined simulator selection in build workflow

## [1.0.5] - 2025-10-15

### Added
- Ruby version file for consistent development environment
- Interactive development menu system
- Project cleanup utility script

### Changed
- Refactored async delays to use Swift concurrency
- Updated CI to use Xcode 16.4 and iOS 18.5 runtime
- Refactored Fastlane API key configuration

### Removed
- App Clip support and related assets
- Fastlane guide documentation

## [1.0.4] - 2025-09-01

### Added
- Reusable QuoteView component
- Icon generation and copy workflow automation
- Clean lane to Fastlane

### Changed
- Improved README with enhanced visuals
- Adjusted block generation parameters for difficulty tiers
- Updated app review contact information

### Fixed
- Screenshot upload handling in Deliverfile

## [1.0.3] - 2025-08-02

### Added
- Enhanced TestFlight deployment with automated version management
- Improved Fastlane configuration for reliable App Store submissions

### Changed
- Updated version management system to properly handle App Store Connect requirements
- Streamlined beta deployment process with better error handling

### Fixed
- Resolved TestFlight upload failures due to closed release trains
- Fixed version increment issues in build pipeline

## [1.0.2] - 2025-07-30

### Added
- Comprehensive game statistics and achievements system
- Advanced session analytics with performance metrics
- Service-oriented architecture with GameLogic and GameService separation
- DocC documentation for all public APIs

### Changed
- Refactored GameState from 361 lines to ~80 lines through service extraction
- Consolidated UI components with unified styling system
- Improved code organization with 13+ reusable view modifiers

### Fixed
- Enhanced game logic validation and error handling
- Improved block placement accuracy and visual feedback

## [1.0.1] - 2025-07-15

### Added
- Initial visual design with custom color palette
- Haptic feedback for enhanced gameplay experience
- High score persistence with Core Data integration

### Changed
- Improved block generation algorithm with difficulty-based weighting
- Enhanced scoring system with combo bonuses for multiple line clears

### Fixed
- Game over detection accuracy improvements
- Block placement validation edge cases

## [1.0.0] - 2025-07-01

### Added
- Initial release of Leaves of Blocks puzzle game
- 8x8 grid gameplay with drag-and-drop block placement
- 21 unique block shapes with progressive difficulty
- Three difficulty modes: Easy, Moderate, Hard
- Score tracking with line clearing bonuses
- SwiftUI-based user interface with modern iOS design
- App Clip support for quick gameplay access
- Privacy-focused design with local-only data storage
- COPPA compliant with no data collection
- iPhone-optimized experience with portrait orientation

[Unreleased]: https://github.com/timveil/leaves-of-blocks/compare/v2.0.6...HEAD
[2.0.6]: https://github.com/timveil/leaves-of-blocks/compare/v2.0.5...v2.0.6
[2.0.5]: https://github.com/timveil/leaves-of-blocks/compare/v2.0.3...v2.0.5
[2.0.3]: https://github.com/timveil/leaves-of-blocks/compare/v2.0.2...v2.0.3
[2.0.2]: https://github.com/timveil/leaves-of-blocks/compare/v2.0.1...v2.0.2
[2.0.1]: https://github.com/timveil/leaves-of-blocks/compare/v1.0.10...v2.0.1
[1.0.10]: https://github.com/timveil/leaves-of-blocks/compare/v1.0.9...v1.0.10
[1.0.9]: https://github.com/timveil/leaves-of-blocks/compare/v1.0.8...v1.0.9
[1.0.8]: https://github.com/timveil/leaves-of-blocks/compare/v1.0.7...v1.0.8
[1.0.7]: https://github.com/timveil/leaves-of-blocks/compare/v1.0.6...v1.0.7
[1.0.6]: https://github.com/timveil/leaves-of-blocks/compare/v1.0.5...v1.0.6
[1.0.5]: https://github.com/timveil/leaves-of-blocks/compare/v1.0.4...v1.0.5
[1.0.4]: https://github.com/timveil/leaves-of-blocks/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/timveil/leaves-of-blocks/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/timveil/leaves-of-blocks/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/timveil/leaves-of-blocks/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/timveil/leaves-of-blocks/releases/tag/v1.0.0
