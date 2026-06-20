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

    // MARK: - Game Rules

    /// Core gameplay rule constants. Distinct from `GameTheme` (visual
    /// tuning) because rules belong with logic, not theming — `GameLogic`
    /// and `GridAnalysis` depend on this namespace rather than reaching
    /// into the theme.
    enum GameRules {
        /// Side length of the square play grid.
        static let gridSize: Int = 8

        /// Points awarded per cell of a placed block (before line clears).
        static let baseBlockScore: Int = 10

        /// Points awarded per cleared row or column.
        static let lineScore: Int = 100

        /// Bonus added per cleared line *beyond* the first in a single
        /// placement, on top of the per-line score.
        static let comboBonus: Int = 50
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
        ///
        /// Rebalanced alongside the qualityScore weight normalization (R2):
        /// the original boundaries (0.7 / 0.4 / 0.15) were calibrated for
        /// an effective range capped at 0.8. After normalizing the weights
        /// to sum to 1.0 the boundaries are scaled by 1.25 so each tier
        /// covers the same fraction of the achievable range as before.
        static let difficultyTierDiverseThreshold: Double = 0.875
        static let difficultyTierConstrainedThreshold: Double = 0.5
        static let difficultyTierMinimalThreshold: Double = 0.1875

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

        /// `true` when a UI test wants the game to start already in a game-over
        /// state (an unplaceable board) — used to exercise the game-over
        /// overlay without playing a full game. Only honored under
        /// `isUITesting`, and unreachable in shipped builds (end users can't
        /// pass launch arguments to an installed app).
        static let forceGameOver = ProcessInfo.processInfo.arguments.contains("-force-game-over")
    }
}
