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
    struct SessionMetrics {
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
        let tierUsageDistribution: [String: Int]   // How often each difficulty tier was used
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
    @ObservationIgnored private var tierUsageCount: [String: Int] = [:]
    @ObservationIgnored private var fallbackCount: Int = 0
    @ObservationIgnored private var totalMeasurements: Int = 0
    @ObservationIgnored private var highTierMeasurements: Int = 0

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
        let averageEfficiency = gridEfficiencyHistory.isEmpty ? 0.0 : gridEfficiencyHistory.reduce(0, +) / Double(gridEfficiencyHistory.count)
        let averageFragmentation = fragmentationHistory.isEmpty ? 0.0 : fragmentationHistory.reduce(0, +) / Double(fragmentationHistory.count)
        let averageStrategic = strategicOpportunities.isEmpty ? 0.0 : strategicOpportunities.reduce(0, +) / Double(strategicOpportunities.count)
        let challengeMaintained = totalMeasurements > 0 ? Double(highTierMeasurements) / Double(totalMeasurements) : 0.0
        
        return SessionMetrics(
            score: score,
            blocksPlaced: blocksPlaced,
            linesCleared: linesCleared,
            longestCombo: longestCombo,
            gameTime: gameTime,
            difficulty: difficulty,
            averageGridEfficiency: averageEfficiency,
            averageFragmentation: averageFragmentation,
            strategicPlayRating: averageStrategic,
            tierUsageDistribution: tierUsageCount,
            fallbackActivations: fallbackCount,
            challengeMaintained: challengeMaintained
        )
    }
    
    // MARK: - Session Management
    
    /// Starts a new tracking session
    func startSession() {
        gridEfficiencyHistory.removeAll()
        fragmentationHistory.removeAll()
        strategicOpportunities.removeAll()
        tierUsageCount.removeAll()
        fallbackCount = 0
        totalMeasurements = 0
        highTierMeasurements = 0
        currentSessionMetrics = nil
        
        BuildConfiguration.log("Player behavior tracking session started", level: .debug)
    }
    
    /// Records grid state metrics during gameplay
    func recordGridState(_ grid: [[GridCell]]) {
        let metrics = GridAnalysis.analyzeGrid(grid)
        let tier = GridAnalysis.determineDifficultyTier(for: grid)
        
        // Record efficiency metrics, dropping the oldest entries past the cap.
        appendBounded(&gridEfficiencyHistory, metrics.efficiency)
        appendBounded(&fragmentationHistory, metrics.fragmentation)
        appendBounded(&strategicOpportunities, metrics.strategicPotential)
        
        // Track tier usage
        let tierName = tier.description
        tierUsageCount[tierName, default: 0] += 1
        
        // Track challenge level
        totalMeasurements += 1
        if tier == .diverse || tier == .constrained {
            highTierMeasurements += 1
        }
        
        BuildConfiguration.log("Recorded grid state - Efficiency: \(String(format: "%.3f", metrics.efficiency)), Tier: \(tierName)", level: .verbose)
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
        let averageEfficiency = gridEfficiencyHistory.isEmpty ? 0.0 : gridEfficiencyHistory.reduce(0, +) / Double(gridEfficiencyHistory.count)
        let averageFragmentation = fragmentationHistory.isEmpty ? 0.0 : fragmentationHistory.reduce(0, +) / Double(fragmentationHistory.count)
        let averageStrategic = strategicOpportunities.isEmpty ? 0.0 : strategicOpportunities.reduce(0, +) / Double(strategicOpportunities.count)
        let challengeMaintained = totalMeasurements > 0 ? Double(highTierMeasurements) / Double(totalMeasurements) : 0.0
        
        let sessionMetrics = SessionMetrics(
            score: score,
            blocksPlaced: blocksPlaced,
            linesCleared: linesCleared,
            longestCombo: longestCombo,
            gameTime: gameTime,
            difficulty: difficulty,
            averageGridEfficiency: averageEfficiency,
            averageFragmentation: averageFragmentation,
            strategicPlayRating: averageStrategic,
            tierUsageDistribution: tierUsageCount,
            fallbackActivations: fallbackCount,
            challengeMaintained: challengeMaintained
        )
        
        currentSessionMetrics = sessionMetrics
        
        BuildConfiguration.log("Session finalized - Efficiency: \(String(format: "%.3f", averageEfficiency)), Strategic: \(String(format: "%.3f", averageStrategic)), Grade: \(sessionMetrics.efficiencyGrade)", level: .info)
        
        return sessionMetrics
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
