import Foundation

// MARK: - Game Logic Separation

// MARK: - Game Rules Engine

struct GameRules {
    
    // MARK: - Scoring Rules
    
    static func calculateBlockPlacementScore(blockSize: Int) -> Int {
        return blockSize * GameTheme.GameConfig.baseBlockScore
    }
    
    static func calculateLineClearScore(linesCleared: Int) -> Int {
        let baseScore = linesCleared * GameTheme.GameConfig.lineScore
        let comboBonus = linesCleared > 1 ? (linesCleared - 1) * GameTheme.GameConfig.comboBonus : 0
        return baseScore + comboBonus
    }
    
    // MARK: - Line Detection
    
    static func findCompletedLines(in grid: [[GridCell]]) -> (rows: Set<Int>, cols: Set<Int>) {
        var completedRows: Set<Int> = []
        var completedCols: Set<Int> = []
        
        // Check rows
        for row in 0..<GameTheme.GameConfig.gridSize {
            if grid[row].allSatisfy({ $0.isFilled }) {
                completedRows.insert(row)
            }
        }
        
        // Check columns
        for col in 0..<GameTheme.GameConfig.gridSize {
            if (0..<GameTheme.GameConfig.gridSize).allSatisfy({ grid[$0][col].isFilled }) {
                completedCols.insert(col)
            }
        }
        
        return (rows: completedRows, cols: completedCols)
    }
    
    // MARK: - Placement Validation
    
    static func canPlaceBlock(_ block: BlockShape, at position: GridPosition, in grid: [[GridCell]]) -> Bool {
        for blockPos in block.positions {
            let finalRow = position.row + blockPos.row
            let finalCol = position.col + blockPos.col
            
            // Check bounds
            if finalRow < 0 || finalRow >= GameTheme.GameConfig.gridSize || 
               finalCol < 0 || finalCol >= GameTheme.GameConfig.gridSize {
                return false
            }
            
            // Check if cell is already filled
            if grid[finalRow][finalCol].isFilled {
                return false
            }
        }
        return true
    }
    
    // MARK: - Game Over Detection
    
    static func isGameOver(currentBlocks: [BlockShape], grid: [[GridCell]]) -> Bool {
        for block in currentBlocks {
            for row in 0..<GameTheme.GameConfig.gridSize {
                for col in 0..<GameTheme.GameConfig.gridSize {
                    if canPlaceBlock(block, at: GridPosition(row: row, col: col), in: grid) {
                        return false
                    }
                }
            }
        }
        return true
    }
}

// MARK: - Block Generator

struct BlockGenerator {
    
    // MARK: - Difficulty-Based Block Generation
    
    private static func getBlockWeights(for difficulty: DifficultyMode) -> [BlockShape: Double] {
        switch difficulty {
        case .easy:
            return [
                // Single blocks - reduced frequency
                BlockShape.allShapes[0]: 2.0,
                
                // 2-block shapes - reduced frequency
                BlockShape.allShapes[1]: 2.0,
                BlockShape.allShapes[2]: 2.0,
                
                // 3-block shapes - moderate frequency
                BlockShape.allShapes[3]: 2.5,
                BlockShape.allShapes[4]: 2.5,
                BlockShape.allShapes[5]: 2.5,
                BlockShape.allShapes[6]: 2.5,
                
                // 4-block shapes - increased frequency
                BlockShape.allShapes[7]: 3.0,
                BlockShape.allShapes[8]: 2.5,
                BlockShape.allShapes[9]: 2.5,
                
                // L-shapes - increased frequency
                BlockShape.allShapes[10]: 2.0,
                BlockShape.allShapes[11]: 2.0,
                
                // T-shapes - increased frequency
                BlockShape.allShapes[12]: 2.0,
                
                // 3x3 square - now more common
                BlockShape.allShapes[13]: 1.0
            ]
            
        case .moderate:
            return [
                // Single blocks - reduced frequency
                BlockShape.allShapes[0]: 1.5,
                
                // 2-block shapes - reduced frequency
                BlockShape.allShapes[1]: 1.5,
                BlockShape.allShapes[2]: 1.5,
                
                // 3-block shapes - moderate frequency
                BlockShape.allShapes[3]: 2.0,
                BlockShape.allShapes[4]: 2.0,
                BlockShape.allShapes[5]: 2.0,
                BlockShape.allShapes[6]: 2.0,
                
                // 4-block shapes - increased frequency
                BlockShape.allShapes[7]: 3.5,
                BlockShape.allShapes[8]: 3.0,
                BlockShape.allShapes[9]: 3.0,
                
                // L-shapes - increased frequency
                BlockShape.allShapes[10]: 2.5,
                BlockShape.allShapes[11]: 2.5,
                
                // T-shapes - increased frequency
                BlockShape.allShapes[12]: 2.5,
                
                // 3x3 square - significantly more common
                BlockShape.allShapes[13]: 2.0
            ]
            
        case .hard:
            return [
                // Single blocks - rare
                BlockShape.allShapes[0]: 1.0,
                
                // 2-block shapes - rare
                BlockShape.allShapes[1]: 1.0,
                BlockShape.allShapes[2]: 1.0,
                
                // 3-block shapes - reduced frequency
                BlockShape.allShapes[3]: 1.5,
                BlockShape.allShapes[4]: 1.5,
                BlockShape.allShapes[5]: 1.5,
                BlockShape.allShapes[6]: 1.5,
                
                // 4-block shapes - very common
                BlockShape.allShapes[7]: 4.0,
                BlockShape.allShapes[8]: 3.5,
                BlockShape.allShapes[9]: 3.5,
                
                // L-shapes - very common
                BlockShape.allShapes[10]: 3.5,
                BlockShape.allShapes[11]: 3.5,
                
                // T-shapes - very common
                BlockShape.allShapes[12]: 3.5,
                
                // 3x3 square - much more common!
                BlockShape.allShapes[13]: 3.0
            ]
        }
    }
    
