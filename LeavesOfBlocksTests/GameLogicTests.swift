//
//  GameLogicTests.swift
//  LeavesOfBlocksTests
//
//  Created by Claude on 11/27/25.
//

import XCTest
@testable import LeavesOfBlocks

// MARK: - Grid Creation Tests

final class GridCreationTests: XCTestCase {

    func testCreateEmptyGridReturns8x8Grid() {
        let grid = GameLogic.createEmptyGrid()

        XCTAssertEqual(grid.count, 8)
        for row in grid {
            XCTAssertEqual(row.count, 8)
        }
    }

    func testCreateEmptyGridAllCellsUnfilled() {
        let grid = GameLogic.createEmptyGrid()

        for row in grid {
            for cell in row {
                XCTAssertFalse(cell.isFilled)
            }
        }
    }
}

// MARK: - Block Placement Validation Tests

final class BlockPlacementValidationTests: XCTestCase {

    func testCanPlaceBlockAtValidPosition() {
        let grid = GameLogic.createEmptyGrid()
        let block = BlockShape.allShapes[0]

        let canPlace = GameLogic.canPlaceBlock(block, at: GridPosition(row: 0, col: 0), in: grid)

        XCTAssertTrue(canPlace)
    }

    func testCanPlaceBlockAtCenterOfGrid() {
        let grid = GameLogic.createEmptyGrid()
        let block = BlockShape.allShapes[0]

        let canPlace = GameLogic.canPlaceBlock(block, at: GridPosition(row: 4, col: 4), in: grid)

        XCTAssertTrue(canPlace)
    }

    func testCannotPlaceBlockOutOfBoundsNegativeRow() {
        let grid = GameLogic.createEmptyGrid()
        let block = BlockShape.allShapes[0]

        let canPlace = GameLogic.canPlaceBlock(block, at: GridPosition(row: -1, col: 0), in: grid)

        XCTAssertFalse(canPlace)
    }

    func testCannotPlaceBlockOutOfBoundsNegativeCol() {
        let grid = GameLogic.createEmptyGrid()
        let block = BlockShape.allShapes[0]

        let canPlace = GameLogic.canPlaceBlock(block, at: GridPosition(row: 0, col: -1), in: grid)

        XCTAssertFalse(canPlace)
    }

    func testCannotPlaceBlockOutOfBoundsTooLargeRow() {
        let grid = GameLogic.createEmptyGrid()
        let block = BlockShape.allShapes[0]

        let canPlace = GameLogic.canPlaceBlock(block, at: GridPosition(row: 8, col: 0), in: grid)

        XCTAssertFalse(canPlace)
    }

    func testCannotPlaceBlockOutOfBoundsTooLargeCol() {
        let grid = GameLogic.createEmptyGrid()
        let block = BlockShape.allShapes[0]

        let canPlace = GameLogic.canPlaceBlock(block, at: GridPosition(row: 0, col: 8), in: grid)

        XCTAssertFalse(canPlace)
    }

    func testCannotPlaceBlockOnFilledCell() {
        var grid = GameLogic.createEmptyGrid()
        grid[0][0].isFilled = true
        let block = BlockShape.allShapes[0]

        let canPlace = GameLogic.canPlaceBlock(block, at: GridPosition(row: 0, col: 0), in: grid)

        XCTAssertFalse(canPlace)
    }
}

// MARK: - Block Placement Tests

final class BlockPlacementTests: XCTestCase {

    func testPlaceBlockFillsCell() {
        var grid = GameLogic.createEmptyGrid()
        let block = BlockShape.allShapes[0]

        GameLogic.placeBlock(block, at: GridPosition(row: 0, col: 0), in: &grid)

        // Check that at least the origin cell is filled
        XCTAssertTrue(grid[0][0].isFilled)
    }

    func testPlaceBlockSetsColor() {
        var grid = GameLogic.createEmptyGrid()
        let block = BlockShape.allShapes[0]

        GameLogic.placeBlock(block, at: GridPosition(row: 0, col: 0), in: &grid)

        XCTAssertEqual(grid[0][0].color, block.color)
    }
}

// MARK: - Line Clearing Tests

final class LineClearingTests: XCTestCase {

    func testClearCompletedLinesDetectsFullRow() {
        var grid = GameLogic.createEmptyGrid()
        // Fill entire first row
        for col in 0..<8 {
            grid[0][col].isFilled = true
            grid[0][col].color = .red
        }

        let result = GameLogic.clearCompletedLines(in: &grid)

        XCTAssertTrue(result.clearedRows.contains(0))
        XCTAssertEqual(result.clearedCells.count, 8)
    }

    func testClearCompletedLinesDetectsFullColumn() {
        var grid = GameLogic.createEmptyGrid()
        // Fill entire first column
        for row in 0..<8 {
            grid[row][0].isFilled = true
            grid[row][0].color = .blue
        }

        let result = GameLogic.clearCompletedLines(in: &grid)

        XCTAssertTrue(result.clearedCols.contains(0))
        XCTAssertEqual(result.clearedCells.count, 8)
    }

