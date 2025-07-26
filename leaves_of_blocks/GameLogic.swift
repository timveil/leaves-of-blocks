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
    
    // MARK: - Shape Variety Helpers
    
    enum ShapeOrientation: CaseIterable {
        case horizontal, vertical, square, lShape, tShape, irregular
    }
    
    private static func getShapeType(_ block: BlockShape) -> String {
        let cellCount = block.positions.count
        
        switch cellCount {
        case 1: return "single"
        case 2: return "double"
        case 3: return "triple"
        case 4: return "quad"
        case 5: return "penta"
        case 6: return "hexa" 
        case 7: return "hepta"
        case 9: return "nona"
        default: return "other"
        }
    }
    
    private static func getShapeOrientation(_ block: BlockShape) -> ShapeOrientation {
        let minRow = block.positions.map(\.row).min() ?? 0
        let maxRow = block.positions.map(\.row).max() ?? 0
        let minCol = block.positions.map(\.col).min() ?? 0
        let maxCol = block.positions.map(\.col).max() ?? 0
        
        let width = maxCol - minCol + 1
        let height = maxRow - minRow + 1
        
        if width == height {
            return .square
        } else if width > height {
            return .horizontal
        } else {
            return .vertical
        }
    }
    
    private static func generateVariedBlock(
        difficulty: DifficultyMode,
        excludeShapeTypes: [String],
        excludeOrientations: [ShapeOrientation]
    ) -> BlockShape {
        let blockWeights = getBlockWeights(for: difficulty)
        var filteredWeights: [BlockShape: Double] = [:]
        
        // Filter out shapes we want to avoid for variety
        for (block, weight) in blockWeights {
            let shapeType = getShapeType(block)
            let orientation = getShapeOrientation(block)
            
            // Avoid 3 of the same type
            let typeCount = excludeShapeTypes.filter { $0 == shapeType }.count
            let orientationCount = excludeOrientations.filter { $0 == orientation }.count
            
            if typeCount < 2 && orientationCount < 2 {
                filteredWeights[block] = weight
            } else {
                // Drastically reduce probability but don't eliminate entirely
                filteredWeights[block] = weight * 0.1
            }
        }
        
        // If we filtered too aggressively, fall back to full weights
        if filteredWeights.isEmpty {
            filteredWeights = blockWeights
        }
        
        let totalWeight = filteredWeights.values.reduce(0, +)
        let randomValue = Double.random(in: 0...totalWeight)
        
        var currentWeight: Double = 0
        
        for (block, weight) in filteredWeights {
            currentWeight += weight
            if randomValue <= currentWeight {
                let randomColor = BlockColor.allCases.randomElement()!
                return BlockShape(positions: block.positions, color: randomColor)
            }
        }
        
        // Fallback
        let randomColor = BlockColor.allCases.randomElement()!
        return BlockShape(positions: BlockShape.allShapes[0].positions, color: randomColor)
    }
    
    private static func getBlockWeights(for difficulty: DifficultyMode) -> [BlockShape: Double] {
        var weights: [BlockShape: Double] = [:]
        
        // Ensure we have weights for all shapes (now 22 total)
        for (index, shape) in BlockShape.allShapes.enumerated() {
            let cellCount = shape.positions.count
            
            switch difficulty {
            case .easy:
                weights[shape] = getEasyWeight(for: cellCount, index: index)
            case .moderate:
                weights[shape] = getModerateWeight(for: cellCount, index: index)
            case .hard:
                weights[shape] = getHardWeight(for: cellCount, index: index)
            }
        }
        
        return weights
    }
    
    private static func getEasyWeight(for cellCount: Int, index: Int) -> Double {
        switch cellCount {
        case 1: return 3.0  // Single blocks common
        case 2: return 3.0  // 2-block shapes common
        case 3: return 2.5  // 3-block shapes moderate
        case 4: return 2.0  // 4-block shapes less common
        case 5: return 1.5  // 5-block shapes (new lines & L-shapes)
        case 6: return 1.0  // 6-block rectangles 
        case 7: return 0.8  // 7-block L-shapes
        case 9: return 0.5  // 9-block square rare
        default: return 1.0
        }
    }
    
    private static func getModerateWeight(for cellCount: Int, index: Int) -> Double {
        switch cellCount {
        case 1: return 2.0  // Single blocks less common
        case 2: return 2.5  // 2-block shapes moderate
        case 3: return 3.0  // 3-block shapes common
        case 4: return 2.5  // 4-block shapes moderate
        case 5: return 2.0  // 5-block shapes moderate
        case 6: return 1.5  // 6-block rectangles
        case 7: return 1.2  // 7-block L-shapes
        case 9: return 1.0  // 9-block square moderate
        default: return 1.5
        }
    }
    
    private static func getHardWeight(for cellCount: Int, index: Int) -> Double {
        switch cellCount {
        case 1: return 1.0  // Single blocks rare
        case 2: return 1.5  // 2-block shapes rare
        case 3: return 2.0  // 3-block shapes less common
        case 4: return 3.0  // 4-block shapes common
        case 5: return 3.5  // 5-block shapes very common
        case 6: return 3.0  // 6-block rectangles common
        case 7: return 2.5  // 7-block L-shapes common
        case 9: return 2.0  // 9-block square common
        default: return 2.0
        }
    }
    
    static func generateWeightedBlocks(count: Int = 3, difficulty: DifficultyMode = .easy) -> [BlockShape] {
        var blocks: [BlockShape] = []
        var usedShapeTypes: [String] = []
        var usedOrientations: [ShapeOrientation] = []
        
        for _ in 0..<count {
            let newBlock = generateVariedBlock(
                difficulty: difficulty,
                excludeShapeTypes: usedShapeTypes,
                excludeOrientations: usedOrientations
            )
            
            blocks.append(newBlock)
            
            // Track what we've used to ensure variety
            let shapeType = getShapeType(newBlock)
            let orientation = getShapeOrientation(newBlock)
            
            usedShapeTypes.append(shapeType)
            usedOrientations.append(orientation)
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