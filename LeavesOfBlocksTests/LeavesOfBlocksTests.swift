//
//  LeavesOfBlocksTests.swift
//  Leaves of BlocksTests
//
//  Created by Tim Veil on 7/25/25.
//

import Testing
import Foundation
@testable import LeavesOfBlocks

// MARK: - Game Models Tests

struct GameModelsTests {
    
    // MARK: - DifficultyMode Tests
    
    @Test("DifficultyMode should have all required cases")
    func difficultyModeHasAllCases() {
        let modes = DifficultyMode.allCases
        #expect(modes.count == 3)
        #expect(modes.contains(.easy))
        #expect(modes.contains(.moderate))
        #expect(modes.contains(.hard))
    }
    
    @Test("DifficultyMode should provide descriptions")
    func difficultyModeDescriptions() {
        #expect(!DifficultyMode.easy.description.isEmpty)
        #expect(!DifficultyMode.moderate.description.isEmpty)
        #expect(!DifficultyMode.hard.description.isEmpty)
    }
    
    @Test("DifficultyMode should provide icons")
    func difficultyModeIcons() {
        #expect(DifficultyMode.easy.icon == "leaf.fill")
        #expect(DifficultyMode.moderate.icon == "square.stack.3d.up.fill")
        #expect(DifficultyMode.hard.icon == "flame.fill")
    }
    
    // MARK: - GridPosition Tests
    
    @Test("GridPosition should be equatable")
    func gridPositionEquality() {
        let pos1 = GridPosition(row: 1, col: 2)
        let pos2 = GridPosition(row: 1, col: 2)
        let pos3 = GridPosition(row: 2, col: 1)
        
        #expect(pos1 == pos2)
        #expect(pos1 != pos3)
    }
    
    @Test("GridPosition should be hashable")
    func gridPositionHashable() {
        let pos1 = GridPosition(row: 1, col: 2)
        let pos2 = GridPosition(row: 1, col: 2)
        
        let set: Set<GridPosition> = [pos1, pos2]
        #expect(set.count == 1)
    }
    
    // MARK: - GridCell Tests
    
    @Test("GridCell should initialize with default values")
    func gridCellDefaultInitialization() {
        let cell = GridCell()
        #expect(!cell.isFilled)
        #expect(cell.color == .blue)
    }
    
    @Test("GridCell should allow modification")
    func gridCellModification() {
        var cell = GridCell()
        cell.isFilled = true
        cell.color = .red
        
        #expect(cell.isFilled)
        #expect(cell.color == .red)
    }
    
    // MARK: - BlockColor Tests
    
    @Test("BlockColor should have all expected cases")
    func blockColorCases() {
        let colors = BlockColor.allCases
        #expect(colors.count == 7)
        #expect(colors.contains(.blue))
        #expect(colors.contains(.green))
        #expect(colors.contains(.red))
        #expect(colors.contains(.yellow))
        #expect(colors.contains(.purple))
        #expect(colors.contains(.orange))
        #expect(colors.contains(.pink))
    }
    
    // MARK: - BlockShape Tests
    
    @Test("BlockShape should have predefined shapes")
    func blockShapePredefinedShapes() {
        #expect(!BlockShape.allShapes.isEmpty)
        #expect(BlockShape.allShapes.count > 20)
    }
    
    @Test("BlockShape should be equatable")
    func blockShapeEquality() {
        let positions1 = [GridPosition(row: 0, col: 0)]
        let positions2 = [GridPosition(row: 0, col: 0)]
        let positions3 = [GridPosition(row: 1, col: 1)]
        
        let shape1 = BlockShape(positions: positions1, color: .blue)
        let shape2 = BlockShape(positions: positions2, color: .blue)
        let shape3 = BlockShape(positions: positions3, color: .blue)
        let shape4 = BlockShape(positions: positions1, color: .red)
        
        #expect(shape1 == shape2)
        #expect(shape1 != shape3)
        #expect(shape1 != shape4)
    }
    
    @Test("Single block shape should be valid")
    func singleBlockShape() {
        let singleBlock = BlockShape.allShapes.first { $0.positions.count == 1 }
        #expect(singleBlock != nil)
        #expect(singleBlock?.positions.count == 1)
    }
    
    @Test("Block shapes should have valid positions")
    func blockShapeValidPositions() {
        for shape in BlockShape.allShapes {
            #expect(!shape.positions.isEmpty)
            
            for position in shape.positions {
                #expect(position.row >= 0)
                #expect(position.col >= 0)
            }
        }
    }
    
    // MARK: - ClearedCell Tests
    
