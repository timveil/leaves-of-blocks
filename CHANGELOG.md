# Changelog

All notable changes to Leaves of Blocks will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

### Fixed

## [1.0.10] - 2025-11-27

### Added
- Add version information and developer links to the About screen for better transparency

### Changed
- Improve app store discoverability with enhanced Games category metadata

## [1.0.9] - 2025-11-27

### Fixed
- Include build number increment in release commit

## [1.0.8] - 2025-11-27

### Added
- Add automated changelog and conventional commit enforcement

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
- Autumn-themed visual design with seasonal colors
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

[Unreleased]: https://github.com/timveil/leaves-of-blocks/compare/v1.0.10...HEAD
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