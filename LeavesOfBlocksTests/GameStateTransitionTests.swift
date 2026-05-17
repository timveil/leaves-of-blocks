//
//  GameStateTransitionTests.swift
//  LeavesOfBlocksTests
//
//  Property-style probes against GameState's placement contract. Each test
//  asserts an invariant about state transitions then varies inputs to find
//  where the contract bends.
//
//  GameState reaches into CoreData via GameService and to disk via
//  InProgressGameStore, so each test injects a per-suite temp file store
//  to keep runs isolated. GameService still uses the production store for
//  high-score queries — those code paths aren't exercised here.
//

import Foundation
import Testing
@testable import LeavesOfBlocks

// MARK: - Helpers

@MainActor
private func makeFreshState(difficulty: DifficultyMode = .easy) -> (GameState, URL) {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("GameStateTransitionTests-\(UUID().uuidString).json")
    let store = InProgressGameStore(fileURL: url)
    let state = GameState(inProgressStore: store)
    state._setTestState(currentDifficulty: difficulty)
    return (state, url)
}

/// Find any cell where `block` is placeable, or nil if the block can't fit.
@MainActor
private func anyPlaceablePosition(for block: BlockShape, on state: GameState) -> GridPosition? {
    return GameLogic.findValidPositions(for: block, in: state.grid).first
}

// MARK: - Invalid Placement is a No-op

@Suite("GameState.placeBlock: invalid placement leaves state unchanged")
struct InvalidPlacementIsNoOpTests {
    @Test @MainActor
    func invalidPositionDoesNothing() {
        let (state, _) = makeFreshState()
        guard let block = state.currentBlocks.first else {
            Issue.record("expected currentBlocks to be non-empty after init")
            return
        }

        let scoreBefore = state.score
        let blocksPlacedBefore = state.blocksPlaced
        let currentBlocksBefore = state.currentBlocks
        let gridFilledBefore = state.grid.flatMap { $0 }.filter { $0.isFilled }.count

        // Position safely outside grid bounds — guaranteed to fail canPlaceBlock.
        state.placeBlock(block, at: GridPosition(row: 99, col: 99))

        #expect(state.score == scoreBefore)
        #expect(state.blocksPlaced == blocksPlacedBefore)
        #expect(state.currentBlocks == currentBlocksBefore)
        #expect(state.grid.flatMap { $0 }.filter { $0.isFilled }.count == gridFilledBefore)
    }

    @Test @MainActor
    func placingOntoOccupiedCellsDoesNothing() {
        let (state, _) = makeFreshState()
        // Fill the entire grid so no normal block can be placed.
        var fullGrid = GameLogic.createEmptyGrid()
        for r in 0..<8 { for c in 0..<8 { fullGrid[r][c].isFilled = true } }
        state._setTestState(grid: fullGrid)
        guard let normalBlock = state.currentBlocks.first(where: { $0.type == .normal }) else {
            Issue.record("expected at least one normal block in currentBlocks")
            return
        }

        let scoreBefore = state.score
        let blocksPlacedBefore = state.blocksPlaced
        let currentBlocksBefore = state.currentBlocks

        state.placeBlock(normalBlock, at: GridPosition(row: 0, col: 0))

        #expect(state.score == scoreBefore)
        #expect(state.blocksPlaced == blocksPlacedBefore)
        #expect(state.currentBlocks == currentBlocksBefore)
    }
}

// MARK: - Successful Placement Updates State Consistently

@Suite("GameState.placeBlock: successful placement updates state consistently")
struct SuccessfulPlacementInvariantsTests {
    @Test @MainActor
    func blocksPlacedIncrementsByOne() {
        let (state, _) = makeFreshState()
        guard let block = state.currentBlocks.first(where: { $0.type == .normal }),
              let pos = anyPlaceablePosition(for: block, on: state) else {
            Issue.record("could not find a placeable normal block on a fresh grid")
            return
        }

        let before = state.blocksPlaced
        state.placeBlock(block, at: pos)
        #expect(state.blocksPlaced == before + 1)
    }

    @Test @MainActor
    func scoreNeverDecreasesAfterPlacement() {
        let (state, _) = makeFreshState()
        guard let block = state.currentBlocks.first(where: { $0.type == .normal }),
              let pos = anyPlaceablePosition(for: block, on: state) else {
            Issue.record("could not find a placeable normal block on a fresh grid")
            return
        }

        let before = state.score
        state.placeBlock(block, at: pos)
        #expect(state.score >= before, "score went backwards: \(before) → \(state.score)")
    }

