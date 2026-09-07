//
//  GameLogicTests.swift
//  LeavesOfBlocksTests
//
//  Unit tests for the pure `GameLogic` static functions: grid creation,
//  placement validation, placement, line clearing, scoring, game-over,
//  and valid-position enumeration.
//

import Foundation
import Testing
@testable import LeavesOfBlocks

// MARK: - Helpers

private func filledGrid() -> [[GridCell]] {
    var grid = GameLogic.createEmptyGrid()
    for row in 0..<grid.count {
        for col in 0..<grid[row].count {
            grid[row][col].isFilled = true
        }
    }
    return grid
}

// MARK: - Grid Creation

@Suite("GameLogic.createEmptyGrid")
struct GridCreationTests {
    @Test("Returns an 8x8 grid")
    func returnsAn8x8Grid() {
        let grid = GameLogic.createEmptyGrid()
        #expect(grid.count == 8)
        for row in grid {
            #expect(row.count == 8)
        }
    }

    @Test("All cells start unfilled")
    func allCellsStartUnfilled() {
        let grid = GameLogic.createEmptyGrid()
        for row in grid {
            for cell in row {
                #expect(cell.isFilled == false)
            }
        }
    }
}

// MARK: - Block Placement Validation

@Suite("GameLogic.canPlaceBlock")
struct BlockPlacementValidationTests {
    @Test("Origin of empty grid is a valid placement")
    func originOfEmptyGridIsAValidPlacement() {
        let grid = GameLogic.createEmptyGrid()
        let block = BlockShape.allShapes[0]
        #expect(GameLogic.canPlaceBlock(block, at: GridPosition(row: 0, col: 0), in: grid))
    }

    @Test("Center of empty grid is a valid placement")
    func centerOfEmptyGridIsAValidPlacement() {
        let grid = GameLogic.createEmptyGrid()
        let block = BlockShape.allShapes[0]
        #expect(GameLogic.canPlaceBlock(block, at: GridPosition(row: 4, col: 4), in: grid))
    }

    @Test("Negative row is rejected")
    func negativeRowIsRejected() {
        let grid = GameLogic.createEmptyGrid()
        let block = BlockShape.allShapes[0]
        #expect(!GameLogic.canPlaceBlock(block, at: GridPosition(row: -1, col: 0), in: grid))
    }

    @Test("Negative column is rejected")
    func negativeColumnIsRejected() {
        let grid = GameLogic.createEmptyGrid()
        let block = BlockShape.allShapes[0]
        #expect(!GameLogic.canPlaceBlock(block, at: GridPosition(row: 0, col: -1), in: grid))
    }

    @Test("Row past the grid is rejected")
    func rowPastTheGridIsRejected() {
        let grid = GameLogic.createEmptyGrid()
        let block = BlockShape.allShapes[0]
        #expect(!GameLogic.canPlaceBlock(block, at: GridPosition(row: 8, col: 0), in: grid))
    }

    @Test("Column past the grid is rejected")
    func columnPastTheGridIsRejected() {
        let grid = GameLogic.createEmptyGrid()
        let block = BlockShape.allShapes[0]
        #expect(!GameLogic.canPlaceBlock(block, at: GridPosition(row: 0, col: 8), in: grid))
    }

    @Test("Cannot overlap a filled cell")
    func cannotOverlapAFilledCell() {
        var grid = GameLogic.createEmptyGrid()
        grid[0][0].isFilled = true
        let block = BlockShape.allShapes[0]
        #expect(!GameLogic.canPlaceBlock(block, at: GridPosition(row: 0, col: 0), in: grid))
    }
}

// MARK: - Block Placement

@Suite("GameLogic.placeBlock")
struct BlockPlacementTests {
    @Test("Placement fills the origin cell")
    func placementFillsTheOriginCell() {
        var grid = GameLogic.createEmptyGrid()
        let block = BlockShape.allShapes[0]
        GameLogic.placeBlock(block, at: GridPosition(row: 0, col: 0), in: &grid)
        #expect(grid[0][0].isFilled)
    }

    @Test("Placement copies the block color to placed cells")
    func placementCopiesTheBlockColorToPlacedCells() {
        var grid = GameLogic.createEmptyGrid()
        let block = BlockShape.allShapes[0]
        GameLogic.placeBlock(block, at: GridPosition(row: 0, col: 0), in: &grid)
        #expect(grid[0][0].color == block.color)
    }
}

// MARK: - Line Clearing

@Suite("GameLogic.clearCompletedLines")
struct LineClearingTests {
    @Test("Detects a full row")
    func detectsAFullRow() {
        var grid = GameLogic.createEmptyGrid()
        for col in 0..<8 {
            grid[0][col].isFilled = true
            grid[0][col].color = .red
        }

        let result = GameLogic.clearCompletedLines(in: &grid)

        #expect(result.clearedRows.contains(0))
        #expect(result.clearedCells.count == 8)
    }

