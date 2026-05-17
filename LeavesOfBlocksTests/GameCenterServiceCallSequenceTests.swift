//
//  GameCenterServiceCallSequenceTests.swift
//  LeavesOfBlocksTests
//
//  U1: lock in the GameService → GameCenterServicing call sequence. Before
//  the protocol extraction, the only handle was `GameCenterService.shared`
//  and the only way to verify Game Center forwarding was a real GameKit
//  round-trip (gated by a sandboxed Apple ID — not viable from a unit
//  test). With `GameCenterServicing` injected into `GameService.init`,
//  the mock can record calls directly.
//

import Foundation
import Testing
@testable import LeavesOfBlocks

@Suite("GameService → GameCenterServicing call sequence")
struct GameCenterServiceCallSequenceTests {

    @Test @MainActor
    func saveGameRecordForwardsToSubmitFinalScore() throws {
        let store = CoreDataManager.makeInMemoryForTests()
        let gameCenter = MockGameCenterService()
        let service = GameService(
            coreDataManager: store,
            gameCenterService: gameCenter
        )

        try service.saveGameRecord(
            score: 4_280,
            linesCleared: 12,
            blocksPlaced: 45,
            gameTime: 180,
            difficulty: .moderate,
            longestCombo: 3
        )

        #expect(gameCenter.submitFinalScoreCalls.count == 1)
        #expect(gameCenter.submitFinalScoreCalls.first == .init(score: 4_280, longestCombo: 3))
    }

    @Test @MainActor
    func saveGameRecordForwardsEvenWhenSessionMetricsIsNil() throws {
        // Mirror the in-game save path: no PlayerBehaviorTracker metrics
        // attached. The Game Center side is opt-in and gates everything on
        // its own preference/auth — the forwarding must happen regardless
        // of whether efficiency data is present.
        let store = CoreDataManager.makeInMemoryForTests()
        let gameCenter = MockGameCenterService()
        let service = GameService(
            coreDataManager: store,
            gameCenterService: gameCenter
        )

        try service.saveGameRecord(
            score: 50,
            linesCleared: 0,
            blocksPlaced: 5,
            gameTime: 30,
            difficulty: .easy,
            longestCombo: 0
        )

        #expect(gameCenter.submitFinalScoreCalls.count == 1)
    }
}
