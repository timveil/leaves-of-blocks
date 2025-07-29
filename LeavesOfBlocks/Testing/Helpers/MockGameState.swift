import Foundation
import SwiftUI

// MARK: - Mock Objects for Testing

#if DEBUG || TESTING

// MARK: - Mock Game State

class MockGameState: GameState {
    
    // MARK: - Test Properties
    
    var shouldFailBlockPlacement = false
    var forceGameOver = false
    var mockScore = 0
    var mockLinesCleared = 0
    
    // MARK: - Overridden Methods
    
    override func canPlaceBlock(_ block: BlockShape, at gridPosition: GridPosition) -> Bool {
        if shouldFailBlockPlacement {
            return false
        }
        return super.canPlaceBlock(block, at: gridPosition)
    }
    
    override func placeBlock(_ block: BlockShape, at gridPosition: GridPosition) {
        if shouldFailBlockPlacement {
            return
        }
        super.placeBlock(block, at: gridPosition)
    }
    
    override func checkGameOver() {
        if forceGameOver {
            isGameOver = true
            return
        }
        super.checkGameOver()
    }
}

// MARK: - Test Data Generators

struct TestDataGenerator {
    
    // MARK: - Grid Generation
    
    static func createEmptyGrid() -> [[GridCell]] {
        return Array(repeating: Array(repeating: GridCell(), count: GameTheme.GameConfig.gridSize), count: GameTheme.GameConfig.gridSize)
    }
    
    static func createFullGrid() -> [[GridCell]] {
        var grid = createEmptyGrid()
        for row in 0..<GameTheme.GameConfig.gridSize {
            for col in 0..<GameTheme.GameConfig.gridSize {
                grid[row][col].isFilled = true
                grid[row][col].color = .blue
            }
        }
        return grid
    }
    
    static func createGridWithFullRow(at row: Int) -> [[GridCell]] {
        var grid = createEmptyGrid()
        for col in 0..<GameTheme.GameConfig.gridSize {
            grid[row][col].isFilled = true
            grid[row][col].color = .red
        }
        return grid
    }
    
    static func createGridWithFullColumn(at col: Int) -> [[GridCell]] {
        var grid = createEmptyGrid()
        for row in 0..<GameTheme.GameConfig.gridSize {
            grid[row][col].isFilled = true
            grid[row][col].color = .green
        }
        return grid
    }
    
    // MARK: - Block Generation
    
    static func createSingleBlock() -> BlockShape {
        return BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .blue)
    }
    
    static func createLShapeBlock() -> BlockShape {
        return BlockShape(
            positions: [
                GridPosition(row: 0, col: 0),
                GridPosition(row: 1, col: 0),
                GridPosition(row: 2, col: 0),
                GridPosition(row: 2, col: 1)
            ],
            color: .red
        )
    }
    
    static func createRandomBlock() -> BlockShape {
        return BlockShape.allShapes.randomElement() ?? createSingleBlock()
    }
    
    // MARK: - Game State Generation
    
    static func createGameStateWithScore(_ score: Int) -> GameState {
        let gameState = GameState()
        gameState.score = score
        return gameState
    }
    
    static func createGameStateWithFullRow() -> GameState {
        let gameState = GameState()
        gameState.grid = createGridWithFullRow(at: 0)
        return gameState
    }
}

#endif