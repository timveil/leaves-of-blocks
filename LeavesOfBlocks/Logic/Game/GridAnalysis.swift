import Foundation

// MARK: - Grid Analysis System

/// Analyzes grid state to determine player skill level and decision quality
/// Used for intelligent difficulty balancing that rewards good play
struct GridAnalysis {
    
    // MARK: - Grid State Metrics
    
    /// Comprehensive analysis of current grid state
    struct GridStateMetrics {
        let efficiency: Double          // 0.0 to 1.0, higher = better space utilization
        let fragmentation: Double       // 0.0 to 1.0, higher = more scattered/worse
        let strategicPotential: Double  // 0.0 to 1.0, higher = more line-clearing opportunities
        let complexity: Double          // 0.0 to 1.0, higher = more complex patterns
        let density: Double             // 0.0 to 1.0, percentage of grid filled
        
        /// Overall grid quality score (0.0 to 1.0)
        var qualityScore: Double {
            let weights: (efficiency: Double, fragmentation: Double, strategicPotential: Double, complexity: Double) = (0.3, -0.2, 0.3, 0.2)
            return max(0.0, min(1.0, 
                efficiency * weights.efficiency + 
                fragmentation * weights.fragmentation + 
                strategicPotential * weights.strategicPotential + 
                complexity * weights.complexity
            ))
        }
    }
    
    // MARK: - Difficulty Tier Classification
    
    /// Determines appropriate difficulty tier based on grid quality
    enum DifficultyTier: Int, CaseIterable {
        case diverse = 0        // Best case - reward good play with variety
        case constrained = 1    // Good play - challenging but fair blocks
        case minimal = 2        // Poor play - constrained but solvable blocks
        case emergency = 3      // Worst case - absolute minimum for solvability
        
        var description: String {
            switch self {
            case .diverse: return "DIVERSE"
            case .constrained: return "CONSTRAINED" 
            case .minimal: return "MINIMAL"
            case .emergency: return "EMERGENCY"
            }
        }
        
        /// Thresholds for tier classification based on quality score.
        /// Boundaries live in `AppConfiguration.Gameplay` so balance tuning
        /// doesn't require editing the analysis logic.
        static func fromQualityScore(_ score: Double) -> DifficultyTier {
            switch score {
            case AppConfiguration.Gameplay.difficultyTierDiverseThreshold...1.0:
                return .diverse
            case AppConfiguration.Gameplay.difficultyTierConstrainedThreshold..<AppConfiguration.Gameplay.difficultyTierDiverseThreshold:
                return .constrained
            case AppConfiguration.Gameplay.difficultyTierMinimalThreshold..<AppConfiguration.Gameplay.difficultyTierConstrainedThreshold:
                return .minimal
            default:
                return .emergency
            }
        }
    }
    
    // MARK: - Grid Analysis Methods
    
    /// Analyzes grid state and returns comprehensive metrics
    static func analyzeGrid(_ grid: [[GridCell]]) -> GridStateMetrics {
        let density = calculateDensity(grid)
        let efficiency = calculateEfficiency(grid)
        let fragmentation = calculateFragmentation(grid)
        let strategicPotential = calculateStrategicPotential(grid)
        let complexity = calculateComplexity(grid)
        
        return GridStateMetrics(
            efficiency: efficiency,
            fragmentation: fragmentation,
            strategicPotential: strategicPotential,
            complexity: complexity,
            density: density
        )
    }
    
    /// Determines appropriate difficulty tier for block generation
    static func determineDifficultyTier(for grid: [[GridCell]]) -> DifficultyTier {
        let metrics = analyzeGrid(grid)
        return DifficultyTier.fromQualityScore(metrics.qualityScore)
    }
    
    // MARK: - Metric Calculations
    