    static func generateWeightedBlocks(count: Int = 3, difficulty: DifficultyMode = .easy) -> [BlockShape] {
        var blocks: [BlockShape] = []
        
        for _ in 0..<count {
            blocks.append(generateWeightedBlock(difficulty: difficulty))
        }
        
        return blocks
    }
    
    private static func generateWeightedBlock(difficulty: DifficultyMode) -> BlockShape {
        let blockWeights = getBlockWeights(for: difficulty)
        let totalWeight = blockWeights.values.reduce(0, +)
        let randomValue = Double.random(in: 0...totalWeight)
        
        var currentWeight: Double = 0
        
        for (block, weight) in blockWeights {
            currentWeight += weight
            if randomValue <= currentWeight {
                let randomColor = BlockColor.allCases.randomElement()!
                return BlockShape(positions: block.positions, color: randomColor)
            }
        }
        
        // Fallback to first block if something goes wrong
        let randomColor = BlockColor.allCases.randomElement()!
        return BlockShape(positions: BlockShape.allShapes[0].positions, color: randomColor)
    }
}

// MARK: - Animation Manager

class AnimationManager: ObservableObject {
    
    // MARK: - Animation State
    
    @Published var fallingLeaves: [FallingLeaf] = []
    
    // MARK: - Animation Creation
    
    func createFallingLeaves(from clearedCells: [ClearedCell], gridFrame: CGRect, cellSize: CGFloat) {
        var newLeaves: [FallingLeaf] = []
        
        for cell in clearedCells {
            let leafPosition = CGPoint(
                x: gridFrame.minX + CGFloat(cell.col) * (cellSize + GameTheme.Layout.gridSpacing) + cellSize/2 + GameTheme.Layout.gridPadding,
                y: gridFrame.minY + CGFloat(cell.row) * (cellSize + GameTheme.Layout.gridSpacing) + cellSize/2 + GameTheme.Layout.gridPadding
            )
            
            let leaf = FallingLeaf(
                startPosition: leafPosition,
                color: cell.color.color,
                size: CGFloat.random(in: GameTheme.GameConfig.leafSizeRange)
            )
            newLeaves.append(leaf)
        }
        
        fallingLeaves.append(contentsOf: newLeaves)
        
        // Remove leaves after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + GameTheme.Animations.leafRemovalDelay) {
            self.fallingLeaves.removeAll()
        }
    }
    
    func clearAllAnimations() {
        fallingLeaves.removeAll()
    }
}

// MARK: - Game State Validator

struct GameStateValidator {
    
    // MARK: - Validation Rules
    
    static func validateGameState(_ gameState: GameState) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // Validate grid size
        if gameState.grid.count != GameTheme.GameConfig.gridSize {
            errors.append(.invalidGridSize(expected: GameTheme.GameConfig.gridSize, actual: gameState.grid.count))
        }
        
        // Validate grid columns
        for (index, row) in gameState.grid.enumerated() {
            if row.count != GameTheme.GameConfig.gridSize {
                errors.append(.invalidRowSize(row: index, expected: GameTheme.GameConfig.gridSize, actual: row.count))
            }
        }
        
        // Validate score
        if gameState.score < 0 {
            errors.append(.negativeScore(gameState.score))
        }
        
        // Validate current blocks
        if gameState.currentBlocks.isEmpty && !gameState.isGameOver {
            errors.append(.noCurrentBlocks)
        }
        
        return errors
    }
}

// MARK: - Validation Errors

enum ValidationError: Error, CustomStringConvertible {
    case invalidGridSize(expected: Int, actual: Int)
    case invalidRowSize(row: Int, expected: Int, actual: Int)
    case negativeScore(Int)
    case noCurrentBlocks
    
    var description: String {
        switch self {
        case .invalidGridSize(let expected, let actual):
            return "Invalid grid size: expected \(expected), got \(actual)"
        case .invalidRowSize(let row, let expected, let actual):
            return "Invalid row \(row) size: expected \(expected), got \(actual)"
        case .negativeScore(let score):
            return "Negative score: \(score)"
        case .noCurrentBlocks:
            return "No current blocks available"
        }
    }
}

// MARK: - Performance Monitor

struct PerformanceMonitor {
    
    // MARK: - Performance Metrics
    
    static func measureExecutionTime<T>(operation: () throws -> T) rethrows -> (result: T, time: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        return (result: result, time: timeElapsed)
    }
    
    static func logPerformanceWarning(operation: String, time: TimeInterval, threshold: TimeInterval = 0.016) {
        if time > threshold {
            print("⚠️ Performance Warning: \(operation) took \(String(format: "%.3f", time))s (threshold: \(String(format: "%.3f", threshold))s)")
        }
    }
}

// MARK: - Debug Helpers

#if DEBUG
struct GameDebug {
    
    static func printGameState(_ gameState: GameState) {
        print("=== Game State ===")
        print("Score: \(gameState.score)")
        print("Lines Cleared: \(gameState.linesCleared)")
        print("Game Over: \(gameState.isGameOver)")
        print("Current Blocks: \(gameState.currentBlocks.count)")
        print("==================")
    }
    
    static func printGrid(_ grid: [[GridCell]]) {
        print("=== Grid State ===")
        for row in grid {
            let rowString = row.map { $0.isFilled ? "■" : "□" }.joined()
            print(rowString)
        }
        print("==================")
    }
}
#endif