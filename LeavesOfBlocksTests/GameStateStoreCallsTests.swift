//
//  GameStateStoreCallsTests.swift
//  LeavesOfBlocksTests
//
//  A2: verifies GameState's call sequence against the in-progress store
//  using a mock conforming to InProgressGameStoring. Pre-A2 this couldn't
//  be tested without round-tripping JSON through a temp file.
//

import Foundation
import Testing
@testable import LeavesOfBlocks

@Suite("GameState ↔ InProgressGameStore call sequence")
struct GameStateStoreCallsTests {

    @Test @MainActor
    func freshInitWithEmptyStoreDoesNotSave() {
        let store = MockInProgressGameStore()
        _ = GameState(inProgressStore: store)

        #expect(store.saveCallCount == 0,
                "construction with an empty store should not write")
        #expect(store.clearCallCount == 0,
                "construction with an empty store should not clear")
    }

    @Test @MainActor
    func resetGameClearsTheStore() {
        let store = MockInProgressGameStore()
        let state = GameState(inProgressStore: store)

        state.startGame(difficulty: .easy)

        #expect(store.clearCallCount >= 1,
                "starting/resetting a game should drop any prior snapshot")
    }

    @Test @MainActor
    func persistInProgressGameNoOpsWhenScoreIsZero() {
        let store = MockInProgressGameStore()
        let state = GameState(inProgressStore: store)

        state.persistInProgressGame()

        #expect(store.saveCallCount == 0,
                "no active run should not produce a snapshot")
    }
}
