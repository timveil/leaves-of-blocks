import Foundation

// MARK: - Game Logic Service

/// Handles all game logic operations separate from state management
class GameLogic {
    
    // MARK: - Block Placement Logic
    
    /// Validates if a block can be placed at the specified position
    static func canPlaceBlock(_ block: BlockShape, at gridPosition: GridPosition, in grid: [[GridCell]]) -> Bool {
        switch block.type {
        case .horizontalClear, .verticalClear, .areaClear:
            // All special blocks require a valid grid position
            return isValidGridPosition(gridPosition)
            
        case .normal:
            // Normal block placement validation
            for blockPos in block.positions {
                let finalRow = gridPosition.row + blockPos.row
                let finalCol = gridPosition.col + blockPos.col
                
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
    }
    
    /// Places a block on the grid and returns the updated grid
    static func placeBlock(_ block: BlockShape, at gridPosition: GridPosition, in grid: inout [[GridCell]]) {
        switch block.type {
        case .horizontalClear:
            // Clear the entire row where the special block is placed
            let targetRow = gridPosition.row
            if targetRow >= 0 && targetRow < GameTheme.GameConfig.gridSize {
                for col in 0..<GameTheme.GameConfig.gridSize {
                    grid[targetRow][col] = GridCell()  // Reset to default state
                }
            }
            
        case .verticalClear:
            // Clear the entire column where the special block is placed
            let targetCol = gridPosition.col
            if targetCol >= 0 && targetCol < GameTheme.GameConfig.gridSize {
                for row in 0..<GameTheme.GameConfig.gridSize {
                    grid[row][targetCol] = GridCell()  // Reset to default state
                }
            }
            
        case .areaClear:
            // Clear a 3x3 area centered on the placement position
            let centerRow = gridPosition.row
            let centerCol = gridPosition.col
            
            // Clear 3x3 area (one cell in each direction from center)
            for rowOffset in -1...1 {
                for colOffset in -1...1 {
                    let targetRow = centerRow + rowOffset
                    let targetCol = centerCol + colOffset
                    let targetPosition = GridPosition(row: targetRow, col: targetCol)
                    
                    // Only clear cells that are within grid bounds
                    if isValidGridPosition(targetPosition) {
                        grid[targetRow][targetCol] = GridCell()  // Reset to default state
                    }
                }
            }
            
        case .normal:
            // Normal block placement
            for blockPos in block.positions {
                let finalRow = gridPosition.row + blockPos.row
                let finalCol = gridPosition.col + blockPos.col
                
                grid[finalRow][finalCol].isFilled = true
                grid[finalRow][finalCol].color = block.color
            }
        }
    }
    
    // MARK: - Line Clearing Logic
    
    /// Finds and clears completed lines, returning information about cleared cells
    static func clearCompletedLines(in grid: inout [[GridCell]]) -> (clearedRows: Set<Int>, clearedCols: Set<Int>, clearedCells: [ClearedCell]) {
        var clearedRows: Set<Int> = []
        var clearedCols: Set<Int> = []
        var clearedCells: [ClearedCell] = []
        
        // Check rows
        for row in 0..<GameTheme.GameConfig.gridSize {
            if grid[row].allSatisfy({ $0.isFilled }) {
                clearedRows.insert(row)
            }
        }
        
        // Check columns
        for col in 0..<GameTheme.GameConfig.gridSize {
            if (0..<GameTheme.GameConfig.gridSize).allSatisfy({ grid[$0][col].isFilled }) {
                clearedCols.insert(col)
            }
        }
        
        // Collect cell information before clearing
        for row in clearedRows {
            for col in 0..<GameTheme.GameConfig.gridSize {
                clearedCells.append(ClearedCell(row: row, col: col, color: grid[row][col].color))
            }
        }
        
        for col in clearedCols {
            for row in 0..<GameTheme.GameConfig.gridSize {
                // Avoid double-counting cells that are in both cleared rows and columns
                if !clearedRows.contains(row) {
                    clearedCells.append(ClearedCell(row: row, col: col, color: grid[row][col].color))
                }
            }
        }
        
        // Clear the lines
        for row in clearedRows {
            for col in 0..<GameTheme.GameConfig.gridSize {
                grid[row][col] = GridCell()
            }
        }
        
        for col in clearedCols {
            for row in 0..<GameTheme.GameConfig.gridSize {
                grid[row][col] = GridCell()
            }
        }
        
        return (clearedRows, clearedCols, clearedCells)
    }
    
    // MARK: - Game Over Logic
    
    /// Checks if any of the current blocks can be placed on the grid
    static func isGameOver(currentBlocks: [BlockShape], grid: [[GridCell]]) -> Bool {
        for block in currentBlocks {
            if canPlaceAnyBlock(block, in: grid) {
                return false
            }
        }
        return true
    }
    
    /// Checks if a specific block can be placed anywhere on the grid
    private static func canPlaceAnyBlock(_ block: BlockShape, in grid: [[GridCell]]) -> Bool {
        for row in 0..<GameTheme.GameConfig.gridSize {
            for col in 0..<GameTheme.GameConfig.gridSize {
                let position = GridPosition(row: row, col: col)
                if canPlaceBlock(block, at: position, in: grid) {
                    return true
                }
            }
        }
        return false
    }
    
    // MARK: - Score Calculation
    
    /// Calculates score for placing a block
    static func calculateBlockScore(block: BlockShape) -> Int {
        switch block.type {
        case .horizontalClear, .verticalClear:
            // Special shapes give bonus points
            return GameTheme.GameConfig.lineScore  // Same as clearing one line
        case .areaClear:
            // Area clear gives higher bonus points (equivalent to clearing 2 lines)
            return GameTheme.GameConfig.lineScore * 2
        case .normal:
            return block.positions.count * GameTheme.GameConfig.baseBlockScore
        }
    }
    
    /// Calculates score for clearing lines with combo bonus
    static func calculateLineScore(clearedRows: Int, clearedCols: Int) -> Int {
        let totalLines = clearedRows + clearedCols
        let baseScore = totalLines * GameTheme.GameConfig.lineScore
        
        // Combo bonus for multiple lines
        let comboBonus = max(0, totalLines - 1) * GameTheme.GameConfig.comboBonus
        
        return baseScore + comboBonus
    }
    
    // MARK: - Grid Utilities
    
    /// Creates an empty grid
    static func createEmptyGrid() -> [[GridCell]] {
        return Array(repeating: Array(repeating: GridCell(), count: GameTheme.GameConfig.gridSize), count: GameTheme.GameConfig.gridSize)
    }
    
    /// Randomly fills grid for testing purposes
    static func randomlyFillGrid(_ grid: inout [[GridCell]], targetPercentage: Double = 0.15) {
        let totalCells = GameTheme.GameConfig.gridSize * GameTheme.GameConfig.gridSize
        let targetCells = Int(Double(totalCells) * targetPercentage)
        
        var cellsPlaced = 0
        var attemptCount = 0
        let maxAttempts = targetCells * 3
        
        while cellsPlaced < targetCells && attemptCount < maxAttempts {
            let randomRow = Int.random(in: 0..<GameTheme.GameConfig.gridSize)
            let randomCol = Int.random(in: 0..<GameTheme.GameConfig.gridSize)
            
            if !grid[randomRow][randomCol].isFilled {
                // Test placing a single block to ensure it doesn't create complete lines
                var tempGrid = grid
                tempGrid[randomRow][randomCol].isFilled = true
                tempGrid[randomRow][randomCol].color = BlockColor.allCases.randomElement() ?? .blue
                
                // Only place if it doesn't create complete lines
                if !wouldCreateCompleteLines(in: tempGrid) {
                    grid[randomRow][randomCol].isFilled = true
                    grid[randomRow][randomCol].color = BlockColor.allCases.randomElement() ?? .blue
                    cellsPlaced += 1
                }
            }
            
            attemptCount += 1
        }
    }
    
    /// Checks if placing cells would create complete lines
    private static func wouldCreateCompleteLines(in testGrid: [[GridCell]]) -> Bool {
        // Check rows
        for row in 0..<GameTheme.GameConfig.gridSize {
            if testGrid[row].allSatisfy({ $0.isFilled }) {
                return true
            }
        }
        
        // Check columns
        for col in 0..<GameTheme.GameConfig.gridSize {
            if (0..<GameTheme.GameConfig.gridSize).allSatisfy({ testGrid[$0][col].isFilled }) {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Helper Methods
    
    /// Validates if a grid position is within valid bounds
    private static func isValidGridPosition(_ position: GridPosition) -> Bool {
        return position.row.isValidGridIndex && position.col.isValidGridIndex
    }
}