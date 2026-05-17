//
//  SpecialBlockTests.swift
//  LeavesOfBlocksTests
//
//  Tests for GameLogic placement and scoring of the special power-up blocks
//  (.horizontalClear / .verticalClear / .areaClear).
//

import Testing
@testable import LeavesOfBlocks

// MARK: - Helpers

private func filledGrid() -> [[GridCell]] {
    var grid = GameLogic.createEmptyGrid()
    for row in 0..<8 {
        for col in 0..<8 {
            grid[row][col].isFilled = true
            grid[row][col].color = .blue
        }
    }
    return grid
}

private func emptyGrid() -> [[GridCell]] {
    GameLogic.createEmptyGrid()
}

// MARK: - Horizontal Clear

@Suite("GameLogic .horizontalClear")
struct HorizontalClearTests {
    @Test
    func clearsTheTargetRow() {
        var grid = filledGrid()
        let block = BlockShape.horizontalClearShape

        GameLogic.placeBlock(block, at: GridPosition(row: 3, col: 4), in: &grid)

        for col in 0..<8 {
            #expect(!grid[3][col].isFilled)
        }
    }

    @Test
    func leavesOtherRowsUntouched() {
        var grid = filledGrid()
        GameLogic.placeBlock(BlockShape.horizontalClearShape, at: GridPosition(row: 3, col: 4), in: &grid)

        for row in [0, 1, 2, 4, 5, 6, 7] {
            for col in 0..<8 {
                #expect(grid[row][col].isFilled)
            }
        }
    }

    @Test
    func canPlaceAnywhereOnGrid() {
        let grid = filledGrid()
        for row in 0..<8 {
            for col in 0..<8 {
                #expect(GameLogic.canPlaceBlock(
                    BlockShape.horizontalClearShape,
                    at: GridPosition(row: row, col: col),
                    in: grid
                ))
            }
        }
    }
}

// MARK: - Vertical Clear

@Suite("GameLogic .verticalClear")
struct VerticalClearTests {
    @Test
    func clearsTheTargetColumn() {
        var grid = filledGrid()
        GameLogic.placeBlock(BlockShape.verticalClearShape, at: GridPosition(row: 5, col: 2), in: &grid)

        for row in 0..<8 {
            #expect(!grid[row][2].isFilled)
        }
    }

    @Test
    func leavesOtherColumnsUntouched() {
        var grid = filledGrid()
        GameLogic.placeBlock(BlockShape.verticalClearShape, at: GridPosition(row: 5, col: 2), in: &grid)

        for row in 0..<8 {
            for col in [0, 1, 3, 4, 5, 6, 7] {
                #expect(grid[row][col].isFilled)
            }
        }
    }
}

// MARK: - Area Clear

@Suite("GameLogic .areaClear")
struct AreaClearTests {
    @Test
    func clearsThreeByThreeAroundCenter() {
        var grid = filledGrid()
        GameLogic.placeBlock(BlockShape.areaClearShape, at: GridPosition(row: 3, col: 3), in: &grid)

        for row in 2...4 {
            for col in 2...4 {
                #expect(!grid[row][col].isFilled)
            }
        }
    }

    @Test
    func ignoresOutOfBoundsOffsets() {
        // Place at corner (0, 0). The 3x3 mask would extend into negative
        // indices on the top/left; the call must clear what's in-bounds and
        // not crash.
        var grid = filledGrid()
        GameLogic.placeBlock(BlockShape.areaClearShape, at: GridPosition(row: 0, col: 0), in: &grid)

        for row in 0...1 {
            for col in 0...1 {
                #expect(!grid[row][col].isFilled)
            }
        }
        // (2,0) and (0,2) are still filled.
        #expect(grid[2][0].isFilled)
        #expect(grid[0][2].isFilled)
    }

    @Test
    func leavesUnaffectedCellsAlone() {
        var grid = filledGrid()
        GameLogic.placeBlock(BlockShape.areaClearShape, at: GridPosition(row: 4, col: 4), in: &grid)

        // Cells outside the 3x3 mask remain filled.
        #expect(grid[0][0].isFilled)
        #expect(grid[7][7].isFilled)
        #expect(grid[2][4].isFilled)
        #expect(grid[6][4].isFilled)
    }
}

// MARK: - Score for Special Blocks

@Suite("GameLogic.calculateBlockScore for special blocks")
struct SpecialBlockScoreTests {
    @Test
    func horizontalClearScoresOneLine() {
        let score = GameLogic.calculateBlockScore(block: BlockShape.horizontalClearShape)
        #expect(score == AppConfiguration.GameRules.lineScore)
    }

    @Test
    func verticalClearScoresOneLine() {
        let score = GameLogic.calculateBlockScore(block: BlockShape.verticalClearShape)
        #expect(score == AppConfiguration.GameRules.lineScore)
    }

    @Test
    func areaClearScoresMoreThanASingleLine() {
        let areaScore = GameLogic.calculateBlockScore(block: BlockShape.areaClearShape)
        let lineScore = GameLogic.calculateBlockScore(block: BlockShape.horizontalClearShape)
        #expect(areaScore > lineScore)
    }
}

// MARK: - canAllBlocksBePlaced

@Suite("GameLogic.canAllBlocksBePlaced")
struct CanAllBlocksBePlacedTests {
    @Test
    func emptyGridFitsAnyTrioOfStandardBlocks() {
        let blocks = Array(BlockShape.allShapes.prefix(3))
        #expect(GameLogic.canAllBlocksBePlaced(blocks, in: emptyGrid()))
    }

    @Test
    func fullGridCannotFitAnyNormalBlock() {
        let block = BlockShape.allShapes[0]
        #expect(!GameLogic.canAllBlocksBePlaced([block], in: filledGrid()))
    }

    @Test
    func emptyArrayIsTriviallyPlaceable() {
        #expect(GameLogic.canAllBlocksBePlaced([], in: emptyGrid()))
    }
}