    /// Calculates how efficiently the grid space is being used
    private static func calculateEfficiency(_ grid: [[GridCell]]) -> Double {
        let gridSize = AppConfiguration.GameRules.gridSize
        var filledCells = 0
        var totalClusters = 0
        var largestCluster = 0
        
        // Count filled cells and analyze clustering
        var visited = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
        
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if grid[row][col].isFilled {
                    filledCells += 1
                    
                    if !visited[row][col] {
                        let clusterSize = exploreCluster(grid, visited: &visited, row: row, col: col)
                        totalClusters += 1
                        largestCluster = max(largestCluster, clusterSize)
                    }
                }
            }
        }
        
        if filledCells == 0 { return 1.0 } // Empty grid is perfectly efficient
        
        // Efficiency favors fewer, larger clusters over many scattered pieces
        let clusteringEfficiency = totalClusters > 0 ? Double(largestCluster) / Double(filledCells) : 0.0
        let spaceUtilization = Double(filledCells) / Double(gridSize * gridSize)
        
        return (clusteringEfficiency * 0.7) + (spaceUtilization * 0.3)
    }
    
    /// Calculates how fragmented (scattered) the filled cells are
    private static func calculateFragmentation(_ grid: [[GridCell]]) -> Double {
        let gridSize = AppConfiguration.GameRules.gridSize
        var fragmentationScore = 0.0
        var filledCells = 0
        
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if grid[row][col].isFilled {
                    filledCells += 1
                    
                    // Count isolated cells (cells with no filled neighbors)
                    var neighbors = 0
                    for (dr, dc) in [(-1,0), (1,0), (0,-1), (0,1)] {
                        let newRow = row + dr
                        let newCol = col + dc
                        
                        if newRow >= 0 && newRow < gridSize && newCol >= 0 && newCol < gridSize {
                            if grid[newRow][newCol].isFilled {
                                neighbors += 1
                            }
                        }
                    }
                    
                    // More isolated cells = higher fragmentation
                    if neighbors == 0 {
                        fragmentationScore += 1.0
                    } else if neighbors == 1 {
                        fragmentationScore += 0.5
                    }
                }
            }
        }
        
        return filledCells > 0 ? fragmentationScore / Double(filledCells) : 0.0
    }
    
    /// Calculates potential for strategic line clearing
    private static func calculateStrategicPotential(_ grid: [[GridCell]]) -> Double {
        let gridSize = AppConfiguration.GameRules.gridSize
        var potentialScore = 0.0
        
        // Analyze rows for near-completion
        for row in 0..<gridSize {
            let filledInRow = grid[row].filter { $0.isFilled }.count
            if filledInRow >= gridSize - 2 { // 2 or fewer empty cells
                potentialScore += Double(filledInRow) / Double(gridSize)
            }
        }
        
        // Analyze columns for near-completion
        for col in 0..<gridSize {
            let filledInCol = (0..<gridSize).filter { grid[$0][col].isFilled }.count
            if filledInCol >= gridSize - 2 { // 2 or fewer empty cells
                potentialScore += Double(filledInCol) / Double(gridSize)
            }
        }
        
        // Normalize to 0-1 range (max possible is 16.0 if all rows and cols are nearly complete)
        return min(1.0, potentialScore / 16.0)
    }
    
    /// Calculates complexity of current grid patterns
    private static func calculateComplexity(_ grid: [[GridCell]]) -> Double {
        let gridSize = AppConfiguration.GameRules.gridSize
        var complexityScore = 0.0
        
        // Count different patterns and shapes
        var patternCount = 0
        var visited = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
        
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if grid[row][col].isFilled && !visited[row][col] {
                    let clusterSize = exploreCluster(grid, visited: &visited, row: row, col: col)
                    patternCount += 1
                    
                    // Larger clusters contribute more to complexity
                    complexityScore += sqrt(Double(clusterSize))
                }
            }
        }
        
        // Normalize complexity score
        return min(1.0, complexityScore / 20.0)
    }
    
    /// Calculates grid density (percentage filled)
    private static func calculateDensity(_ grid: [[GridCell]]) -> Double {
        let gridSize = AppConfiguration.GameRules.gridSize
        let filledCells = grid.flatMap { $0 }.filter { $0.isFilled }.count
        return Double(filledCells) / Double(gridSize * gridSize)
    }
    
    // MARK: - Helper Methods
    
    /// Explores a cluster of connected filled cells using DFS
    private static func exploreCluster(_ grid: [[GridCell]], visited: inout [[Bool]], row: Int, col: Int) -> Int {
        let gridSize = AppConfiguration.GameRules.gridSize
        
        if row < 0 || row >= gridSize || col < 0 || col >= gridSize ||
           visited[row][col] || !grid[row][col].isFilled {
            return 0
        }
        
        visited[row][col] = true
        var size = 1
        
        // Explore all 4 directions
        for (dr, dc) in [(-1,0), (1,0), (0,-1), (0,1)] {
            size += exploreCluster(grid, visited: &visited, row: row + dr, col: col + dc)
        }
        
        return size
    }
}