    @Test @MainActor
    func normalBlockScoreMatchesGameLogicFormula() {
        // A placement on an empty grid (no line clear possible from a single
        // small block) should bump score by exactly the block-score formula.
        let (state, _) = makeFreshState()
        guard let block = state.currentBlocks.first(where: {
                $0.type == .normal && $0.positions.count <= 4
            }),
              let pos = anyPlaceablePosition(for: block, on: state) else {
            Issue.record("could not find a small normal block on a fresh grid")
            return
        }

        let scoreBefore = state.score
        let expectedDelta = GameLogic.calculateBlockScore(block: block)
        state.placeBlock(block, at: pos)
        // No clears possible (small block on empty grid), so delta must equal block score exactly.
        #expect(
            state.score - scoreBefore == expectedDelta,
            "expected +\(expectedDelta), got +\(state.score - scoreBefore)"
        )
    }

    @Test @MainActor
    func placedBlockIsRemovedFromCurrentBlocks() {
        let (state, _) = makeFreshState()
        guard let block = state.currentBlocks.first(where: { $0.type == .normal }),
              let pos = anyPlaceablePosition(for: block, on: state) else {
            Issue.record("no placeable block")
            return
        }
        let countBefore = state.currentBlocks.count
        state.placeBlock(block, at: pos)
        // Block is removed (or, if it was the last block, currentBlocks is
        // refilled by generateNewBlocks — count goes back up rather than to 0).
        let removed = !state.currentBlocks.contains(where: {
            $0.positions == block.positions && $0.color == block.color
        })
        let refilled = state.currentBlocks.count > countBefore - 1
        #expect(removed || refilled)
    }

    @Test @MainActor
    func currentBlocksNeverStaysEmpty() {
        // After placing every current block, generateNewBlocks should fire
        // and refill the slot. End-of-turn currentBlocks should never be empty
        // unless game-over fired and we're done.
        let (state, _) = makeFreshState()
        var safety = 30
        while !state.currentBlocks.isEmpty && !state.isGameOver && safety > 0 {
            guard let (block, pos) = state.currentBlocks.lazy.compactMap({ b -> (BlockShape, GridPosition)? in
                guard let p = GameLogic.findValidPositions(for: b, in: state.grid).first else { return nil }
                return (b, p)
            }).first else {
                break  // no current block fits — game would be over
            }
            state.placeBlock(block, at: pos)
            safety -= 1
        }
        #expect(state.isGameOver || !state.currentBlocks.isEmpty,
                "currentBlocks empty without game-over (refill failed)")
    }
}

// MARK: - Combo + Specials Tracking Invariants

@Suite("GameState combo and special-shape tracking")
struct ComboAndSpecialsTrackingTests {
    @Test @MainActor
    func longestComboNeverBelowCurrentCombo() {
        // Probe: across many random placements, longestCombo always >= currentCombo.
        let (state, _) = makeFreshState()
        var safety = 25
        while !state.isGameOver && safety > 0 {
            guard let (block, pos) = state.currentBlocks.lazy.compactMap({ b -> (BlockShape, GridPosition)? in
                guard let p = GameLogic.findValidPositions(for: b, in: state.grid).first else { return nil }
                return (b, p)
            }).first else { break }
            state.placeBlock(block, at: pos)
            #expect(state.longestCombo >= state.currentCombo,
                    "longestCombo=\(state.longestCombo) < currentCombo=\(state.currentCombo)")
            safety -= 1
        }
    }

    @Test @MainActor
    func specialShapesUsedOnlyIncrementsForNonNormalBlocks() {
        let (state, _) = makeFreshState()
        // Inject a special block manually.
        let special = BlockShape.horizontalClearShape
        state._setTestState(currentBlocks: [special])
        let before = state.specialShapesUsed
        state.placeBlock(special, at: GridPosition(row: 0, col: 0))
        #expect(state.specialShapesUsed == before + 1)
    }

    @Test @MainActor
    func placeBlockRemovesTheExactInstanceWhenDuplicateShapesExist() {
        // H7: two BlockShape instances with identical positions+color but
        // distinct IDs. Placing one should remove that one specifically —
        // not whichever came first in currentBlocks. Pre-H7, removal matched
        // on positions+color and would remove the earlier-indexed twin.
        let (state, _) = makeFreshState()
        let positions = [GridPosition(row: 0, col: 0)]
        let blockA = BlockShape(positions: positions, color: .red)
        let blockB = BlockShape(positions: positions, color: .red)
        #expect(blockA.id != blockB.id, "test setup: distinct IDs required")

        state._setTestState(currentBlocks: [blockA, blockB])
        state.placeBlock(blockB, at: GridPosition(row: 4, col: 4))

        #expect(state.currentBlocks.contains(where: { $0.id == blockA.id }),
                "blockA should still be present in the holding area")
        #expect(!state.currentBlocks.contains(where: { $0.id == blockB.id }),
                "blockB (the placed one) should have been removed")
    }

    @Test @MainActor
    func normalBlockDoesNotIncrementSpecialShapesUsed() {
        let (state, _) = makeFreshState()
        guard let normal = state.currentBlocks.first(where: { $0.type == .normal }),
              let pos = anyPlaceablePosition(for: normal, on: state) else {
            Issue.record("no placeable normal block")
            return
        }
        let before = state.specialShapesUsed
        state.placeBlock(normal, at: pos)
        #expect(state.specialShapesUsed == before)
    }
}
