import Foundation

// MARK: - Player Behavior Tracking System

/// Tracks player behavior and efficiency metrics throughout the game session.
///
/// - Note: Always accessed from the main actor (constructed by `GameState`,
///   read by SwiftUI views). The class itself is not annotated `@MainActor`
///   because static helpers in `BlockGenerator` invoke it from
///   non-isolated contexts that are themselves serialized through
///   `GameState`'s `@MainActor` boundary.
@Observable
final class PlayerBehaviorTracker {
    
    // MARK: - Session Metrics
    
    /// Comprehensive session statistics including efficiency metrics
    struct SessionMetrics: Equatable {
        // Existing metrics
        let score: Int
        let blocksPlaced: Int
        let linesCleared: Int
        let longestCombo: Int
        let gameTime: TimeInterval
        let difficulty: DifficultyMode
        
        // New efficiency metrics
        let averageGridEfficiency: Double          // Average grid efficiency throughout game
        let averageFragmentation: Double           // Average grid fragmentation
        let strategicPlayRating: Double            // How well player set up line clears
        let fallbackActivations: Int               // Number of times fallback system activated
        let challengeMaintained: Double            // Percentage of game spent in higher tiers
        
        // Derived metrics
        //
        // These return stable lowercase keys ("grade_a_plus", "grade_master")
        // that are persisted to Core Data. Display sites should pass them
        // through `.localizedGrade` to render. Older records may still
        // contain English values ("A+", "Master") — `localizedGrade` handles
        // both formats.
        var efficiencyGrade: String {
            switch averageGridEfficiency {
            case 0.8...1.0: return "grade_a_plus"
            case 0.7..<0.8: return "grade_a"
            case 0.6..<0.7: return "grade_b_plus"
            case 0.5..<0.6: return "grade_b"
            case 0.4..<0.5: return "grade_c_plus"
            case 0.3..<0.4: return "grade_c"
            default: return "grade_d"
            }
        }

        var strategicGrade: String {
            switch strategicPlayRating {
            case 0.8...1.0: return "grade_master"
            case 0.6..<0.8: return "grade_expert"
            case 0.4..<0.6: return "grade_skilled"
            case 0.2..<0.4: return "grade_learning"
            default: return "grade_beginner"
            }
        }

        var challengeLevel: String {
            switch challengeMaintained {
            case 0.7...1.0: return "challenge_high"
            case 0.4..<0.7: return "challenge_medium"
            default: return "challenge_low"
            }
        }
    }
    
    // MARK: - Tracking Properties

    private(set) var currentSessionMetrics: SessionMetrics?

    @ObservationIgnored private var gridEfficiencyHistory: [Double] = []
    @ObservationIgnored private var fragmentationHistory: [Double] = []
    @ObservationIgnored private var strategicOpportunities: [Double] = []
    @ObservationIgnored private var fallbackCount: Int = 0
    /// In-game "challenge measurement" count — the denominator of
    /// `challengeMaintained`. `private(set)` (rather than `private`) so
    /// tests can observe the counter without exporting a side-door API; the
    /// setter remains internal-only.
    @ObservationIgnored private(set) var totalMeasurements: Int = 0
    @ObservationIgnored private(set) var highTierMeasurements: Int = 0

    /// Cap on per-session metric history. Prevents unbounded memory growth in
    /// very long sessions; older measurements are dropped from the front.
    @ObservationIgnored private static let maxHistoryLength = 200
    
    // MARK: - Current Metrics Access
    
    /// Get current efficiency metrics without finalizing the session
    func getCurrentMetrics(
        score: Int,
        blocksPlaced: Int,
        linesCleared: Int,
        longestCombo: Int,
        gameTime: TimeInterval,
        difficulty: DifficultyMode
    ) -> SessionMetrics {
        let averages = currentAverages()

        return SessionMetrics(
            score: score,
            blocksPlaced: blocksPlaced,
            linesCleared: linesCleared,
            longestCombo: longestCombo,
            gameTime: gameTime,
            difficulty: difficulty,
            averageGridEfficiency: averages.efficiency,
            averageFragmentation: averages.fragmentation,
            strategicPlayRating: averages.strategic,
            fallbackActivations: fallbackCount,
            challengeMaintained: averages.challengeMaintained
        )
    }

