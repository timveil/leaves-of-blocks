//
//  GameLogicTests.swift
//  LeavesOfBlocksTests
//
//  Created by Tim Veil on 7/25/25.
//

import Testing
import Foundation
@testable import LeavesOfBlocks

// MARK: - Game Rules Tests

struct GameRulesTests {
    
    // MARK: - Scoring Tests
    
    @Test("Calculate block placement score correctly")
    func calculateBlockPlacementScore() {
        let score1 = GameRules.calculateBlockPlacementScore(blockSize: 1)
        let score4 = GameRules.calculateBlockPlacementScore(blockSize: 4)
        
        #expect(score1 == 10)
        #expect(score4 == 40)
    }
    
    @Test("Calculate line clear score without combo")
    func calculateLineClearScoreWithoutCombo() {
        let score = GameRules.calculateLineClearScore(linesCleared: 1)
        #expect(score == 100)
    }
    
    @Test("Calculate line clear score with combo")
    func calculateLineClearScoreWithCombo() {
        let score2 = GameRules.calculateLineClearScore(linesCleared: 2)
        let score3 = GameRules.calculateLineClearScore(linesCleared: 3)
        
        #expect(score2 == 250) // 200 + 50 combo bonus
        #expect(score3 == 400) // 300 + 100 combo bonus
    }
    
    // MARK: - Line Detection Tests
    
    @Test("Find completed rows")
    func findCompletedRows() {
        var grid = TestDataGenerator.createEmptyGrid()
        
        // Fill row 2 completely
        for col in 0..<GameTheme.GameConfig.gridSize {
            grid[2][col].isFilled = true
        }
        
        let result = GameRules.findCompletedLines(in: grid)
        
        #expect(result.rows.contains(2))
        #expect(result.rows.count == 1)
        #expect(result.cols.isEmpty)
    }
    
    @Test("Find completed columns")
    func findCompletedColumns() {
        var grid = TestDataGenerator.createEmptyGrid()
        
        // Fill column 3 completely
        for row in 0..<GameTheme.GameConfig.gridSize {
            grid[row][3].isFilled = true
        }
        
        let result = GameRules.findCompletedLines(in: grid)
        
        #expect(result.cols.contains(3))
        #expect(result.cols.count == 1)
        #expect(result.rows.isEmpty)
    }
    
    @Test("Find multiple completed lines")
    func findMultipleCompletedLines() {
        var grid = TestDataGenerator.createEmptyGrid()
        
        // Fill row 0 and column 1
        for col in 0..<GameTheme.GameConfig.gridSize {
            grid[0][col].isFilled = true
        }
        for row in 0..<GameTheme.GameConfig.gridSize {
            grid[row][1].isFilled = true
        }
        
        let result = GameRules.findCompletedLines(in: grid)
        
        #expect(result.rows.contains(0))
        #expect(result.cols.contains(1))
        #expect(result.rows.count == 1)
        #expect(result.cols.count == 1)
    }
    
    @Test("No completed lines in empty grid")
    func noCompletedLinesInEmptyGrid() {
        let grid = TestDataGenerator.createEmptyGrid()
        let result = GameRules.findCompletedLines(in: grid)
        
        #expect(result.rows.isEmpty)
        #expect(result.cols.isEmpty)
    }
    
    @Test("No completed lines in partially filled grid")
    func noCompletedLinesInPartiallyFilledGrid() {
        var grid = TestDataGenerator.createEmptyGrid()
        
        // Fill some cells but not complete lines
        grid[0][0].isFilled = true
        grid[1][1].isFilled = true
        grid[2][2].isFilled = true
        
        let result = GameRules.findCompletedLines(in: grid)
        
        #expect(result.rows.isEmpty)
        #expect(result.cols.isEmpty)
    }
    
    // MARK: - Placement Validation Tests
    
