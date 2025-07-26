import Foundation
import SwiftUI
import UIKit

enum DifficultyMode: String, CaseIterable, Codable {
    case easy = "Easy"
    case moderate = "Moderate" 
    case hard = "Hard"
    
    var description: String {
        switch self {
        case .easy:
            return "Lots of small blocks, perfect for beginners"
        case .moderate:
            return "Balanced mix of small and large blocks"
        case .hard:
            return "Many large blocks, a real challenge!"
        }
    }
    
    var icon: String {
        switch self {
        case .easy:
            return "leaf.fill"
        case .moderate:
            return "square.stack.3d.up.fill"
        case .hard:
            return "flame.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .easy:
            return GameTheme.Colors.blockGreen
        case .moderate:
            return GameTheme.Colors.blockYellow
        case .hard:
            return GameTheme.Colors.blockRed
        }
    }
}

struct GridPosition: Equatable, Codable, Hashable {
    let row: Int
    let col: Int
}

struct GridCell {
    var isFilled: Bool = false
    var color: BlockColor = .blue
}

enum BlockColor: CaseIterable, Codable, Hashable {
    case blue, green, red, yellow, purple, orange, pink
}

struct ClearedCell: Equatable, Codable {
    let row: Int
    let col: Int
    let color: BlockColor
}

struct BlockShape: Codable, Equatable, Hashable {
    let positions: [GridPosition]
    let color: BlockColor
    
    static let allShapes: [BlockShape] = [
        // Single block
        BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .blue),
        
        // 2-block shapes
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1)], color: .green),
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 1, col: 0)], color: .green),
        
        // 3-block shapes
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 0, col: 2)], color: .red),
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 1, col: 0), GridPosition(row: 2, col: 0)], color: .red),
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 1, col: 0)], color: .yellow),
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 1, col: 1)], color: .yellow),
        
        // 4-block shapes
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 1, col: 0), GridPosition(row: 1, col: 1)], color: .purple),
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 0, col: 2), GridPosition(row: 0, col: 3)], color: .orange),
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 1, col: 0), GridPosition(row: 2, col: 0), GridPosition(row: 3, col: 0)], color: .orange),
        
        // L-shapes
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 1, col: 0), GridPosition(row: 2, col: 0), GridPosition(row: 2, col: 1)], color: .pink),
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 0, col: 2), GridPosition(row: 1, col: 0)], color: .pink),
        
        // T-shapes
        BlockShape(positions: [GridPosition(row: 0, col: 1), GridPosition(row: 1, col: 0), GridPosition(row: 1, col: 1), GridPosition(row: 1, col: 2)], color: .blue),
        
        // 3x3 square (9 blocks)
        BlockShape(positions: [
            GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 0, col: 2),
            GridPosition(row: 1, col: 0), GridPosition(row: 1, col: 1), GridPosition(row: 1, col: 2),
            GridPosition(row: 2, col: 0), GridPosition(row: 2, col: 1), GridPosition(row: 2, col: 2)
        ], color: .green)
    ]
}

class GameState: ObservableObject {
    static let gridSize = GameTheme.GameConfig.gridSize
    
    @Published var grid: [[GridCell]]
    @Published var currentBlocks: [BlockShape]
    @Published var score: Int = 0
    @Published var isGameOver: Bool = false
    @Published var linesCleared: Int = 0
    @Published var lastClearedCells: [ClearedCell] = []
    
    // Game Statistics
    @Published var blocksPlaced: Int = 0
    @Published var gameStartTime: Date = Date()
    @Published var longestCombo: Int = 0
    @Published var currentCombo: Int = 0
    @Published var isNewHighScore: Bool = false
    
    // Difficulty mode
    @Published var currentDifficulty: DifficultyMode = .easy
    
    let highScoreManager = HighScoreManager()
    
    init() {
        grid = Array(repeating: Array(repeating: GridCell(), count: GameState.gridSize), count: GameState.gridSize)
        currentBlocks = []
        generateNewBlocks()
    }
    
    func generateNewBlocks() {
        currentBlocks = BlockGenerator.generateWeightedBlocks(count: 3, difficulty: currentDifficulty)
        checkGameOver()
    }
    
