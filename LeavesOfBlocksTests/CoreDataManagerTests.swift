//
//  CoreDataManagerTests.swift
//  LeavesOfBlocksTests
//
//  Tests for CoreDataManager's persistence, fetch, and aggregation surface.
//  Each suite uses a fresh in-memory CoreDataManager via the test factory
//  so runs are isolated from each other and from the user's real game
//  history. (Until the test factory existed, this whole file would have
//  written to production storage.)
//

import Foundation
import Testing
@testable import LeavesOfBlocks

// MARK: - Helpers

@MainActor
private func makeManager() -> CoreDataManager {
    CoreDataManager.makeInMemoryForTests()
}

@MainActor
private func saveSample(
    on manager: CoreDataManager,
    score: Int = 100,
    difficulty: DifficultyMode = .easy,
    blocksPlaced: Int = 10,
    linesCleared: Int = 1,
    longestCombo: Int = 1,
    gameTime: TimeInterval = 60
) {
    manager.saveGameRecord(
        score: score,
        difficulty: difficulty,
        blocksPlaced: blocksPlaced,
        linesCleared: linesCleared,
        longestCombo: longestCombo,
        gameTime: gameTime
    )
}

// MARK: - Empty Store Behavior

@Suite("CoreDataManager: empty store")
struct CoreDataManagerEmptyStoreTests {
    @Test @MainActor
    func fetchHistoryReturnsEmptyArray() {
        let m = makeManager()
        #expect(m.fetchGameHistory().isEmpty)
        #expect(m.fetchGameHistory(limit: 10).isEmpty)
        #expect(m.fetchGameHistory(for: .easy).isEmpty)
        #expect(m.fetchHighScores(limit: 5).isEmpty)
    }

    @Test @MainActor
    func calculateStatisticsReturnsZeros() {
        let m = makeManager()
        let stats = m.calculateStatistics()
        #expect(stats.totalGames == 0)
        #expect(stats.totalScore == 0)
        #expect(stats.averageScore == 0)
        #expect(stats.totalBlocksPlaced == 0)
        #expect(stats.highScore == 0)
    }

    @Test @MainActor
    func calculateExtendedStatisticsReturnsEmpty() {
        let m = makeManager()
        let stats = m.calculateExtendedStatistics()
        #expect(stats.totalGames == 0)
        #expect(stats.highScore == 0)
        #expect(stats.bestCombo == 0)
        #expect(stats.favoriteDifficulty == nil)
    }
}

// MARK: - Save + Fetch

@Suite("CoreDataManager: save + fetch round-trip")
struct CoreDataManagerSaveFetchTests {
    @Test @MainActor
    func savedRecordAppearsInFetchHistory() {
        let m = makeManager()
        saveSample(on: m, score: 100)
        let records = m.fetchGameHistory()
        #expect(records.count == 1)
        #expect(records.first?.score == 100)
    }

    @Test @MainActor
    func savedRecordPreservesAllFields() {
        let m = makeManager()
        m.saveGameRecord(
            score: 250,
            difficulty: .hard,
            blocksPlaced: 42,
            linesCleared: 8,
            longestCombo: 3,
            gameTime: 120
        )
        let record = m.fetchGameHistory().first!
        #expect(record.score == 250)
        #expect(record.difficulty == DifficultyMode.hard.rawValue)
        #expect(record.blocksPlaced == 42)
        #expect(record.linesCleared == 8)
        #expect(record.longestCombo == 3)
        #expect(record.gameTime == 120)
        #expect(record.id != nil)
        #expect(record.date != nil)
    }

    @Test @MainActor
    func fetchHistoryReturnsNewestFirst() {
        let m = makeManager()
        saveSample(on: m, score: 100)
        // Force a new Date stamp by yielding briefly. saveGameRecord stamps
        // record.date = Date() — sequential calls in the same millisecond
        // would tie. A Thread.sleep is heavy-handed but cheap and reliable.
        Thread.sleep(forTimeInterval: 0.005)
        saveSample(on: m, score: 200)
        Thread.sleep(forTimeInterval: 0.005)
        saveSample(on: m, score: 50)

        let records = m.fetchGameHistory()
        #expect(records.count == 3)
        #expect(records[0].score == 50)   // most recent
        #expect(records[2].score == 100)  // oldest
    }

    @Test @MainActor
    func fetchHistoryRespectsLimit() {
        let m = makeManager()
        for s in [10, 20, 30, 40, 50] {
            saveSample(on: m, score: s)
            Thread.sleep(forTimeInterval: 0.002)
        }
        #expect(m.fetchGameHistory(limit: 3).count == 3)
        #expect(m.fetchGameHistory(limit: 10).count == 5)
        #expect(m.fetchGameHistory(limit: 0).count == 5)  // Core Data treats 0 as "no limit"
    }
}

// MARK: - Filtered Queries

