//
//  BoardLayoutTests.swift
//  LeavesOfBlocksTests
//
//  Crash repro / regression test for BoardView.findOptimalPlacement.
//
//  Production crash (2.0.3, iOS 26.4.2):
//      Swift runtime failure: Range requires lowerBound <= upperBound
//      at BoardView.findOptimalPlacement(for:nearPoint:) line 326
//
//  The clamping math built `startRow...endRow` where the two bounds were
//  clamped to the grid edges independently — a drag well above the grid
//  (nearPoint with a deeply negative y, possible because nearPoint is
//  grid-local and the view-coordinate off-screen check uses a separate
//  margin) produced `endRow < 0 < startRow` and tripped the runtime trap.
//

import Foundation
import Testing
@testable import LeavesOfBlocks

@Suite("BoardLayout.placementSearchRanges")
struct BoardLayoutSearchRangeTests {

    // MARK: - Happy Path

    @Test("Drag at grid center returns valid ranges around that cell")
    func dragAtCenterReturnsValidRanges() {
        let result = BoardLayout.placementSearchRanges(
            centerRow: 4, centerCol: 4,
            searchRadius: 2, gridSize: 8
        )
        #expect(result?.rows == 2...6)
        #expect(result?.cols == 2...6)
    }

    @Test("Drag near top-left clamps to grid origin")
    func dragNearTopLeftClampsToOrigin() {
        let result = BoardLayout.placementSearchRanges(
            centerRow: 0, centerCol: 0,
            searchRadius: 3, gridSize: 8
        )
        #expect(result?.rows == 0...3)
        #expect(result?.cols == 0...3)
    }

    @Test("Drag near bottom-right clamps to grid edge")
    func dragNearBottomRightClampsToEdge() {
        let result = BoardLayout.placementSearchRanges(
            centerRow: 7, centerCol: 7,
            searchRadius: 3, gridSize: 8
        )
        #expect(result?.rows == 4...7)
        #expect(result?.cols == 4...7)
    }

    @Test("Drag exactly at edge returns single-cell range")
    func dragAtEdgeReturnsSingleCellWhenRadiusIsZero() {
        let result = BoardLayout.placementSearchRanges(
            centerRow: 0, centerCol: 0,
            searchRadius: 0, gridSize: 8
        )
        #expect(result?.rows == 0...0)
        #expect(result?.cols == 0...0)
    }

    // MARK: - Crash Repro

    @Test("Drag far above the grid returns nil instead of trapping")
    func dragFarAboveGridReturnsNil() {
        let result = BoardLayout.placementSearchRanges(
            centerRow: -50, centerCol: 4,
            searchRadius: 3, gridSize: 8
        )
        #expect(result == nil)
    }

    @Test("Drag far below the grid returns nil instead of trapping")
    func dragFarBelowGridReturnsNil() {
        let result = BoardLayout.placementSearchRanges(
            centerRow: 999, centerCol: 4,
            searchRadius: 3, gridSize: 8
        )
        #expect(result == nil)
    }

    @Test("Drag far left of the grid returns nil")
    func dragFarLeftReturnsNil() {
        let result = BoardLayout.placementSearchRanges(
            centerRow: 4, centerCol: -50,
            searchRadius: 3, gridSize: 8
        )
        #expect(result == nil)
    }

    @Test("Drag far right of the grid returns nil")
    func dragFarRightReturnsNil() {
        let result = BoardLayout.placementSearchRanges(
            centerRow: 4, centerCol: 999,
            searchRadius: 3, gridSize: 8
        )
        #expect(result == nil)
    }

    @Test("Drag just past the top edge by less than the radius still finds candidates")
    func dragJustPastTopEdgeStillReturnsRange() {
        // centerRow = -2 with searchRadius = 5 → upper = 3, lower clamped = 0.
        // The drag is technically off-grid but candidates at row 0..3 are
        // still in reach, so the helper should still return a range.
        let result = BoardLayout.placementSearchRanges(
            centerRow: -2, centerCol: 4,
            searchRadius: 5, gridSize: 8
        )
        #expect(result?.rows == 0...3)
        #expect(result?.cols == 0...7)
    }
}

