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

        // MARK: Board Pressure (#177)
        //
        // `BlockGenerator` no longer caps block size by grid-quality tier —
        // see `Logic/Game/BoardPressure.swift`. It samples several candidate
        // sets from the same unconstrained distribution, scores each by how
        // much it actually helps the player, and picks from that ranking at
        // the quantile `BoardPressure.calculate` names. These constants tune
        // that pipeline; see `LeavesOfBlocksTests/GameSimulation.swift`'s
        // calibration report for how they're validated against a
        // session-length target.

        /// Candidate sets sampled per deal before falling back to the
        /// constrained search. Generation time is logged by
        /// `BlockGenerator` (`[SOLVABILITY]`); reduce this if it exceeds a
        /// frame budget on device-class hardware.
        static let pressureCandidateCount: Int = 10

        /// Candidate sets sampled in the constrained fallback, once no
        /// unconstrained candidate is solvable.
        static let pressureFallbackCandidateCount: Int = 10

        /// `BoardPressure`'s four input weights. Sum to 1.0, mirroring
        /// `GridStateMetrics.qualityScore`'s style, so the weighted sum
        /// before the difficulty ceiling is applied stays in `0...1`.
        ///
        /// The progress ramp dominates on purpose. A skilled player keeps
        /// the board itself clean — low density, low fragmentation, few dead
        /// cells — for the whole game, which is exactly what those three
        /// terms are supposed to reward. But it means board state alone
        /// never meaningfully pressures good play: the calibration report
        /// (`GameSimulationTests.swift`) showed the greedy bot (stand-in for
        /// a typical attentive player) still alive at the 30-minute cap in
        /// essentially every game when the ramp was weighted at 0.15 — the
        /// only thing that can eventually catch up with a consistently
        /// well-played board is time itself.
        static let pressureWeightDensity: Double = 0.12
        static let pressureWeightFragmentation: Double = 0.15
        static let pressureWeightDeadCells: Double = 0.13
        static let pressureWeightProgressRamp: Double = 0.60

        /// Blocks placed until the progress ramp reaches its maximum, per
        /// difficulty. Lower means pressure climbs with progress faster,
        /// independent of how the board looks. Set well under each mode's
        /// ~30-minute-equivalent placement count (at the assumed 5s/placement,
        /// 360) so pressure is still rising, not flat, through most of a
        /// typical session rather than maxing out early.
        static let pressureRampBlocksEasy: Int = 260
        static let pressureRampBlocksModerate: Int = 170
        static let pressureRampBlocksHard: Int = 90

        /// The most pressure a difficulty mode can ever apply, regardless of
        /// how bad the board gets. Easy always keeps some slack; Hard can
        /// reach the full 1.0.
        static let pressureCeilingEasy: Double = 0.7
        static let pressureCeilingModerate: Double = 0.85
        static let pressureCeilingHard: Double = 1.0

        /// Helpfulness-score penalty per ≤2-cell block in a candidate set —
        /// so a set of three singles ranks near the bottom even though each
        /// individually "fits fine" — and the bonus applied when some block
        /// in the set can complete a line immediately.
        static let helpfulnessSmallBlockPenalty: Double = 6.0
        static let helpfulnessLineClearBonus: Double = 8.0

        /// Empty-cell count at/below which the constrained fallback's "at
        /// most one ≤2-cell block per set" rule is lifted — below this,
        /// small blocks are often the only shapes that fit anywhere.
        static let fallbackTightBoardThreshold: Int = 10
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