    @Test("Detects a full column")
    func detectsAFullColumn() {
        var grid = GameLogic.createEmptyGrid()
        for row in 0..<8 {
            grid[row][0].isFilled = true
            grid[row][0].color = .blue
        }

        let result = GameLogic.clearCompletedLines(in: &grid)

        #expect(result.clearedCols.contains(0))
        #expect(result.clearedCells.count == 8)
    }

    @Test("An incomplete row is not cleared")
    func anIncompleteRowIsNotCleared() {
        var grid = GameLogic.createEmptyGrid()
        for col in 0..<7 {
            grid[0][col].isFilled = true
        }

        let result = GameLogic.clearCompletedLines(in: &grid)

        #expect(result.clearedRows.isEmpty)
        #expect(result.clearedCells.isEmpty)
    }

    @Test("Row + column combo: shared cell isn't double-counted")
    func rowPlusColumnComboSharedCellIsNotDoubleCounted() {
        var grid = GameLogic.createEmptyGrid()
        for col in 0..<8 {
            grid[0][col].isFilled = true
            grid[0][col].color = .red
        }
        for row in 0..<8 {
            grid[row][0].isFilled = true
            grid[row][0].color = .blue
        }

        let result = GameLogic.clearCompletedLines(in: &grid)

        #expect(result.clearedRows.contains(0))
        #expect(result.clearedCols.contains(0))
        // 8 from row + 7 from column (one cell shared)
        #expect(result.clearedCells.count == 15)
    }
}

// MARK: - Score Calculation

@Suite("GameLogic scoring")
struct ScoreCalculationTests {
    @Test("Block score is 10 points per cell")
    func blockScoreIs10PointsPerCell() {
        let block = BlockShape.allShapes[0]
        #expect(GameLogic.calculateBlockScore(block: block) == block.positions.count * 10)
    }

    @Test("Single cleared row scores 100")
    func singleClearedRowScores100() {
        #expect(GameLogic.calculateLineScore(clearedRows: 1, clearedCols: 0) == 100)
    }

    @Test("Single cleared column scores 100")
    func singleClearedColumnScores100() {
        #expect(GameLogic.calculateLineScore(clearedRows: 0, clearedCols: 1) == 100)
    }

    @Test("Two rows: 200 base + 50 combo = 250")
    func twoRows200BasePlus50Combo() {
        #expect(GameLogic.calculateLineScore(clearedRows: 2, clearedCols: 0) == 250)
    }

    @Test("Three lines: 300 base + 100 combo = 400")
    func threeLines300BasePlus100Combo() {
        #expect(GameLogic.calculateLineScore(clearedRows: 2, clearedCols: 1) == 400)
    }

    @Test("No lines cleared scores zero")
    func noLinesClearedScoresZero() {
        #expect(GameLogic.calculateLineScore(clearedRows: 0, clearedCols: 0) == 0)
    }
}

// MARK: - Game Over Detection

@Suite("GameLogic.isGameOver")
struct GameOverDetectionTests {
    @Test("Empty grid with a placeable block is not game over")
    func emptyGridWithAPlaceableBlockIsNotGameOver() {
        let grid = GameLogic.createEmptyGrid()
        let blocks = [BlockShape.allShapes[0]]
        #expect(!GameLogic.isGameOver(currentBlocks: blocks, grid: grid))
    }

    @Test("No blocks remaining is treated as game over")
    func noBlocksRemainingIsTreatedAsGameOver() {
        let grid = GameLogic.createEmptyGrid()
        #expect(GameLogic.isGameOver(currentBlocks: [], grid: grid))
    }

    @Test("Full grid is game over for any block")
    func fullGridIsGameOverForAnyBlock() {
        let grid = filledGrid()
        let blocks = [BlockShape.allShapes[0]]
        #expect(GameLogic.isGameOver(currentBlocks: blocks, grid: grid))
    }
}

// MARK: - Find Valid Positions

@Suite("GameLogic.findValidPositions")
struct FindValidPositionsTests {
    @Test("Empty grid yields many valid positions")
    func emptyGridYieldsManyValidPositions() {
        let grid = GameLogic.createEmptyGrid()
        let block = BlockShape.allShapes[0]
        #expect(!GameLogic.findValidPositions(for: block, in: grid).isEmpty)
    }

    @Test("Partially-filled grid has fewer valid positions than empty grid")
    func partiallyFilledGridHasFewerValidPositionsThanEmptyGrid() {
        var grid = GameLogic.createEmptyGrid()
        grid[0][0].isFilled = true
        let block = BlockShape.allShapes[0]

        let partial = GameLogic.findValidPositions(for: block, in: grid).count
        let empty = GameLogic.findValidPositions(for: block, in: GameLogic.createEmptyGrid()).count

        #expect(partial < empty)
    }