@Suite("CoreDataManager: filtered queries")
struct CoreDataManagerFilteredQueryTests {
    @Test @MainActor
    func fetchHistoryForDifficultyOnlyReturnsThatDifficulty() {
        let m = makeManager()
        saveSample(on: m, score: 10, difficulty: .easy)
        saveSample(on: m, score: 20, difficulty: .moderate)
        saveSample(on: m, score: 30, difficulty: .hard)
        saveSample(on: m, score: 40, difficulty: .easy)

        let easyOnly = m.fetchGameHistory(for: .easy)
        #expect(easyOnly.count == 2)
        #expect(easyOnly.allSatisfy { $0.difficulty == DifficultyMode.easy.rawValue })

        let hardOnly = m.fetchGameHistory(for: .hard)
        #expect(hardOnly.count == 1)
        #expect(hardOnly.first?.score == 30)
    }

    @Test @MainActor
    func fetchHistoryForDifficultySortsByScoreDescending() {
        let m = makeManager()
        saveSample(on: m, score: 50, difficulty: .easy)
        saveSample(on: m, score: 200, difficulty: .easy)
        saveSample(on: m, score: 100, difficulty: .easy)

        let records = m.fetchGameHistory(for: .easy)
        #expect(records.map { Int($0.score) } == [200, 100, 50])
    }

    @Test @MainActor
    func fetchHighScoresReturnsTopByScoreDesc() {
        let m = makeManager()
        for s in [50, 200, 100, 300, 75] {
            saveSample(on: m, score: s)
        }
        let top3 = m.fetchHighScores(limit: 3)
        #expect(top3.map { Int($0.score) } == [300, 200, 100])
    }

    @Test @MainActor
    func fetchHighScoresWithLimitLargerThanRowsReturnsAll() {
        let m = makeManager()
        saveSample(on: m, score: 10)
        saveSample(on: m, score: 20)
        let result = m.fetchHighScores(limit: 100)
        #expect(result.count == 2)
    }
}

// MARK: - Deletion

@Suite("CoreDataManager: deletion")
struct CoreDataManagerDeletionTests {
    @Test @MainActor
    func deleteAllRemovesEverything() {
        let m = makeManager()
        for s in [10, 20, 30] {
            saveSample(on: m, score: s)
        }
        #expect(m.fetchGameHistory().count == 3)

        m.deleteAllGameRecords()

        #expect(m.fetchGameHistory().isEmpty)
        #expect(m.calculateStatistics().totalGames == 0)
    }

    @Test @MainActor
    func deleteAllOnEmptyStoreIsHarmless() {
        let m = makeManager()
        m.deleteAllGameRecords()  // no throws expected
        #expect(m.fetchGameHistory().isEmpty)
    }
}

// MARK: - Statistics Aggregation

@Suite("CoreDataManager: calculateStatistics")
struct CoreDataManagerStatisticsTests {
    @Test @MainActor
    func aggregatesAcrossAllRecords() {
        let m = makeManager()
        m.saveGameRecord(score: 100, difficulty: .easy, blocksPlaced: 20,
                         linesCleared: 2, longestCombo: 1, gameTime: 60)
        m.saveGameRecord(score: 200, difficulty: .moderate, blocksPlaced: 30,
                         linesCleared: 4, longestCombo: 2, gameTime: 90)
        m.saveGameRecord(score: 50, difficulty: .easy, blocksPlaced: 10,
                         linesCleared: 1, longestCombo: 1, gameTime: 30)

        let stats = m.calculateStatistics()
        #expect(stats.totalGames == 3)
        #expect(stats.totalScore == 350)
        #expect(stats.averageScore == 350 / 3)  // integer division: 116
        #expect(stats.totalBlocksPlaced == 60)
        #expect(stats.highScore == 200)
    }

    @Test @MainActor
    func singleRecordHighScoreEqualsThatRecord() {
        let m = makeManager()
        saveSample(on: m, score: 777)
        #expect(m.calculateStatistics().highScore == 777)
    }
}

// MARK: - Extended Statistics

@Suite("CoreDataManager: calculateExtendedStatistics")
struct CoreDataManagerExtendedStatisticsTests {
    @Test @MainActor
    func capturesRecordsFromMultipleGames() {
        let m = makeManager()
        // Two games on different days (day boundary tested separately).
        m.saveGameRecord(score: 100, difficulty: .easy, blocksPlaced: 10,
                         linesCleared: 5, longestCombo: 3, gameTime: 100)
        m.saveGameRecord(score: 200, difficulty: .easy, blocksPlaced: 20,
                         linesCleared: 10, longestCombo: 5, gameTime: 200)

        let stats = m.calculateExtendedStatistics()
        #expect(stats.totalGames == 2)
        #expect(stats.highScore == 200)
        #expect(stats.bestCombo == 5)
        #expect(stats.mostLinesInGame == 10)
        #expect(stats.longestGameTime == 200)
        #expect(stats.totalPlayTime == 300)
        #expect(stats.favoriteDifficulty == .easy)
    }

    @Test @MainActor
    func favoriteDifficultyIsTheModalDifficulty() {
        let m = makeManager()
        saveSample(on: m, difficulty: .easy)
        saveSample(on: m, difficulty: .easy)
        saveSample(on: m, difficulty: .moderate)
        saveSample(on: m, difficulty: .hard)

        #expect(m.calculateExtendedStatistics().favoriteDifficulty == .easy)
    }
}
