//
//  MockInProgressGameStoreContractTests.swift
//  LeavesOfBlocksTests
//
//  Locks in the mock-store contract so downstream tests (GameState call
//  sequence, future feature tests) can trust the behavior they're asserting
//  against. The mock previously had no tests of its own — a future change
//  that, say, stopped `clear()` from resetting `loadResult` would let
//  GameState tests pass while the mock silently diverged from the real
//  `InProgressGameStore`.
//
//  This suite is "contract pinning, not bug fixing" — the assertions
//  succeed on the current implementation. The TDD red was "the contract is
//  unspecified" rather than "the contract is wrong."
//

import Foundation
import Testing
@testable import LeavesOfBlocks

@Suite("MockInProgressGameStore contract")
struct MockInProgressGameStoreContractTests {

    private func makeSnapshot(score: Int = 100) -> InProgressGameSnapshot {
        InProgressGameSnapshot(
            grid: GameLogic.createEmptyGrid(),
            currentBlocks: [],
            score: score,
            linesCleared: 0,
            blocksPlaced: 0,
            longestCombo: 0,
            currentCombo: 0,
            specialShapesUsed: 0,
            difficulty: .easy,
            elapsedGameTime: 0,
            savedAt: Date()
        )
    }

    @Test @MainActor
    func saveSetsHasSavedGameToTrue() {
        let store = MockInProgressGameStore()
        #expect(store.hasSavedGame == false)

        store.save(makeSnapshot())

        #expect(store.hasSavedGame == true)
    }

    @Test @MainActor
    func clearResetsHasSavedGameToFalse() {
        let store = MockInProgressGameStore()
        store.save(makeSnapshot())
        #expect(store.hasSavedGame == true)

        store.clear()

        #expect(store.hasSavedGame == false)
        #expect(store.load() == nil)
    }

    @Test @MainActor
    func saveLoadRoundTripsTheSameSnapshot() {
        let store = MockInProgressGameStore()
        let original = makeSnapshot(score: 4_280)

        store.save(original)

        // The mock's contract is value-equality, not identity — saving and
        // then loading should yield a snapshot Equatable-equal to the input.
        // (`InProgressGameSnapshot` is a Codable value type with Equatable
        // synthesized over all stored properties including `savedAt`.)
        #expect(store.load() == original)
    }

    @Test @MainActor
    func saveCallCountAccumulatesIndependentlyOfLoad() {
        // Probe surface that GameState tests rely on: saveCallCount counts
        // every save invocation, even if the stored snapshot is replaced.
        let store = MockInProgressGameStore()
        store.save(makeSnapshot(score: 1))
        store.save(makeSnapshot(score: 2))
        store.save(makeSnapshot(score: 3))

        #expect(store.saveCallCount == 3)
        #expect(store.load()?.score == 3) // latest wins
    }
}