    @Test("Can place block in valid position")
    func canPlaceBlockInValidPosition() {
        let grid = TestDataGenerator.createEmptyGrid()
        let block = TestDataGenerator.createSingleBlock()
        let position = GridPosition(row: 2, col: 3)
        
        #expect(GameRules.canPlaceBlock(block, at: position, in: grid))
    }
    
    @Test("Cannot place block out of bounds horizontally")
    func cannotPlaceBlockOutOfBoundsHorizontally() {
        let grid = TestDataGenerator.createEmptyGrid()
        let block = BlockShape(
            positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1)],
            color: .blue
        )
        let position = GridPosition(row: 0, col: GameTheme.GameConfig.gridSize - 1)
        
        #expect(!GameRules.canPlaceBlock(block, at: position, in: grid))
    }
    
    @Test("Cannot place block out of bounds vertically")
    func cannotPlaceBlockOutOfBoundsVertically() {
        let grid = TestDataGenerator.createEmptyGrid()
        let block = BlockShape(
            positions: [GridPosition(row: 0, col: 0), GridPosition(row: 1, col: 0)],
            color: .blue
        )
        let position = GridPosition(row: GameTheme.GameConfig.gridSize - 1, col: 0)
        
        #expect(!GameRules.canPlaceBlock(block, at: position, in: grid))
    }
    
    @Test("Cannot place block on filled cells")
    func cannotPlaceBlockOnFilledCells() {
        var grid = TestDataGenerator.createEmptyGrid()
        grid[1][1].isFilled = true
        
        let block = TestDataGenerator.createSingleBlock()
        let position = GridPosition(row: 1, col: 1)
        
        #expect(!GameRules.canPlaceBlock(block, at: position, in: grid))
    }
    
    @Test("Can place block partially overlapping with boundaries")
    func canPlaceBlockPartiallyOverlappingWithBoundaries() {
        let grid = TestDataGenerator.createEmptyGrid()
        let block = BlockShape(
            positions: [
                GridPosition(row: 0, col: 0),
                GridPosition(row: 0, col: 1),
                GridPosition(row: 1, col: 0)
            ],
            color: .green
        )
        let position = GridPosition(row: GameTheme.GameConfig.gridSize - 2, col: GameTheme.GameConfig.gridSize - 2)
        
        #expect(GameRules.canPlaceBlock(block, at: position, in: grid))
    }
    
    // MARK: - Game Over Detection Tests
    
    @Test("Game is not over when blocks can be placed")
    func gameIsNotOverWhenBlocksCanBePlaced() {
        let grid = TestDataGenerator.createEmptyGrid()
        let blocks = [TestDataGenerator.createSingleBlock()]
        
        #expect(!GameRules.isGameOver(currentBlocks: blocks, grid: grid))
    }
    
    @Test("Game is over when no blocks can be placed")
    func gameIsOverWhenNoBlocksCanBePlaced() {
        let grid = TestDataGenerator.createFullGrid()
        let blocks = [TestDataGenerator.createSingleBlock()]
        
        #expect(GameRules.isGameOver(currentBlocks: blocks, grid: grid))
    }
    
    @Test("Game is not over with empty blocks array")
    func gameIsNotOverWithEmptyBlocksArray() {
        let grid = TestDataGenerator.createFullGrid()
        let blocks: [BlockShape] = []
        
        // Empty blocks array should not be considered game over
        #expect(!GameRules.isGameOver(currentBlocks: blocks, grid: grid))
    }
    
    @Test("Game over with large blocks in nearly full grid")
    func gameOverWithLargeBlocksInNearlyFullGrid() {
        var grid = TestDataGenerator.createEmptyGrid()
        
        // Fill all cells except one
        for row in 0..<GameTheme.GameConfig.gridSize {
            for col in 0..<GameTheme.GameConfig.gridSize {
                if !(row == 0 && col == 0) {
                    grid[row][col].isFilled = true
                }
            }
        }
        
        let largeBlock = TestDataGenerator.createLShapeBlock()
        let blocks = [largeBlock]
        
        #expect(GameRules.isGameOver(currentBlocks: blocks, grid: grid))
    }
}

