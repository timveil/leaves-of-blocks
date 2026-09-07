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

/// A known normal block: two cells side by side unless given other cells.
///
/// Tests that need *a block* build one rather than searching the generated
/// tray for a suitable draw. The tray comes from BlockGenerator, which is
/// weighted and random and can legitimately hand back three large or special
/// shapes — a run where nothing matched used to fail the test that was looking,
/// which reported a fixture problem as if the behaviour under test had broken.
///
/// - Parameters:
///   - cells: The block's shape, as (row, column) offsets from its origin.
///   - color: Distinguishes blocks in a tray that holds more than one.
private func normalBlock(_ cells: [(row: Int, col: Int)] = [(0, 0), (0, 1)],
                         color: BlockColor = .blue) -> BlockShape {
    BlockShape(positions: cells.map { GridPosition(row: $0.row, col: $0.col) }, color: color)
}

/// A state whose tray and grid are both known.
///
/// The grid defaults to empty so a placement always has somewhere to go: these
/// tests assert what placing a block does, not whether the generator produced
/// one that fits. Genuine randomized coverage lives in PropertyTests.swift and
/// BlockGeneratorPropertyTests, where the randomness is the subject rather than
/// the fixture.
@MainActor
private func makeStateWithBlocks(_ blocks: [BlockShape],
                                 grid: [[GridCell]] = GameLogic.createEmptyGrid(),
                                 difficulty: DifficultyMode = .easy) -> (GameState, URL) {
    let (state, url) = makeFreshState(difficulty: difficulty)
    state._setTestState(currentBlocks: blocks, grid: grid)
    return (state, url)
}

// MARK: - Invalid Placement is a No-op

@Suite("GameState.placeBlock: invalid placement leaves state unchanged")
struct InvalidPlacementIsNoOpTests {
    @Test @MainActor
    func invalidPositionDoesNothing() {
        let (state, _) = makeStateWithBlocks([normalBlock()])
        let block = state.currentBlocks[0]

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
        // Fill the entire grid so no normal block can be placed.
        var fullGrid = GameLogic.createEmptyGrid()
        for r in 0..<8 { for c in 0..<8 { fullGrid[r][c].isFilled = true } }
        let (state, _) = makeStateWithBlocks([normalBlock()], grid: fullGrid)
        let block = state.currentBlocks[0]

        let scoreBefore = state.score
        let blocksPlacedBefore = state.blocksPlaced
        let currentBlocksBefore = state.currentBlocks

        state.placeBlock(block, at: GridPosition(row: 0, col: 0))

        #expect(state.score == scoreBefore)
        #expect(state.blocksPlaced == blocksPlacedBefore)
        #expect(state.currentBlocks == currentBlocksBefore)
    }
}

// MARK: - Successful Placement Updates State Consistently

@Suite("GameState.placeBlock: successful placement updates state consistently")
struct SuccessfulPlacementInvariantsTests {
    @Test @MainActor
    func blocksPlacedIncrementsByOne() throws {
        let (state, _) = makeStateWithBlocks([normalBlock()])
        let block = state.currentBlocks[0]
        let pos = try #require(anyPlaceablePosition(for: block, on: state))

        let before = state.blocksPlaced
        state.placeBlock(block, at: pos)
        #expect(state.blocksPlaced == before + 1)
    }

    @Test @MainActor
    func scoreNeverDecreasesAfterPlacement() throws {
        let (state, _) = makeStateWithBlocks([normalBlock()])
        let block = state.currentBlocks[0]
        let pos = try #require(anyPlaceablePosition(for: block, on: state))

        let before = state.score
        state.placeBlock(block, at: pos)
        #expect(state.score >= before, "score went backwards: \(before) → \(state.score)")
    }

    @Test @MainActor
    func normalBlockScoreMatchesGameLogicFormula() throws {
        // A placement on an EMPTY grid cannot complete a line, so the delta is
        // exactly the block-score formula. Both halves of that are now fixed
        // rather than drawn: makeStateWithBlocks clears the grid, which
        // makeFreshState pre-fills at random, and the block is built here.
        //
        // This is the test that flaked. It asked the tray for a normal block of
        // four cells or fewer, and a run where the generator offered none failed
        // on the fixture without ever reaching the assertion.
        let (state, _) = makeStateWithBlocks([normalBlock()])
        let block = state.currentBlocks[0]
        let pos = try #require(anyPlaceablePosition(for: block, on: state))

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
    func placedBlockIsRemovedFromCurrentBlocks() throws {
        // Two blocks, so removal is observable on its own: placing the last one
        // triggers generateNewBlocks, and the refill used to make this assert
        // "removed OR refilled", which passes either way. The refill path has
        // its own test below.
        let (state, _) = makeStateWithBlocks([normalBlock(), normalBlock([(0, 0)], color: .green)])
        let block = state.currentBlocks[0]
        let pos = try #require(anyPlaceablePosition(for: block, on: state))

        let countBefore = state.currentBlocks.count
        state.placeBlock(block, at: pos)

        #expect(!state.currentBlocks.contains { $0.id == block.id }, "the placed block is still in the tray")
        #expect(state.currentBlocks.count == countBefore - 1)
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
    func normalBlockDoesNotIncrementSpecialShapesUsed() throws {
        let (state, _) = makeStateWithBlocks([normalBlock()])
        let normal = state.currentBlocks[0]
        let pos = try #require(anyPlaceablePosition(for: normal, on: state))

        let before = state.specialShapesUsed
        state.placeBlock(normal, at: pos)
        #expect(state.specialShapesUsed == before)
    }
}
