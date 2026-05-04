//
//  GameServiceTests.swift
//  LeavesOfBlocksTests
//
//  Tests for GameService time formatting and timer lifecycle.
//

import Testing
@testable import LeavesOfBlocks

// MARK: - Formatted Game Time

@Suite("GameService.formattedGameTime")
struct GameServiceFormatTests {
    @Test @MainActor
    func zeroIsRenderedAsClock() {
        let service = GameService()
        #expect(service.formattedGameTime() == "0:00")
    }

    @Test @MainActor
    func reflectsCurrentGameTime() {
        let service = GameService()
        // currentGameTime is settable; the formatter delegates to
        // TimeInterval.formattedAsClock.
        service.currentGameTime = 125
        #expect(service.formattedGameTime() == "2:05")
    }

    @Test @MainActor
    func gameTimeAccessorMirrorsCurrentGameTime() {
        let service = GameService()
        service.currentGameTime = 42
        #expect(service.gameTime == 42)
    }
}

// MARK: - Timer Lifecycle

@Suite("GameService timer lifecycle")
struct GameServiceTimerLifecycleTests {
    @Test @MainActor
    func startResetsAndKicksOffTheTimer() {
        let service = GameService()
        service.currentGameTime = 999

        service.startGameTimer()

        #expect(service.currentGameTime == 0)

        // Cleanup
        service.stopGameTimer()
    }

    @Test @MainActor
    func resetTimerKeepsTimerRunningAndZeroesElapsed() {
        let service = GameService()
        service.startGameTimer()
        service.currentGameTime = 10

        service.resetGameTimer()

        #expect(service.currentGameTime == 0)

        // Cleanup
        service.stopGameTimer()
    }

    @Test @MainActor
    func stopTimerLeavesElapsedAlone() {
        let service = GameService()
        service.startGameTimer()
        service.currentGameTime = 7

        service.stopGameTimer()

        #expect(service.currentGameTime == 7)
    }

    @Test @MainActor
    func startSessionResetsTime() {
        let service = GameService()
        service.currentGameTime = 50
        service.startGameSession(difficulty: .moderate)
        #expect(service.currentGameTime == 0)
        service.endGameSession()
    }
}

// MARK: - High Score + Persistence (with in-memory CoreDataManager)

@Suite("GameService.isNewHighScore / getHighScore / saveGameRecord")
struct GameServicePersistenceTests {
    @Test @MainActor
    func isNewHighScoreOnEmptyStoreIsAlwaysTrueForPositiveScore() {
        let store = CoreDataManager.makeInMemoryForTests()
        let service = GameService(coreDataManager: store)
        #expect(service.isNewHighScore(1))
        #expect(service.isNewHighScore(99999))
    }

    @Test @MainActor
    func isNewHighScoreReturnsFalseWhenScoreIsBelowOrEqualToCurrent() {
        let store = CoreDataManager.makeInMemoryForTests()
        let service = GameService(coreDataManager: store)
        service.saveGameRecord(score: 500, linesCleared: 5, blocksPlaced: 20,
                               gameTime: 100, difficulty: .easy, longestCombo: 1)
        #expect(!service.isNewHighScore(500))
        #expect(!service.isNewHighScore(499))
        #expect(service.isNewHighScore(501))
    }

    @Test @MainActor
    func getHighScoreReturnsPersistedHighScore() {
        let store = CoreDataManager.makeInMemoryForTests()
        let service = GameService(coreDataManager: store)
        #expect(service.getHighScore() == 0)

        service.saveGameRecord(score: 100, linesCleared: 1, blocksPlaced: 5,
                               gameTime: 30, difficulty: .easy, longestCombo: 1)
        service.saveGameRecord(score: 350, linesCleared: 3, blocksPlaced: 12,
                               gameTime: 60, difficulty: .moderate, longestCombo: 2)

        #expect(service.getHighScore() == 350)
    }

    @Test @MainActor
    func saveGameRecordPersistsToTheInjectedStore() {
        let store = CoreDataManager.makeInMemoryForTests()
        let service = GameService(coreDataManager: store)

        service.saveGameRecord(score: 222, linesCleared: 2, blocksPlaced: 8,
                               gameTime: 45, difficulty: .hard, longestCombo: 1)

        // Read directly from the same store to verify the write landed there.
        let records = store.fetchGameHistory()
        #expect(records.count == 1)
        #expect(records.first?.score == 222)
        #expect(records.first?.difficulty == DifficultyMode.hard.rawValue)
    }

    @Test @MainActor
    func clearGameHistoryEmptiesTheStore() {
        let store = CoreDataManager.makeInMemoryForTests()
        let service = GameService(coreDataManager: store)
        service.saveGameRecord(score: 100, linesCleared: 1, blocksPlaced: 5,
                               gameTime: 30, difficulty: .easy, longestCombo: 1)
        service.saveGameRecord(score: 200, linesCleared: 2, blocksPlaced: 10,
                               gameTime: 60, difficulty: .moderate, longestCombo: 1)
        #expect(store.fetchGameHistory().count == 2)

        service.clearGameHistory()

        #expect(store.fetchGameHistory().isEmpty)
        #expect(service.getHighScore() == 0)
    }

    @Test @MainActor
    func resetAllDataClearsHistoryToo() {
        // resetAllData currently delegates to clearGameHistory plus a future
        // hook for UserDefaults — verify the history side is cleared.
        let store = CoreDataManager.makeInMemoryForTests()
        let service = GameService(coreDataManager: store)
        service.saveGameRecord(score: 50, linesCleared: 1, blocksPlaced: 5,
                               gameTime: 30, difficulty: .easy, longestCombo: 1)

        service.resetAllData()

        #expect(store.fetchGameHistory().isEmpty)
    }
}