    func canPlaceBlock(_ block: BlockShape, at gridPosition: GridPosition) -> Bool {
        for blockPos in block.positions {
            let finalRow = gridPosition.row + blockPos.row
            let finalCol = gridPosition.col + blockPos.col
            
            // Check bounds
            if finalRow < 0 || finalRow >= GameState.gridSize || 
               finalCol < 0 || finalCol >= GameState.gridSize {
                return false
            }
            
            // Check if cell is already filled
            if grid[finalRow][finalCol].isFilled {
                return false
            }
        }
        return true
    }
    
    func placeBlock(_ block: BlockShape, at gridPosition: GridPosition) {
        guard canPlaceBlock(block, at: gridPosition) else { return }
        
        #if DEBUG
        print("🧩 Placing block with \(block.positions.count) cells at (\(gridPosition.row), \(gridPosition.col))")
        #endif
        
        // Haptic feedback for block placement
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Place the block
        for blockPos in block.positions {
            let finalRow = gridPosition.row + blockPos.row
            let finalCol = gridPosition.col + blockPos.col
            grid[finalRow][finalCol].isFilled = true
            grid[finalRow][finalCol].color = block.color
        }
        
        // Update statistics
        blocksPlaced += 1
        
        // Add points for placing block
        score += block.positions.count * 10
        
        // Remove the placed block from current blocks
        if let index = currentBlocks.firstIndex(where: { $0.positions == block.positions && $0.color == block.color }) {
            currentBlocks.remove(at: index)
        }
        
        // Clear completed lines
        let clearResult = clearCompletedLines()
        lastClearedCells = clearResult.clearedCells
        
        // Generate new blocks if all are used
        if currentBlocks.isEmpty {
            generateNewBlocks()
        }
        
        // Always check for game over after placing a block
        // This ensures immediate detection when no moves are available
        checkGameOver()
    }
    
    func clearCompletedLines() -> (clearedRows: Set<Int>, clearedCols: Set<Int>, clearedCells: [ClearedCell]) {
        var clearedRows: Set<Int> = []
        var clearedCols: Set<Int> = []
        var clearedCells: [ClearedCell] = []
        
        // Check rows
        for row in 0..<GameState.gridSize {
            if grid[row].allSatisfy({ $0.isFilled }) {
                clearedRows.insert(row)
            }
        }
        
        // Check columns
        for col in 0..<GameState.gridSize {
            if (0..<GameState.gridSize).allSatisfy({ grid[$0][col].isFilled }) {
                clearedCols.insert(col)
            }
        }
        
        // Collect cell information before clearing
        for row in clearedRows {
            for col in 0..<GameState.gridSize {
                clearedCells.append(ClearedCell(row: row, col: col, color: grid[row][col].color))
            }
        }
        
        for col in clearedCols {
            for row in 0..<GameState.gridSize {
                if !clearedRows.contains(row) { // Avoid duplicates
                    clearedCells.append(ClearedCell(row: row, col: col, color: grid[row][col].color))
                }
            }
        }
        
        // Clear rows
        for row in clearedRows {
            for col in 0..<GameState.gridSize {
                grid[row][col] = GridCell()
            }
        }
        
        // Clear columns
        for col in clearedCols {
            for row in 0..<GameState.gridSize {
                grid[row][col] = GridCell()
            }
        }
        
        // Add bonus points
        let totalLinesCleared = clearedRows.count + clearedCols.count
        if totalLinesCleared > 0 {
            // Strong haptic feedback for line clearing
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
            
            linesCleared += totalLinesCleared
            score += totalLinesCleared * 100
            
            // Update combo tracking
            currentCombo = totalLinesCleared
            if currentCombo > longestCombo {
                longestCombo = currentCombo
            }
            
            if totalLinesCleared > 1 {
                score += (totalLinesCleared - 1) * 50 // Combo bonus
            }
        } else {
            currentCombo = 0
        }
        
        return (clearedRows: clearedRows, clearedCols: clearedCols, clearedCells: clearedCells)
    }
    
