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

    @Test("A special block doesn't count toward the empty-cell requirement")
    func specialBlockDoesNotConsumeAnEmptyCellInTheFastCheck() {
        // Exactly one empty cell. A horizontalClear special can go anywhere
        // — it clears rather than occupies (canPlaceBlockInline only checks
        // isValidGridPosition for specials, no occupancy check at all) — so
        // pairing it with a single normal 1-cell block that fits the one
        // empty cell should be jointly placeable. The special's `.positions`
        // array is a one-entry placeholder, not a real occupancy
        // requirement, so it must not count toward "cells needed."
        var grid = filledGrid()
        grid[0][0].isFilled = false

        let singleCell = BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .red)
        let blocks = [BlockShape.horizontalClearShape, singleCell]

        #expect(GameLogic.canAllBlocksBePlaced(blocks, in: grid))
    }

    @Test("A special placed first can create room a normal block doesn't have on its own")
    func specialClearingUnlocksAFollowingNormalBlock() {
        // Only one empty cell (3, 3) exists anywhere — nowhere near row 0,
        // which is fully filled. A 2-cell horizontal domino has zero valid
        // positions on this grid as given (it needs two *adjacent* empty
        // cells, and there's only one empty cell, period). But clearing row
        // 0 with a horizontalClear opens up 8 contiguous empty cells,
        // trivially fitting the domino afterward. The search has to
        // actually try the special — and credit what it clears — before
        // concluding the domino can't fit; sorting by block size alone
        // (a special's `.positions` placeholder always reports 1, so it
        // naturally sorts after a 2-cell block) would try the domino
        // against the untouched board first and give up too early.
        var grid = filledGrid()
        grid[3][3].isFilled = false

        let domino = BlockShape(
            positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1)],
            color: .red
        )
        let blocks = [domino, BlockShape.horizontalClearShape]

        #expect(GameLogic.canAllBlocksBePlaced(blocks, in: grid))
    }
}