    /// Snapshot of the four session aggregates, computed identically from
    /// `getCurrentMetrics` (in-flight read) and `finalizeSession` (terminal
    /// read). Kept private so both paths can't drift.
    private struct SessionAverages {
        let efficiency: Double
        let fragmentation: Double
        let strategic: Double
        let challengeMaintained: Double
    }

    private func currentAverages() -> SessionAverages {
        SessionAverages(
            efficiency: mean(gridEfficiencyHistory),
            fragmentation: mean(fragmentationHistory),
            strategic: mean(strategicOpportunities),
            challengeMaintained: totalMeasurements > 0
                ? Double(highTierMeasurements) / Double(totalMeasurements)
                : 0
        )
    }

    private func mean(_ values: [Double]) -> Double {
        values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
    }
    
    // MARK: - Session Management
    
    /// Starts a new tracking session
    func startSession() {
        gridEfficiencyHistory.removeAll()
        fragmentationHistory.removeAll()
        strategicOpportunities.removeAll()
        fallbackCount = 0
        totalMeasurements = 0
        highTierMeasurements = 0
        currentSessionMetrics = nil

        BuildConfiguration.log("Player behavior tracking session started", level: .debug)
    }

    /// Records grid state metrics during gameplay.
    ///
    /// - Parameters:
    ///   - grid: The grid to analyze.
    ///   - isInitialSeed: Pass `true` for the one-time seed at session start
    ///     (used by `GameState.resetGame()` and `GameState.apply(snapshot:)`).
    ///     Initial seeds populate the rolling efficiency/fragmentation/strategic
    ///     histories so they aren't empty for early reads, but they don't
    ///     count toward `challengeMaintained` — that metric reflects in-game
    ///     play, not the starting grid the player was dealt.
    func recordGridState(_ grid: [[GridCell]], isInitialSeed: Bool = false) {
        let metrics = GridAnalysis.analyzeGrid(grid)
        let tier = GridAnalysis.determineDifficultyTier(for: grid)

        // Record efficiency metrics, dropping the oldest entries past the cap.
        appendBounded(&gridEfficiencyHistory, metrics.efficiency)
        appendBounded(&fragmentationHistory, metrics.fragmentation)
        appendBounded(&strategicOpportunities, metrics.strategicPotential)

        if !isInitialSeed {
            // Track challenge level — only in-game measurements count.
            totalMeasurements += 1
            if tier == .diverse || tier == .constrained {
                highTierMeasurements += 1
            }
        }

        BuildConfiguration.log("Recorded grid state - Efficiency: \(String(format: "%.3f", metrics.efficiency)), Tier: \(tier.description)\(isInitialSeed ? " (seed)" : "")", level: .verbose)
    }
    
    /// Appends `value` to `history`, dropping the oldest entry once the cap is exceeded.
    private func appendBounded(_ history: inout [Double], _ value: Double) {
        history.append(value)
        if history.count > Self.maxHistoryLength {
            history.removeFirst(history.count - Self.maxHistoryLength)
        }
    }

    /// Records when fallback system activates
    func recordFallbackActivation(from originalTier: GridAnalysis.DifficultyTier, to finalTier: GridAnalysis.DifficultyTier) {
        fallbackCount += 1
        BuildConfiguration.log("Fallback activation recorded: \(originalTier.description) -> \(finalTier.description)", level: .info)
    }
    
