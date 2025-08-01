import Foundation

// MARK: - Player Behavior Tracking System

/// Tracks player behavior and efficiency metrics throughout the game session
class PlayerBehaviorTracker: ObservableObject {
    
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
        var efficiencyGrade: String {
            switch averageGridEfficiency {
            case 0.8...1.0: return "A+"
            case 0.7..<0.8: return "A"
            case 0.6..<0.7: return "B+"
            case 0.5..<0.6: return "B"
            case 0.4..<0.5: return "C+"
            case 0.3..<0.4: return "C"
            default: return "D"
            }
        }
        
        var strategicGrade: String {
            switch strategicPlayRating {
            case 0.8...1.0: return "Master"
            case 0.6..<0.8: return "Expert"
            case 0.4..<0.6: return "Skilled"
            case 0.2..<0.4: return "Learning"
            default: return "Beginner"
            }
        }
        
        var challengeLevel: String {
            switch challengeMaintained {
            case 0.7...1.0: return "High"
            case 0.4..<0.7: return "Medium"
            default: return "Low"
            }
        }
    }
    
    // MARK: - Tracking Properties
    
    @Published private(set) var currentSessionMetrics: SessionMetrics?
    
    private var gridEfficiencyHistory: [Double] = []
    private var fragmentationHistory: [Double] = []
    private var strategicOpportunities: [Double] = []
    private var tierUsageCount: [String: Int] = [:]
    private var fallbackCount: Int = 0
    private var totalMeasurements: Int = 0
    private var highTierMeasurements: Int = 0
    
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
        
        // Record efficiency metrics
        gridEfficiencyHistory.append(metrics.efficiency)
        fragmentationHistory.append(metrics.fragmentation)
        strategicOpportunities.append(metrics.strategicPotential)
        
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
    
    // MARK: - Analytics Helpers
    
    /// Gets current session efficiency if available
    var currentEfficiency: Double? {
        return gridEfficiencyHistory.last
    }
    
    /// Gets current strategic rating if available  
    var currentStrategicRating: Double? {
        return strategicOpportunities.last
    }
    
    /// Gets efficiency trend (improving/declining)
    var efficiencyTrend: String {
        guard gridEfficiencyHistory.count >= 5 else { return "Insufficient Data" }
        
        let recent = Array(gridEfficiencyHistory.suffix(5))
        let older = Array(gridEfficiencyHistory.dropLast(5).suffix(5))
        
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let olderAvg = older.isEmpty ? recentAvg : older.reduce(0, +) / Double(older.count)
        
        let improvement = recentAvg - olderAvg
        
        switch improvement {
        case 0.1...: return "Improving"
        case -0.1..<0.1: return "Stable"
        default: return "Declining"
        }
    }
    
    /// Gets performance summary for current session
    var performanceSummary: String {
        guard let metrics = currentSessionMetrics else { return "No session data" }
        
        return "Efficiency: \(metrics.efficiencyGrade) | Strategic: \(metrics.strategicGrade) | Challenge: \(metrics.challengeLevel)"
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
        // Get standard statistics
        let baseStats = GameSessionStatistics(
            score: score,
            blocksPlaced: blocksPlaced,
            linesCleared: linesCleared,
            gameTime: gameTime,
            longestCombo: longestCombo,
            currentCombo: currentCombo,
            difficulty: difficulty
        )
        
        // Finalize tracking session
        let sessionMetrics = tracker.finalizeSession(
            score: score,
            blocksPlaced: blocksPlaced,
            linesCleared: linesCleared,
            longestCombo: longestCombo,
            gameTime: gameTime,
            difficulty: difficulty
        )
        
        // Enhanced statistics would be returned here
        // For now, return base statistics until we extend the model
        return baseStats
    }
}