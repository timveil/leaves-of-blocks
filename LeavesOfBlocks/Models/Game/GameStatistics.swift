import Foundation

// MARK: - Game Session Statistics

/// Handles calculation of game statistics and metrics for a single game session
struct GameSessionStatistics {
    
    // MARK: - Raw Data Properties
    
    let score: Int
    let blocksPlaced: Int
    let linesCleared: Int
    let gameTime: TimeInterval
    let longestCombo: Int
    let currentCombo: Int
    let difficulty: DifficultyMode
    
    // MARK: - Initialization
    
    init(
        score: Int,
        blocksPlaced: Int,
        linesCleared: Int,
        gameTime: TimeInterval,
        longestCombo: Int,
        currentCombo: Int,
        difficulty: DifficultyMode
    ) {
        self.score = score
        self.blocksPlaced = blocksPlaced
        self.linesCleared = linesCleared
        self.gameTime = gameTime
        self.longestCombo = longestCombo
        self.currentCombo = currentCombo
        self.difficulty = difficulty
    }
    
    // MARK: - Computed Statistics
    
    /// Average score per block placed
    var averageBlockScore: Double {
        guard blocksPlaced > 0 else { return 0.0 }
        return Double(score) / Double(blocksPlaced)
    }
    
    /// Percentage of blocks that resulted in line clears
    var lineClearPercentage: Double {
        guard blocksPlaced > 0 else { return 0.0 }
        return (Double(linesCleared) / Double(blocksPlaced)) * 100
    }
    
    /// Score per minute played
    var scorePerMinute: Double {
        guard gameTime > 0 else { return 0.0 }
        let minutes = gameTime / 60.0
        return Double(score) / minutes
    }
    
    /// Lines cleared per minute
    var linesClearedPerMinute: Double {
        guard gameTime > 0 else { return 0.0 }
        let minutes = gameTime / 60.0
        return Double(linesCleared) / minutes
    }
    
    /// Blocks placed per minute
    var blocksPerMinute: Double {
        guard gameTime > 0 else { return 0.0 }
        let minutes = gameTime / 60.0
        return Double(blocksPlaced) / minutes
    }
    
    /// Efficiency rating based on score per time and lines cleared
    var efficiencyRating: Double {
        let scoreWeight = 0.6
        let lineWeight = 0.4
        
        let normalizedScore = min(scorePerMinute / 1000.0, 1.0) // Normalize to 0-1
        let normalizedLines = min(linesClearedPerMinute / 10.0, 1.0) // Normalize to 0-1
        
        return (normalizedScore * scoreWeight + normalizedLines * lineWeight) * 100
    }
    
    /// Performance grade based on various metrics
    var performanceGrade: String {
        let efficiency = efficiencyRating
        
        switch efficiency {
        case 90...100: return "S"
        case 80..<90: return "A"
        case 70..<80: return "B"
        case 60..<70: return "C"
        case 50..<60: return "D"
        default: return "F"
        }
    }
    
    /// Formatted game time string
    var formattedGameTime: String {
        let minutes = Int(gameTime) / 60
        let seconds = Int(gameTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Comparison Statistics
    
    /// Compares this game session to another
    func compare(to other: GameSessionStatistics) -> GameSessionComparison {
        return GameSessionComparison(current: self, previous: other)
    }
    
    // MARK: - Achievement Checks
    
    /// Checks if this session achieved any milestones
    var achievements: [GameAchievement] {
        var achievements: [GameAchievement] = []
        
        if longestCombo >= 5 {
            achievements.append(.comboMaster)
        }
        
        if lineClearPercentage >= 80 {
            achievements.append(.linemaster)
        }
        
        if efficiencyRating >= 90 {
            achievements.append(.perfectionist)
        }
        
        if gameTime >= 300 { // 5 minutes
            achievements.append(.endurance)
        }
        
        return achievements
    }
}

// MARK: - Supporting Types

/// Represents a comparison between two game sessions
struct GameSessionComparison {
    let current: GameSessionStatistics
    let previous: GameSessionStatistics
    
    var scoreImprovement: Int {
        return current.score - previous.score
    }
    
    var efficiencyImprovement: Double {
        return current.efficiencyRating - previous.efficiencyRating
    }
    
    var timeImprovement: TimeInterval {
        return current.gameTime - previous.gameTime
    }
}

/// Represents different achievements that can be earned
enum GameAchievement: String, CaseIterable {
    case comboMaster = "Combo Master"
    case linemaster = "Line Master"
    case perfectionist = "Perfectionist"
    case endurance = "Endurance"
    
    var description: String {
        switch self {
        case .comboMaster:
            return "Achieved a combo of 5 or more lines"
        case .linemaster:
            return "80% or more blocks resulted in line clears"
        case .perfectionist:
            return "Achieved 90% or higher efficiency rating"
        case .endurance:
            return "Played for 5 minutes or longer"
        }
    }
    
    var icon: String {
        switch self {
        case .comboMaster:
            return "flame"
        case .linemaster:
            return "target"
        case .perfectionist:
            return "star.fill"
        case .endurance:
            return "clock"
        }
    }
}