    /// Finalizes session and calculates comprehensive metrics
    func finalizeSession(
        score: Int,
        blocksPlaced: Int,
        linesCleared: Int,
        longestCombo: Int,
        gameTime: TimeInterval,
        difficulty: DifficultyMode
    ) -> SessionMetrics {
        let averages = currentAverages()

        let sessionMetrics = SessionMetrics(
            score: score,
            blocksPlaced: blocksPlaced,
            linesCleared: linesCleared,
            longestCombo: longestCombo,
            gameTime: gameTime,
            difficulty: difficulty,
            averageGridEfficiency: averages.efficiency,
            averageFragmentation: averages.fragmentation,
            strategicPlayRating: averages.strategic,
            fallbackActivations: fallbackCount,
            challengeMaintained: averages.challengeMaintained
        )

        currentSessionMetrics = sessionMetrics

        BuildConfiguration.log("Session finalized - Efficiency: \(String(format: "%.3f", averages.efficiency)), Strategic: \(String(format: "%.3f", averages.strategic)), Grade: \(sessionMetrics.efficiencyGrade)", level: .info)

        return sessionMetrics
    }

    // MARK: - State Snapshot

    /// Value-type snapshot of every accumulating tracker field. Captured before
    /// each placement so undo can rewind the tracker to a prior point without
    /// replaying recordings.
    struct State: Equatable {
        let gridEfficiencyHistory: [Double]
        let fragmentationHistory: [Double]
        let strategicOpportunities: [Double]
        let fallbackCount: Int
        let totalMeasurements: Int
        let highTierMeasurements: Int
        let currentSessionMetrics: SessionMetrics?
    }

    /// Snapshots the tracker's accumulated state. Pure read — does not mutate.
    func captureState() -> State {
        State(
            gridEfficiencyHistory: gridEfficiencyHistory,
            fragmentationHistory: fragmentationHistory,
            strategicOpportunities: strategicOpportunities,
            fallbackCount: fallbackCount,
            totalMeasurements: totalMeasurements,
            highTierMeasurements: highTierMeasurements,
            currentSessionMetrics: currentSessionMetrics
        )
    }

    /// Restores tracker state from a prior `captureState()`. Replaces every
    /// accumulating field; does not emit observation notifications for the
    /// `@ObservationIgnored` arrays (callers — typically `GameState.restore` —
    /// re-render via other observed properties).
    func restore(_ state: State) {
        gridEfficiencyHistory = state.gridEfficiencyHistory
        fragmentationHistory = state.fragmentationHistory
        strategicOpportunities = state.strategicOpportunities
        fallbackCount = state.fallbackCount
        totalMeasurements = state.totalMeasurements
        highTierMeasurements = state.highTierMeasurements
        currentSessionMetrics = state.currentSessionMetrics
    }
}

// MARK: - Extended GameSessionStatistics

extension GameSessionStatistics {
    /// Creates enhanced statistics with efficiency metrics
    static func withEfficiencyMetrics(
        from tracker: PlayerBehaviorTracker,
        score: Int,
        blocksPlaced: Int,
        linesCleared: Int,
        gameTime: TimeInterval,
        longestCombo: Int,
        currentCombo: Int,
        difficulty: DifficultyMode
    ) -> GameSessionStatistics {
        // Get current metrics without finalizing session
        let metrics = tracker.getCurrentMetrics(
            score: score,
            blocksPlaced: blocksPlaced,
            linesCleared: linesCleared,
            longestCombo: longestCombo,
            gameTime: gameTime,
            difficulty: difficulty
        )
        
        // Return statistics with efficiency metrics
        return GameSessionStatistics(
            score: score,
            blocksPlaced: blocksPlaced,
            linesCleared: linesCleared,
            gameTime: gameTime,
            longestCombo: longestCombo,
            currentCombo: currentCombo,
            difficulty: difficulty,
            efficiencyGrade: metrics.efficiencyGrade,
            strategicGrade: metrics.strategicGrade,
            fallbackActivations: metrics.fallbackActivations
        )
    }
}
