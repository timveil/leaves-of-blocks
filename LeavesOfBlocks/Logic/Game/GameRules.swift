import Foundation

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
        // If there are no blocks, it's not game over (game should generate new blocks)
        guard !currentBlocks.isEmpty else {
            return false
        }
        
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