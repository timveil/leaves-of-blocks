//
//  HintTests.swift
//  LeavesOfBlocksTests
//
//  Tests for the player-assist Hint feature: discovery (prefers placements
//  that clear lines, falls back to first valid, returns nil when nothing fits)
//  and GameState orchestration (once-per-game gate, disabled at game-over).
//

import Foundation
import Testing
@testable import LeavesOfBlocks

// MARK: - Helpers

@MainActor
private func makeHintState() -> (GameState, URL) {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("HintTests-\(UUID().uuidString).json")
    let store = InProgressGameStore(fileURL: url)
    let state = GameState(inProgressStore: store)
    return (state, url)
}

private func filled(rows: [Int], cols: [Int]) -> [[GridCell]] {
    var grid = GameLogic.createEmptyGrid()
    for r in rows {
        for c in cols {
            grid[r][c].isFilled = true
        }
    }
    return grid
}

// MARK: - Discovery

@Suite("Hint: discovery")
struct HintDiscoveryTests {
    @Test
    func findsValidPlacementOnEmptyGrid() {
        let grid = GameLogic.createEmptyGrid()
        let block = BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .blue)
        let hint = GameLogic.findHint(blocks: [block], grid: grid)
        #expect(hint != nil)
        #expect(hint?.blockIndex == 0)
    }

    @Test
    func returnsNilWhenNoBlockFits() {
        // Full grid: nothing fits.
        var grid = GameLogic.createEmptyGrid()
        for r in 0..<8 { for c in 0..<8 { grid[r][c].isFilled = true } }
        let block = BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .blue)
        #expect(GameLogic.findHint(blocks: [block], grid: grid) == nil)
    }

    @Test
    func returnsNilWhenBlocksArrayIsEmpty() {
        let grid = GameLogic.createEmptyGrid()
        #expect(GameLogic.findHint(blocks: [], grid: grid) == nil)
    }

    @Test
    func prefersPlacementThatClearsLines() {
        // Row 0 cols 0..6 filled. Only a 1x1 at (0,7) clears row 0.
        // The first block is a 1x2 with no clearing placement (only valid in
        // row 1 onward, where row 1 isn't nearly full). The second block is
        // the 1x1 clearer. Without the prefer-clearing rule the scanner would
        // return the 1x2's first valid spot; with it, the clearing hint wins.
        var grid = GameLogic.createEmptyGrid()
        for col in 0..<7 { grid[0][col].isFilled = true }
        let nonClearing = BlockShape(
            positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1)],
            color: .red
        )
        let clearingBlock = BlockShape(
            positions: [GridPosition(row: 0, col: 0)],
            color: .blue
        )

        let hint = GameLogic.findHint(blocks: [nonClearing, clearingBlock], grid: grid)
        #expect(hint?.willClearLines == true)
        #expect(hint?.blockIndex == 1)
        #expect(hint?.position == GridPosition(row: 0, col: 7))
    }

    @Test
    func highlightedCellsForNormalBlockTranslatePositions() {
        let grid = GameLogic.createEmptyGrid()
        // 1x2 horizontal block.
        let block = BlockShape(
            positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1)],
            color: .blue
        )
        let hint = GameLogic.findHint(blocks: [block], grid: grid)
        #expect(hint?.highlightedCells.count == 2)
        // First valid position is (0,0), so the highlighted cells should be (0,0) and (0,1).
        #expect(hint?.highlightedCells.contains(GridPosition(row: 0, col: 0)) == true)
        #expect(hint?.highlightedCells.contains(GridPosition(row: 0, col: 1)) == true)
    }

    @Test
    func highlightedCellsForHorizontalClearCoversFullRow() {
        let grid = GameLogic.createEmptyGrid()
        let horizontal = BlockShape(
            positions: [GridPosition(row: 0, col: 0)],
            color: .red,
            type: .horizontalClear
        )
        let hint = GameLogic.findHint(blocks: [horizontal], grid: grid)
        let row = hint?.position.row
        #expect(hint?.highlightedCells.count == 8)
        for col in 0..<8 {
            #expect(hint?.highlightedCells.contains(GridPosition(row: row ?? -1, col: col)) == true)
        }
    }

    @Test
    func highlightedCellsForVerticalClearCoversFullColumn() {
        let grid = GameLogic.createEmptyGrid()
        let vertical = BlockShape(
            positions: [GridPosition(row: 0, col: 0)],
            color: .red,
            type: .verticalClear
        )
        let hint = GameLogic.findHint(blocks: [vertical], grid: grid)
        let col = hint?.position.col
        #expect(hint?.highlightedCells.count == 8)
        for row in 0..<8 {
            #expect(hint?.highlightedCells.contains(GridPosition(row: row, col: col ?? -1)) == true)
        }
    }

    @Test
    func highlightedCellsForAreaClearStayWithinGrid() {
        let grid = GameLogic.createEmptyGrid()
        let area = BlockShape(
            positions: [GridPosition(row: 0, col: 0)],
            color: .red,
            type: .areaClear
        )
        let hint = GameLogic.findHint(blocks: [area], grid: grid)
        guard let cells = hint?.highlightedCells else {
            Issue.record("expected an area-clear hint")
            return
        }
        // Every highlighted cell must be within the 8x8 grid.
        for cell in cells {
            #expect(cell.row >= 0 && cell.row < 8)
            #expect(cell.col >= 0 && cell.col < 8)
        }
        // Center is (0,0) by first-valid scan; area-clear at (0,0) covers (0,0), (0,1), (1,0), (1,1) (the in-bounds subset).
        #expect(cells.count == 4)
    }
}

// MARK: - GameState orchestration

@Suite("Hint: orchestration")
struct HintOrchestrationTests {
    @Test @MainActor
    func canHintIsTrueOnFreshState() {
        let (state, _) = makeHintState()
        #expect(state.canHint == true)
        #expect(state.hintUsed == false)
    }

    @Test @MainActor
    func requestHintConsumesFlagOnce() {
        let (state, _) = makeHintState()
        let first = state.requestHint()
        #expect(first != nil)
        #expect(state.hintUsed == true)
        #expect(state.canHint == false)

        let second = state.requestHint()
        #expect(second == nil)
    }

    @Test @MainActor
    func requestHintReturnsNilWhenGameOver() {
        let (state, _) = makeHintState()
        state._setTestState(isGameOver: true)
        #expect(state.canHint == false)
        #expect(state.requestHint() == nil)
        #expect(state.hintUsed == false, "no-op request must not consume the flag")
    }

    @Test @MainActor
    func nilHintDoesNotConsumeFlag() {
        let (state, _) = makeHintState()
        // Fill grid so no block fits.
        var grid = GameLogic.createEmptyGrid()
        for r in 0..<8 { for c in 0..<8 { grid[r][c].isFilled = true } }
        state._setTestState(grid: grid)
        let result = state.requestHint()
        #expect(result == nil)
        #expect(state.hintUsed == false)
    }

    @Test @MainActor
    func resetGameRestoresHintAvailability() {
        let (state, _) = makeHintState()
        _ = state.requestHint()
        #expect(state.hintUsed == true)

        state.resetGame()
        #expect(state.hintUsed == false)
        #expect(state.canHint == true)
    }
}