// MARK: - Block Generator Tests

struct BlockGeneratorTests {
    
    @Test("Generate correct number of blocks")
    func generateCorrectNumberOfBlocks() {
        let blocks = BlockGenerator.generateWeightedBlocks(count: 5, difficulty: .easy)
        #expect(blocks.count == 5)
    }
    
    @Test("Generated blocks have valid properties")
    func generatedBlocksHaveValidProperties() {
        let blocks = BlockGenerator.generateWeightedBlocks(count: 3, difficulty: .moderate)
        
        for block in blocks {
            #expect(!block.positions.isEmpty)
            #expect(BlockColor.allCases.contains(block.color))
        }
    }
    
    @Test("Easy difficulty favors smaller blocks", arguments: Array(0..<10))
    func easyDifficultyFavorsSmallerBlocks(iteration: Int) {
        let blocks = BlockGenerator.generateWeightedBlocks(count: 10, difficulty: .easy)
        let averageSize = Double(blocks.map { $0.positions.count }.reduce(0, +)) / Double(blocks.count)
        
        #expect(averageSize < 5.0, "Easy difficulty should favor smaller blocks")
    }
    
    @Test("Hard difficulty allows larger blocks", arguments: Array(0..<10))
    func hardDifficultyAllowsLargerBlocks(iteration: Int) {
        let blocks = BlockGenerator.generateWeightedBlocks(count: 10, difficulty: .hard)
        let hasLargeBlock = blocks.contains { $0.positions.count >= 5 }
        
        #expect(hasLargeBlock, "Hard difficulty should sometimes generate large blocks")
    }
    
    @Test("Block generation produces variety")
    func blockGenerationProducesVariety() {
        let blocks = BlockGenerator.generateWeightedBlocks(count: 20, difficulty: .moderate)
        let uniqueSizes = Set(blocks.map { $0.positions.count })
        
        #expect(uniqueSizes.count > 1, "Should generate blocks of different sizes")
    }
    
    @Test("Generated blocks match predefined shapes")
    func generatedBlocksMatchPredefinedShapes() {
        let blocks = BlockGenerator.generateWeightedBlocks(count: 5, difficulty: .easy)
        
        for block in blocks {
            let matchingShape = BlockShape.allShapes.first { shape in
                shape.positions == block.positions
            }
            #expect(matchingShape != nil, "Generated block should match a predefined shape")
        }
    }
}

// MARK: - Game State Validator Tests

struct GameStateValidatorTests {
    
    @Test("Valid game state passes validation")
    func validGameStatePassesValidation() {
        let gameState = GameState()
        let errors = GameStateValidator.validateGameState(gameState)
        
        #expect(errors.isEmpty)
    }
    
    @Test("Invalid grid size fails validation")
    func invalidGridSizeFailsValidation() {
        let gameState = GameState()
        gameState.grid = Array(repeating: Array(repeating: GridCell(), count: 5), count: 5)
        
        let errors = GameStateValidator.validateGameState(gameState)
        
        #expect(!errors.isEmpty)
        #expect(errors.contains { error in
            if case .invalidGridSize = error { return true }
            return false
        })
    }
    
    @Test("Invalid row size fails validation")
    func invalidRowSizeFailsValidation() {
        let gameState = GameState()
        gameState.grid[0] = Array(repeating: GridCell(), count: 5)
        
        let errors = GameStateValidator.validateGameState(gameState)
        
        #expect(!errors.isEmpty)
        #expect(errors.contains { error in
            if case .invalidRowSize = error { return true }
            return false
        })
    }
    
    @Test("Negative score fails validation")
    func negativeScoreFailsValidation() {
        let gameState = GameState()
        gameState.score = -100
        
        let errors = GameStateValidator.validateGameState(gameState)
        
        #expect(!errors.isEmpty)
        #expect(errors.contains { error in
            if case .negativeScore = error { return true }
            return false
        })
    }
    
    @Test("No current blocks without game over fails validation")
    func noCurrentBlocksWithoutGameOverFailsValidation() {
        let gameState = GameState()
        gameState.currentBlocks = []
        gameState.isGameOver = false
        
        let errors = GameStateValidator.validateGameState(gameState)
        
        #expect(!errors.isEmpty)
        #expect(errors.contains { error in
            if case .noCurrentBlocks = error { return true }
            return false
        })
    }
}

