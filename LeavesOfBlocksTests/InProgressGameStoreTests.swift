//
//  InProgressGameStoreTests.swift
//  LeavesOfBlocksTests
//
//  Tests for the JSON-on-disk in-progress game store and the GameState
//  snapshot/restore lifecycle that depends on it.
//

import Foundation
import Testing
@testable import LeavesOfBlocks

// MARK: - Helpers

@MainActor
private func makeTempStore() -> (InProgressGameStore, URL) {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("InProgressGameTests-\(UUID().uuidString).json")
    return (InProgressGameStore(fileURL: url), url)
}

private func sampleSnapshot(score: Int = 1_250) -> InProgressGameSnapshot {
    var grid = GameLogic.createEmptyGrid()
    grid[0][0] = GridCell(isFilled: true, color: .red)
    grid[3][4] = GridCell(isFilled: true, color: .green)

    let block = BlockShape(
        positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1)],
        color: .blue
    )

    return InProgressGameSnapshot(
        grid: grid,
        currentBlocks: [block],
        score: score,
        linesCleared: 3,
        blocksPlaced: 7,
        longestCombo: 2,
        currentCombo: 0,
        specialShapesUsed: 0,
        difficulty: .moderate,
        elapsedGameTime: 84,
        savedAt: Date(timeIntervalSince1970: 1_700_000_000)
    )
}

// MARK: - Round-trip

@Suite("InProgressGameStore round-trip")
struct InProgressGameStoreRoundTripTests {
    @Test @MainActor
    func loadReturnsNilWhenNoFile() {
        let (store, url) = makeTempStore()
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(store.hasSavedGame == false)
        #expect(store.load() == nil)
    }

    @Test @MainActor
    func saveAndLoadPreservesAllFields() {
        let (store, url) = makeTempStore()
        defer { try? FileManager.default.removeItem(at: url) }

        let original = sampleSnapshot()
        store.save(original)

        #expect(store.hasSavedGame == true)
        let loaded = store.load()
        #expect(loaded == original)
    }

    @Test @MainActor
    func saveOverwritesPreviousSnapshot() {
        let (store, url) = makeTempStore()
        defer { try? FileManager.default.removeItem(at: url) }

        store.save(sampleSnapshot(score: 100))
        store.save(sampleSnapshot(score: 999))

        let loaded = store.load()
        #expect(loaded?.score == 999)
    }

    @Test @MainActor
    func clearRemovesTheFile() {
        let (store, url) = makeTempStore()
        defer { try? FileManager.default.removeItem(at: url) }

        store.save(sampleSnapshot())
        #expect(store.hasSavedGame == true)

        store.clear()
        #expect(store.hasSavedGame == false)
        #expect(store.load() == nil)
    }

    @Test @MainActor
    func clearOnEmptyStoreIsHarmless() {
        let (store, url) = makeTempStore()
        defer { try? FileManager.default.removeItem(at: url) }

        store.clear()
        #expect(store.hasSavedGame == false)
    }
}

// MARK: - GameState restore

@Suite("GameState restoration from snapshot")
struct GameStateRestoreTests {
    @Test @MainActor
    func freshInitWithEmptyStoreStartsNewGame() {
        let (store, url) = makeTempStore()
        defer { try? FileManager.default.removeItem(at: url) }

        let state = GameState(inProgressStore: store)

        #expect(state.score == 0)
        #expect(state.blocksPlaced == 0)
        #expect(state.currentBlocks.count > 0)
    }

    @Test @MainActor
    func initWithExistingSnapshotRestoresGameplayState() {
        let (store, url) = makeTempStore()
        defer { try? FileManager.default.removeItem(at: url) }

        let snapshot = sampleSnapshot(score: 4_280)
        store.save(snapshot)

        let state = GameState(inProgressStore: store)

        #expect(state.score == 4_280)
        #expect(state.blocksPlaced == snapshot.blocksPlaced)
        #expect(state.linesCleared == snapshot.linesCleared)
        #expect(state.longestCombo == snapshot.longestCombo)
        #expect(state.currentDifficulty == snapshot.difficulty)
        #expect(state.currentBlocks == snapshot.currentBlocks)
        #expect(state.grid == snapshot.grid)
        #expect(state.isGameOver == false)
    }

    @Test @MainActor
    func resetGameClearsTheStore() {
        let (store, url) = makeTempStore()
        defer { try? FileManager.default.removeItem(at: url) }

        store.save(sampleSnapshot())
        let state = GameState(inProgressStore: store)
        #expect(store.hasSavedGame == true)

        state.resetGame()

        #expect(store.hasSavedGame == false)
        #expect(state.score == 0)
    }

    @Test @MainActor
    func startGameClearsTheStore() {
        let (store, url) = makeTempStore()
        defer { try? FileManager.default.removeItem(at: url) }

        store.save(sampleSnapshot())
        let state = GameState(inProgressStore: store)

        state.startGame(difficulty: .hard)

        #expect(store.hasSavedGame == false)
        #expect(state.currentDifficulty == .hard)
        #expect(state.score == 0)
    }

    @Test @MainActor
    func snapshotCapturesCurrentState() {
        let (store, url) = makeTempStore()
        defer { try? FileManager.default.removeItem(at: url) }

        let state = GameState(inProgressStore: store)
        state.score = 500
        state.blocksPlaced = 3
        state.linesCleared = 1

        let snap = state.snapshot()

        #expect(snap.score == 500)
        #expect(snap.blocksPlaced == 3)
        #expect(snap.linesCleared == 1)
        #expect(snap.difficulty == state.currentDifficulty)
    }

    @Test @MainActor
    func hasActiveRunReflectsScoreAndGameOver() {
        let (store, url) = makeTempStore()
        defer { try? FileManager.default.removeItem(at: url) }

        let state = GameState(inProgressStore: store)
        #expect(state.hasActiveRun == false)

        state.score = 100
        #expect(state.hasActiveRun == true)

        state.isGameOver = true
        #expect(state.hasActiveRun == false)
    }

    @Test @MainActor
    func persistInProgressGameNoOpsWhenNoActiveRun() {
        let (store, url) = makeTempStore()
        defer { try? FileManager.default.removeItem(at: url) }

        let state = GameState(inProgressStore: store)
        state.persistInProgressGame()

        #expect(store.hasSavedGame == false)
    }

    @Test @MainActor
    func persistInProgressGameWritesWhenActive() {
        let (store, url) = makeTempStore()
        defer { try? FileManager.default.removeItem(at: url) }

        let state = GameState(inProgressStore: store)
        state.score = 250
        state.persistInProgressGame()

        #expect(store.hasSavedGame == true)
        #expect(store.load()?.score == 250)
    }
}