    func checkGameOver() {
        // If no current blocks, it's not game over (waiting for new blocks)
        guard !currentBlocks.isEmpty else {
            isGameOver = false
            return
        }
        
        // Use the optimized game logic function
        let gameOverState = GameRules.isGameOver(currentBlocks: currentBlocks, grid: grid)
        
        #if DEBUG
        print("🎮 Game Over Check: hasBlocks=\(currentBlocks.count), gameOverState=\(gameOverState), currentGameOver=\(isGameOver)")
        if gameOverState {
            print("🚫 No valid moves found for current blocks:")
            for (index, block) in currentBlocks.enumerated() {
                print("   Block \(index): \(block.positions.count) cells")
            }
        }
        #endif
        
        if gameOverState && !isGameOver {
            // Game just ended - handle high score
            print("🏁 GAME OVER DETECTED! Final score: \(score)")
            isGameOver = true
            let oldHighScore = highScoreManager.highScore
            highScoreManager.updateHighScore(score)
            isNewHighScore = score > oldHighScore
        } else if !gameOverState {
            // Game is still active
            isGameOver = false
        }
    }
    
    func startGame(difficulty: DifficultyMode) {
        currentDifficulty = difficulty
        resetGame()
    }
    
    func resetGame() {
        grid = Array(repeating: Array(repeating: GridCell(), count: GameState.gridSize), count: GameState.gridSize)
        score = 0
        linesCleared = 0
        isGameOver = false
        lastClearedCells = []
        
        // Reset statistics
        blocksPlaced = 0
        gameStartTime = Date()
        longestCombo = 0
        currentCombo = 0
        isNewHighScore = false
        
        // Randomly pre-fill the grid with shapes
        randomlyFillGrid()
        
        generateNewBlocks()
    }
    
    private func randomlyFillGrid() {
        let totalCells = GameState.gridSize * GameState.gridSize // 64 cells for 8x8
        let maxFillCells = Int(Double(totalCells) * 0.4) // Up to 40% filled (25-26 cells)
        let targetFillCells = Int.random(in: 0...maxFillCells)
        
        var cellsPlaced = 0
        var attemptCount = 0
        let maxAttempts = targetFillCells * 10 // Prevent infinite loops
        
        while cellsPlaced < targetFillCells && attemptCount < maxAttempts {
            attemptCount += 1
            
            // Pick a random shape
            guard let randomShape = BlockShape.allShapes.randomElement() else { continue }
            
            // Pick a random position
            let randomRow = Int.random(in: 0..<GameState.gridSize)
            let randomCol = Int.random(in: 0..<GameState.gridSize)
            let position = GridPosition(row: randomRow, col: randomCol)
            
            // Try to place the shape
            if canPlaceBlock(randomShape, at: position) {
                // Temporarily place the block to check for complete lines
                var tempGrid = grid
                for blockPos in randomShape.positions {
                    let finalRow = position.row + blockPos.row
                    let finalCol = position.col + blockPos.col
                    tempGrid[finalRow][finalCol].isFilled = true
                    tempGrid[finalRow][finalCol].color = randomShape.color
                }
                
                // Check if this placement would create any complete lines
                let wouldCreateLines = wouldCreateCompleteLines(in: tempGrid)
                
                if !wouldCreateLines {
                    // Place the block for real
                    for blockPos in randomShape.positions {
                        let finalRow = position.row + blockPos.row
                        let finalCol = position.col + blockPos.col
                        grid[finalRow][finalCol].isFilled = true
                        grid[finalRow][finalCol].color = randomShape.color
                        cellsPlaced += 1
                    }
                }
            }
        }
    }
    
    private func wouldCreateCompleteLines(in testGrid: [[GridCell]]) -> Bool {
        // Check rows for completion
        for row in 0..<GameState.gridSize {
            if testGrid[row].allSatisfy({ $0.isFilled }) {
                return true
            }
        }
        
        // Check columns for completion
        for col in 0..<GameState.gridSize {
            if (0..<GameState.gridSize).allSatisfy({ testGrid[$0][col].isFilled }) {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Computed Statistics
    
    var gameTime: TimeInterval {
        Date().timeIntervalSince(gameStartTime)
    }
    
    var averageBlockScore: Double {
        guard blocksPlaced > 0 else { return 0.0 }
        return Double(score) / Double(blocksPlaced)
    }
    
    var lineClearPercentage: Double {
        guard blocksPlaced > 0 else { return 0.0 }
        return (Double(linesCleared) / Double(blocksPlaced)) * 100
    }
}