// MARK: - Performance Monitor Tests

struct PerformanceMonitorTests {
    
    @Test("Measure execution time accurately")
    func measureExecutionTimeAccurately() throws {
        let expectedDelay: TimeInterval = 0.1
        
        let (result, time) = PerformanceMonitor.measureExecutionTime {
            Thread.sleep(forTimeInterval: expectedDelay)
            return "test"
        }
        
        #expect(result == "test")
        #expect(time >= expectedDelay * 0.8) // Allow some tolerance
        #expect(time <= expectedDelay * 1.5) // Allow some tolerance
    }
    
    @Test("Measure fast operations")
    func measureFastOperations() throws {
        let (result, time) = PerformanceMonitor.measureExecutionTime {
            return Array(0..<1000).reduce(0, +)
        }
        
        #expect(result == 499500)
        #expect(time < 0.1)
    }
    
    @Test("Handle throwing operations")
    func handleThrowingOperations() throws {
        enum TestError: Error {
            case testError
        }
        
        let (_, time) = try PerformanceMonitor.measureExecutionTime {
            Thread.sleep(forTimeInterval: 0.05)
            throw TestError.testError
        }
        
        #expect(time > 0.04)
    }
}

// MARK: - Integration Tests

struct GameLogicIntegrationTests {
    
    @Test("Complete game flow with line clearing")
    func completeGameFlowWithLineClearing() {
        let gameState = GameState()
        
        // Fill a complete row manually
        for col in 0..<GameState.gridSize {
            gameState.grid[0][col].isFilled = true
            gameState.grid[0][col].color = .blue
        }
        
        let initialScore = gameState.score
        let clearResult = gameState.clearCompletedLines()
        
        #expect(clearResult.clearedRows.contains(0))
        #expect(gameState.score > initialScore)
        #expect(gameState.linesCleared > 0)
        
        // Verify row is cleared
        for col in 0..<GameState.gridSize {
            #expect(!gameState.grid[0][col].isFilled)
        }
    }
    
    @Test("Block placement triggers line clearing")
    func blockPlacementTriggersLineClearing() {
        let gameState = GameState()
        
        // Fill row 0 except last cell
        for col in 0..<GameState.gridSize - 1 {
            gameState.grid[0][col].isFilled = true
            gameState.grid[0][col].color = .red
        }
        
        let singleBlock = BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .blue)
        let position = GridPosition(row: 0, col: GameState.gridSize - 1)
        
        let initialLinesCleared = gameState.linesCleared
        gameState.placeBlock(singleBlock, at: position)
        
        #expect(gameState.linesCleared > initialLinesCleared)
        
        // Verify row is cleared
        for col in 0..<GameState.gridSize {
            #expect(!gameState.grid[0][col].isFilled)
        }
    }
    
    @Test("Game over detection after block placement")
    func gameOverDetectionAfterBlockPlacement() {
        let gameState = GameState()
        
        // Fill grid except one cell
        for row in 0..<GameState.gridSize {
            for col in 0..<GameState.gridSize {
                if !(row == 0 && col == 0) {
                    gameState.grid[row][col].isFilled = true
                }
            }
        }
        
        // Place a block that fills the last cell
        let singleBlock = BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .blue)
        let position = GridPosition(row: 0, col: 0)
        
        gameState.placeBlock(singleBlock, at: position)
        
        #expect(gameState.isGameOver)
    }
}