    @Test("Full grid returns no valid positions")
    func fullGridReturnsNoValidPositions() {
        let grid = filledGrid()
        let block = BlockShape.allShapes[0]
        #expect(GameLogic.findValidPositions(for: block, in: grid).isEmpty)
    }
}

// MARK: - Highlighted Cells

/// Direct coverage for the footprint resolver behind the hint highlight.
///
/// `HintTests` exercises it only through `findHint`, which always reports the
/// first scan-order placement — so every case there lands at the top-left and
/// the interior, mid-grid behavior went unpinned.
///
/// The other `GameLogic` members without direct tests are deliberate omissions:
/// `DifficultyPatternConfig.forDifficulty` is `private` and reachable only
/// through `randomlyFillGrid`, and `randomlyFillGrid` /
/// `fillGridWithGeometricPatterns` draw from the global RNG, so they admit
/// property assertions (fill stays under target, no line completed) rather
/// than examples. Neither is covered here.
@Suite("GameLogic.highlightedCells")
struct HighlightedCellsTests {
    private static let size = AppConfiguration.GameRules.gridSize

    @Test("A normal block's cells are its offsets translated by the position")
    func normalBlockCellsAreOffsetsTranslatedByThePosition() {
        // Given an L-shaped normal block and an interior placement
        let block = BlockShape(
            positions: [
                GridPosition(row: 0, col: 0),
                GridPosition(row: 1, col: 0),
                GridPosition(row: 1, col: 1)
            ],
            color: .blue
        )
        let position = GridPosition(row: 3, col: 4)

        // When the footprint is resolved
        let cells = GameLogic.highlightedCells(for: block, at: position)

        // Then every offset appears translated by the placement position
        #expect(Set(cells) == Set([
            GridPosition(row: 3, col: 4),
            GridPosition(row: 4, col: 4),
            GridPosition(row: 4, col: 5)
        ]))
    }

    @Test("A horizontal-clear block covers its whole row and nothing else")
    func horizontalClearCoversItsWholeRowAndNothingElse() {
        // Given a horizontal-clear block whose own footprint is a single cell
        let block = BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .red, type: .horizontalClear)
        let position = GridPosition(row: 5, col: 2)

        // When the footprint is resolved
        let cells = GameLogic.highlightedCells(for: block, at: position)

        // Then it is exactly row 5, regardless of the column placed in
        #expect(Set(cells) == Set((0..<Self.size).map { GridPosition(row: 5, col: $0) }))
    }

    @Test("A vertical-clear block covers its whole column and nothing else")
    func verticalClearCoversItsWholeColumnAndNothingElse() {
        // Given a vertical-clear block placed away from the first row
        let block = BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .red, type: .verticalClear)
        let position = GridPosition(row: 6, col: 3)

        // When the footprint is resolved
        let cells = GameLogic.highlightedCells(for: block, at: position)

        // Then it is exactly column 3, regardless of the row placed in
        #expect(Set(cells) == Set((0..<Self.size).map { GridPosition(row: $0, col: 3) }))
    }

    @Test("An area-clear block away from the edges covers the full 3x3 neighborhood")
    func areaClearAwayFromEdgesCoversTheFullNeighborhood() {
        // Given an area-clear block centered where no edge clips it
        let block = BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .red, type: .areaClear)
        let position = GridPosition(row: 4, col: 4)

        // When the footprint is resolved
        let cells = GameLogic.highlightedCells(for: block, at: position)

        // Then it is the center plus all eight neighbors
        let expected = Set((-1...1).flatMap { rowOffset in
            (-1...1).map { GridPosition(row: 4 + rowOffset, col: 4 + $0) }
        })
        #expect(Set(cells) == expected)
    }

    @Test("An area-clear block at a corner drops the cells outside the grid")
    func areaClearAtACornerDropsTheCellsOutsideTheGrid() {
        // Given an area-clear block centered on the bottom-right corner
        let block = BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .red, type: .areaClear)
        let last = Self.size - 1
        let position = GridPosition(row: last, col: last)

        // When the footprint is resolved
        let cells = GameLogic.highlightedCells(for: block, at: position)

        // Then only the in-bounds quadrant survives
        #expect(Set(cells) == Set([
            GridPosition(row: last - 1, col: last - 1),
            GridPosition(row: last - 1, col: last),
            GridPosition(row: last, col: last - 1),
            GridPosition(row: last, col: last)
        ]))
    }

    @Test("A special block's own shape does not widen its footprint")
    func specialBlockOwnShapeDoesNotWidenItsFootprint() {
        // Given a horizontal-clear block carrying a two-cell shape
        let block = BlockShape(
            positions: [GridPosition(row: 0, col: 0), GridPosition(row: 1, col: 0)],
            color: .red,
            type: .horizontalClear
        )

        // When the footprint is resolved
        let cells = GameLogic.highlightedCells(for: block, at: GridPosition(row: 2, col: 0))

        // Then the second shape row is not highlighted — only the placed row is
        #expect(cells.allSatisfy { $0.row == 2 })
    }
}