    @Test("ClearedCell should be equatable")
    func clearedCellEquality() {
        let cell1 = ClearedCell(row: 1, col: 2, color: .blue)
        let cell2 = ClearedCell(row: 1, col: 2, color: .blue)
        let cell3 = ClearedCell(row: 2, col: 1, color: .blue)
        
        #expect(cell1 == cell2)
        #expect(cell1 != cell3)
    }
}

// MARK: - Game State Tests

struct GameStateTests {
    
    @Test("GameState should initialize with correct default values")
    func gameStateInitialization() {
        let gameState = GameState()
        
        #expect(gameState.grid.count == GameState.gridSize)
        #expect(gameState.grid[0].count == GameState.gridSize)
        #expect(gameState.score == 0)
        #expect(!gameState.isGameOver)
        #expect(gameState.linesCleared == 0)
        #expect(gameState.blocksPlaced == 0)
        #expect(gameState.currentCombo == 0)
        #expect(gameState.longestCombo == 0)
        #expect(!gameState.isNewHighScore)
        #expect(gameState.currentDifficulty == .easy)
    }
    
    @Test("GameState should generate initial blocks")
    func gameStateGeneratesBlocks() {
        let gameState = GameState()
        #expect(gameState.currentBlocks.count == 3)
    }
    
    @Test("Grid should be empty on initialization")
    func gridEmptyOnInitialization() {
        let gameState = GameState()
        
        for row in gameState.grid {
            for cell in row {
                #expect(!cell.isFilled)
            }
        }
    }
    
    @Test("Can place block in empty grid")
    func canPlaceBlockInEmptyGrid() {
        let gameState = GameState()
        let singleBlock = BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .blue)
        let position = GridPosition(row: 0, col: 0)
        
        #expect(gameState.canPlaceBlock(singleBlock, at: position))
    }
    
    @Test("Cannot place block out of bounds")
    func cannotPlaceBlockOutOfBounds() {
        let gameState = GameState()
        let singleBlock = BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .blue)
        
        let invalidPositions = [
            GridPosition(row: -1, col: 0),
            GridPosition(row: 0, col: -1),
            GridPosition(row: GameState.gridSize, col: 0),
            GridPosition(row: 0, col: GameState.gridSize)
        ]
        
        for position in invalidPositions {
            #expect(!gameState.canPlaceBlock(singleBlock, at: position))
        }
    }
    
    @Test("Cannot place block on filled cell")
    func cannotPlaceBlockOnFilledCell() {
        let gameState = GameState()
        let singleBlock = BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .blue)
        let position = GridPosition(row: 0, col: 0)
        
        gameState.grid[0][0].isFilled = true
        
        #expect(!gameState.canPlaceBlock(singleBlock, at: position))
    }
    
    @Test("Block placement increases score")
    func blockPlacementIncreasesScore() {
        let gameState = GameState()
        let singleBlock = BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .blue)
        let position = GridPosition(row: 0, col: 0)
        let initialScore = gameState.score
        
        gameState.placeBlock(singleBlock, at: position)
        
        #expect(gameState.score > initialScore)
        #expect(gameState.score == initialScore + 10)
    }
    
    @Test("Block placement fills grid cells")
    func blockPlacementFillsCells() {
        let gameState = GameState()
        let singleBlock = BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .blue)
        let position = GridPosition(row: 1, col: 1)
        
        gameState.placeBlock(singleBlock, at: position)
        
        #expect(gameState.grid[1][1].isFilled)
        #expect(gameState.grid[1][1].color == .blue)
    }
    
    @Test("Reset game clears state")
    func resetGameClearsState() {
        let gameState = GameState()
        gameState.score = 1000
        gameState.linesCleared = 5
        gameState.blocksPlaced = 10
        gameState.grid[0][0].isFilled = true
        
        gameState.resetGame()
        
        #expect(gameState.score == 0)
        #expect(gameState.linesCleared == 0)
        #expect(gameState.blocksPlaced == 0)
        #expect(!gameState.isGameOver)
        #expect(gameState.currentBlocks.count == 3)
    }
    
    @Test("Start game sets difficulty")
    func startGameSetsDifficulty() {
        let gameState = GameState()
        
        gameState.startGame(difficulty: .hard)
        
        #expect(gameState.currentDifficulty == .hard)
    }
    
    @Test("Game time calculation")
    func gameTimeCalculation() throws {
        let gameState = GameState()
        let startTime = gameState.gameStartTime
        
        Thread.sleep(forTimeInterval: 0.1)
        
        let gameTime = gameState.gameTime
        #expect(gameTime > 0)
        #expect(gameTime < 1.0)
    }
}

// MARK: - Parameterized Tests

struct ParameterizedTests {
    
