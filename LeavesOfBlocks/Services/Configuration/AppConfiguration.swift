import Foundation

// MARK: - Application Configuration

/// Build/runtime tuning knobs that aren't user preferences.
///
/// Kept compile-time only — no dependencies on `UserDefaults`, no remote config.
enum AppConfiguration {

    // MARK: - Feature Flags

    enum FeatureFlags {
        /// True in DEBUG builds. Used to gate verbose logging and debug helpers.
        static let enableDebugMode = BuildConfiguration.isDebugBuild
    }

    // MARK: - Performance Settings

    enum Performance {
        static let animationFrameRate = 60.0
        static var dragUpdateThrottleInterval: TimeInterval { 1.0 / animationFrameRate }
    }

    // MARK: - Gameplay Tuning

    /// Constants the gameplay layer used to inline. Centralizing here so the
    /// numbers can be tuned without editing logic.
    enum Gameplay {
        /// `GridAnalysis.DifficultyTier.fromQualityScore` boundary scores.
        /// Quality scores at or above `diverseThreshold` map to `.diverse`,
        /// `constrainedThreshold..<diverseThreshold` map to `.constrained`,
        /// `minimalThreshold..<constrainedThreshold` map to `.minimal`, and
        /// anything below maps to `.emergency`.
        static let difficultyTierDiverseThreshold: Double = 0.7
        static let difficultyTierConstrainedThreshold: Double = 0.4
        static let difficultyTierMinimalThreshold: Double = 0.15

        /// Backtracking call budget used by `GameLogic.canAllBlocksBePlaced`.
        /// At 1000 calls, an 8x8 grid with three reasonably-sized blocks
        /// typically resolves within a few milliseconds; beyond this we
        /// treat the search as unsolvable and force the next round of
        /// generation to back off to a simpler set.
        static let placementBacktrackLimit: Int = 1_000
    }

    // MARK: - Runtime Flags

    /// Process-info-driven flags. Each is evaluated once at app launch.
    enum Runtime {
        /// `true` when the app was launched by an XCUI test runner.
        static let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")

        /// `true` when the app should display screenshot-friendly fixture data.
        static let isScreenshotMode = ProcessInfo.processInfo.arguments.contains("-screenshot-mode")
    }
}