    func testClearCompletedLinesDoesNotClearIncompleteRow() {
        var grid = GameLogic.createEmptyGrid()
        // Fill 7 of 8 cells in row
        for col in 0..<7 {
            grid[0][col].isFilled = true
        }

        let result = GameLogic.clearCompletedLines(in: &grid)

        XCTAssertTrue(result.clearedRows.isEmpty)
        XCTAssertTrue(result.clearedCells.isEmpty)
    }

    func testClearCompletedLinesHandlesRowAndColumnCombo() {
        var grid = GameLogic.createEmptyGrid()
        // Fill first row
        for col in 0..<8 {
            grid[0][col].isFilled = true
            grid[0][col].color = .red
        }
        // Fill first column
        for row in 0..<8 {
            grid[row][0].isFilled = true
            grid[row][0].color = .blue
        }

        let result = GameLogic.clearCompletedLines(in: &grid)

        // Both row 0 and column 0 should be cleared
        XCTAssertTrue(result.clearedRows.contains(0))
        XCTAssertTrue(result.clearedCols.contains(0))
        // 8 from row + 7 from column (one cell shared)
        XCTAssertEqual(result.clearedCells.count, 15)
    }
}

// MARK: - Score Calculation Tests

final class ScoreCalculationTests: XCTestCase {

    func testCalculateBlockScoreReturnsTenPerCell() {
        let singleCellBlock = BlockShape.allShapes[0]

        let score = GameLogic.calculateBlockScore(block: singleCellBlock)

        XCTAssertEqual(score, singleCellBlock.positions.count * 10)
    }

    func testCalculateLineScoreForSingleRow() {
        let score = GameLogic.calculateLineScore(clearedRows: 1, clearedCols: 0)

        XCTAssertEqual(score, 100)
    }

    func testCalculateLineScoreForSingleColumn() {
        let score = GameLogic.calculateLineScore(clearedRows: 0, clearedCols: 1)

        XCTAssertEqual(score, 100)
    }

    func testCalculateLineScoreWithComboBonus() {
        // 2 rows cleared = 200 base + 50 combo = 250
        let score = GameLogic.calculateLineScore(clearedRows: 2, clearedCols: 0)

        XCTAssertEqual(score, 250)
    }

    func testCalculateLineScoreWithMultipleComboBonus() {
        // 3 lines = 300 base + 100 combo (50 * 2) = 400
        let score = GameLogic.calculateLineScore(clearedRows: 2, clearedCols: 1)

        XCTAssertEqual(score, 400)
    }

    func testCalculateLineScoreReturnsZeroForNoLines() {
        let score = GameLogic.calculateLineScore(clearedRows: 0, clearedCols: 0)

        XCTAssertEqual(score, 0)
    }
}

// MARK: - Game Over Detection Tests

final class GameOverDetectionTests: XCTestCase {

    func testIsGameOverReturnsFalseWithEmptyGrid() {
        let grid = GameLogic.createEmptyGrid()
        let blocks = [BlockShape.allShapes[0]]

        let gameOver = GameLogic.isGameOver(currentBlocks: blocks, grid: grid)

        XCTAssertFalse(gameOver)
    }

    func testIsGameOverReturnsTrueWithNoBlocks() {
        let grid = GameLogic.createEmptyGrid()
        let blocks: [BlockShape] = []

        let gameOver = GameLogic.isGameOver(currentBlocks: blocks, grid: grid)

        XCTAssertTrue(gameOver)
    }

    func testIsGameOverReturnsTrueWhenGridFull() {
        var grid = GameLogic.createEmptyGrid()
        // Fill entire grid
        for row in 0..<8 {
            for col in 0..<8 {
                grid[row][col].isFilled = true
            }
        }
        let blocks = [BlockShape.allShapes[0]]

        let gameOver = GameLogic.isGameOver(currentBlocks: blocks, grid: grid)

        XCTAssertTrue(gameOver)
    }
}

// MARK: - Find Valid Positions Tests

final class FindValidPositionsTests: XCTestCase {

    func testFindValidPositionsOnEmptyGrid() {
        let grid = GameLogic.createEmptyGrid()
        let block = BlockShape.allShapes[0]

        let positions = GameLogic.findValidPositions(for: block, in: grid)

        // Should have many valid positions on empty grid
        XCTAssertFalse(positions.isEmpty)
    }

    func testFindValidPositionsWithPartiallyFilledGrid() {
        var grid = GameLogic.createEmptyGrid()
        grid[0][0].isFilled = true
        let block = BlockShape.allShapes[0]

        let positions = GameLogic.findValidPositions(for: block, in: grid)
        let positionsOnEmptyGrid = GameLogic.findValidPositions(for: block, in: GameLogic.createEmptyGrid())

        // Should have fewer positions than empty grid
        XCTAssertLessThan(positions.count, positionsOnEmptyGrid.count)
    }

    func testFindValidPositionsReturnsEmptyWhenNoValidPlacements() {
        var grid = GameLogic.createEmptyGrid()
        // Fill entire grid
        for row in 0..<8 {
            for col in 0..<8 {
                grid[row][col].isFilled = true
            }
        }
        let block = BlockShape.allShapes[0]

        let positions = GameLogic.findValidPositions(for: block, in: grid)

        XCTAssertTrue(positions.isEmpty)
    }
}