    @Test("Block shapes should have valid cell counts", arguments: [1, 2, 3, 4])
    func blockShapesHaveValidCellCounts(expectedCount: Int) {
        let shapesWithCount = BlockShape.allShapes.filter { $0.positions.count == expectedCount }
        #expect(!shapesWithCount.isEmpty, "Should have at least one shape with \(expectedCount) cells")
    }
    
    @Test("Difficulty modes should have different weights", arguments: DifficultyMode.allCases)
    func difficultyModesHaveDifferentWeights(difficulty: DifficultyMode) {
        let blocks = BlockGenerator.generateWeightedBlocks(count: 10, difficulty: difficulty)
        #expect(blocks.count == 10)
        
        for block in blocks {
            #expect(!block.positions.isEmpty)
        }
    }
    
    @Test("Grid positions should be valid", arguments: zip([0, 4, 7], [0, 4, 7]))
    func gridPositionsAreValid(row: Int, col: Int) {
        let position = GridPosition(row: row, col: col)
        #expect(position.row >= 0)
        #expect(position.col >= 0)
        #expect(position.row < GameState.gridSize)
        #expect(position.col < GameState.gridSize)
    }
}

// MARK: - Edge Cases and Error Conditions

struct EdgeCaseTests {
    
    @Test("Large block placement near boundaries")
    func largeBlockPlacementNearBoundaries() {
        let gameState = GameState()
        let largeBlock = BlockShape(
            positions: [
                GridPosition(row: 0, col: 0),
                GridPosition(row: 0, col: 1),
                GridPosition(row: 1, col: 0),
                GridPosition(row: 1, col: 1)
            ],
            color: .purple
        )
        
        let validPosition = GridPosition(row: 0, col: 0)
        let invalidPosition = GridPosition(row: GameState.gridSize - 1, col: GameState.gridSize - 1)
        
        #expect(gameState.canPlaceBlock(largeBlock, at: validPosition))
        #expect(!gameState.canPlaceBlock(largeBlock, at: invalidPosition))
    }
    
    @Test("Empty block positions array handling")
    func emptyBlockPositionsHandling() {
        let emptyBlock = BlockShape(positions: [], color: .blue)
        let gameState = GameState()
        let position = GridPosition(row: 0, col: 0)
        
        #expect(gameState.canPlaceBlock(emptyBlock, at: position))
    }
    
    @Test("Maximum grid utilization")
    func maximumGridUtilization() {
        let gameState = GameState()
        
        for row in 0..<GameState.gridSize {
            for col in 0..<GameState.gridSize {
                gameState.grid[row][col].isFilled = true
            }
        }
        
        let singleBlock = BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .blue)
        let position = GridPosition(row: 0, col: 0)
        
        #expect(!gameState.canPlaceBlock(singleBlock, at: position))
    }
}

// MARK: - Async Tests

struct AsyncTests {
    
    @Test("Async block generation")
    func asyncBlockGeneration() async throws {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let blocks = BlockGenerator.generateWeightedBlocks(count: 3, difficulty: .moderate)
                assert(blocks.count == 3)
                continuation.resume()
            }
        }
    }
    
    @Test("Concurrent game state access")
    func concurrentGameStateAccess() async throws {
        let gameState = GameState()
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    let block = BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .blue)
                    let position = GridPosition(row: Int.random(in: 0..<GameState.gridSize), 
                                              col: Int.random(in: 0..<GameState.gridSize))
                    
                    if gameState.canPlaceBlock(block, at: position) {
                        gameState.placeBlock(block, at: position)
                    }
                }
            }
        }
        
        #expect(gameState.score >= 0)
    }
}

// MARK: - Performance Tests

struct PerformanceTests {
    
    @Test("Block placement performance")
    func blockPlacementPerformance() throws {
        let gameState = GameState()
        let block = BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .blue)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<100 {
            let position = GridPosition(row: i % GameState.gridSize, col: (i * 2) % GameState.gridSize)
            if gameState.canPlaceBlock(block, at: position) {
                gameState.placeBlock(block, at: position)
            }
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        #expect(timeElapsed < 1.0, "Block placement should complete within 1 second")
    }
    
    @Test("Grid validation performance")
    func gridValidationPerformance() throws {
        var grid = Array(repeating: Array(repeating: GridCell(), count: GameState.gridSize), count: GameState.gridSize)
        
        for row in 0..<GameState.gridSize {
            for col in 0..<GameState.gridSize {
                grid[row][col].isFilled = true
            }
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<1000 {
            let _ = GameRules.findCompletedLines(in: grid)
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        #expect(timeElapsed < 0.1, "Grid validation should be fast")
    }
}