// MARK: - End-to-end findOptimalPlacement

@Suite("BoardLayout.findOptimalPlacement")
struct BoardLayoutFindOptimalPlacementTests {

    // Test inputs sized to match the running game: 40pt cells, 2pt spacing,
    // 8x8 grid, 300pt max snap distance. Matches the production values that
    // BoardView wires up; only here so the assertions read naturally.
    private static let cellSize: CGFloat = 40
    private static let cellSpacing: CGFloat = 2
    private static let gridSize: Int = 8
    private static let maxDistance: CGFloat = 300

    private func singleCellBlock() -> BlockShape {
        BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .blue)
    }

    /// `canPlace` closure that mirrors GameLogic.canPlaceBlock against an
    /// empty grid — every position is valid.
    private func canPlaceOnEmptyGrid(_ block: BlockShape, _ position: GridPosition) -> Bool {
        GameLogic.canPlaceBlock(block, at: position, in: GameLogic.createEmptyGrid())
    }

    /// `canPlace` closure that mirrors a fully-occupied grid — nothing fits.
    private func canPlaceOnFullGrid(_ block: BlockShape, _ position: GridPosition) -> Bool {
        var grid = GameLogic.createEmptyGrid()
        for r in 0..<Self.gridSize {
            for c in 0..<Self.gridSize {
                grid[r][c].isFilled = true
            }
        }
        return GameLogic.canPlaceBlock(block, at: position, in: grid)
    }

    @Test("Drag at grid center on empty grid finds a placement")
    func dragAtCenterOnEmptyGridFindsPlacement() {
        // Grid-local point near the center of the 8x8 grid.
        let center = CGPoint(x: 160, y: 160)

        let position = BoardLayout.findOptimalPlacement(
            for: singleCellBlock(),
            nearPoint: center,
            cellSize: Self.cellSize,
            cellSpacing: Self.cellSpacing,
            gridSize: Self.gridSize,
            maxDistance: Self.maxDistance,
            canPlace: canPlaceOnEmptyGrid
        )

        #expect(position != nil)
        if let position {
            // Should be near row 3-4, col 3-4 — the cell center calculation
            // shouldn't snap us across the board.
            #expect((3...4).contains(position.row))
            #expect((3...4).contains(position.col))
        }
    }

    @Test("Drag far above the grid returns nil (crash regression)")
    func dragFarAboveGridReturnsNil() {
        // nearPoint.y deeply negative — the exact shape that crashed in 2.0.3
        // before BoardLayout.placementSearchRanges gained its guard.
        let result = BoardLayout.findOptimalPlacement(
            for: singleCellBlock(),
            nearPoint: CGPoint(x: 160, y: -5_000),
            cellSize: Self.cellSize,
            cellSpacing: Self.cellSpacing,
            gridSize: Self.gridSize,
            maxDistance: Self.maxDistance,
            canPlace: canPlaceOnEmptyGrid
        )
        #expect(result == nil)
    }

    @Test("Drag far below the grid returns nil")
    func dragFarBelowGridReturnsNil() {
        let result = BoardLayout.findOptimalPlacement(
            for: singleCellBlock(),
            nearPoint: CGPoint(x: 160, y: 50_000),
            cellSize: Self.cellSize,
            cellSpacing: Self.cellSpacing,
            gridSize: Self.gridSize,
            maxDistance: Self.maxDistance,
            canPlace: canPlaceOnEmptyGrid
        )
        #expect(result == nil)
    }

    @Test("Full grid returns nil even for an in-grid nearPoint")
    func fullGridReturnsNil() {
        // The point is fine; the canPlace closure rejects every position
        // because the grid is full. Should return nil rather than a stale
        // best-position from a previous iteration.
        let result = BoardLayout.findOptimalPlacement(
            for: singleCellBlock(),
            nearPoint: CGPoint(x: 160, y: 160),
            cellSize: Self.cellSize,
            cellSpacing: Self.cellSpacing,
            gridSize: Self.gridSize,
            maxDistance: Self.maxDistance,
            canPlace: canPlaceOnFullGrid
        )
        #expect(result == nil)
    }
}
