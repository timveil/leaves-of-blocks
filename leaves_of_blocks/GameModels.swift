import Foundation

struct GridPosition: Equatable, Codable {
    let row: Int
    let col: Int
}

struct GridCell {
    var isFilled: Bool = false
    var color: BlockColor = .blue
}

enum BlockColor: CaseIterable, Codable {
    case blue, green, red, yellow, purple, orange, pink
}

struct BlockShape: Codable, Equatable {
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
        
        // 5-block plus
        BlockShape(positions: [GridPosition(row: 1, col: 1), GridPosition(row: 0, col: 1), GridPosition(row: 2, col: 1), GridPosition(row: 1, col: 0), GridPosition(row: 1, col: 2)], color: .green)
    ]
}

class GameState: ObservableObject {
    static let gridSize = 10
    
    @Published var grid: [[GridCell]]
    @Published var currentBlocks: [BlockShape]
    @Published var score: Int = 0
    @Published var isGameOver: Bool = false
    @Published var linesCleared: Int = 0
    
    let highScoreManager = HighScoreManager()
    
    init() {
        grid = Array(repeating: Array(repeating: GridCell(), count: GameState.gridSize), count: GameState.gridSize)
        currentBlocks = []
        generateNewBlocks()
    }
    
    func generateNewBlocks() {
        generateWeightedBlocks()
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
        
        // Place the block
        for blockPos in block.positions {
            let finalRow = gridPosition.row + blockPos.row
            let finalCol = gridPosition.col + blockPos.col
            grid[finalRow][finalCol].isFilled = true
            grid[finalRow][finalCol].color = block.color
        }
        
        // Add points for placing block
        score += block.positions.count * 10
        
        // Remove the placed block from current blocks
        if let index = currentBlocks.firstIndex(where: { $0.positions == block.positions && $0.color == block.color }) {
            currentBlocks.remove(at: index)
        }
        
        // Clear completed lines
        clearCompletedLines()
        
        // Generate new blocks if all are used
        if currentBlocks.isEmpty {
            generateNewBlocks()
        }
    }
    
    func clearCompletedLines() {
        var clearedRows: Set<Int> = []
        var clearedCols: Set<Int> = []
        
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
            linesCleared += totalLinesCleared
            score += totalLinesCleared * 100
            if totalLinesCleared > 1 {
                score += (totalLinesCleared - 1) * 50 // Combo bonus
            }
        }
    }
    
    func checkGameOver() {
        for block in currentBlocks {
            for row in 0..<GameState.gridSize {
                for col in 0..<GameState.gridSize {
                    if canPlaceBlock(block, at: GridPosition(row: row, col: col)) {
                        isGameOver = false
                        return
                    }
                }
            }
        }
        isGameOver = true
        highScoreManager.updateHighScore(score)
    }
    
    func resetGame() {
        grid = Array(repeating: Array(repeating: GridCell(), count: GameState.gridSize), count: GameState.gridSize)
        score = 0
        linesCleared = 0
        isGameOver = false
        generateNewBlocks()
    }
}