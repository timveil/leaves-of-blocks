//
//  GameSessionFromRecordTests.swift
//  LeavesOfBlocksTests
//
//  H6: tests for the GameRecord → GameSession projection used by
//  HistoryView. The view previously inlined this mapping inside
//  loadGameHistory(); extracting it as `GameSession(record:)` lets the
//  view drive itself off `@FetchRequest` and lets the mapping be tested
//  without a Core Data fetch on every assertion.
//

import CoreData
import Foundation
import Testing
@testable import LeavesOfBlocks

// MARK: - Helpers

@MainActor
private func makeRecord(
    in manager: CoreDataManager,
    score: Int = 100,
    difficulty: DifficultyMode = .easy,
    blocksPlaced: Int = 5,
    linesCleared: Int = 1,
    longestCombo: Int = 1,
    gameTime: TimeInterval = 60,
    date: Date = Date(),
    averageGridEfficiency: Double = 0,
    averageFragmentation: Double = 0,
    strategicPlayRating: Double = 0,
    challengeMaintained: Double = 0,
    fallbackActivations: Int = 0,
    efficiencyGrade: String? = nil,
    strategicGrade: String? = nil
) -> GameRecord {
    let record = GameRecord(context: manager.viewContext)
    record.id = UUID()
    record.score = Int32(score)
    record.difficulty = difficulty.rawValue
    record.blocksPlaced = Int32(blocksPlaced)
    record.linesCleared = Int32(linesCleared)
    record.longestCombo = Int32(longestCombo)
    record.gameTime = gameTime
    record.date = date
    record.averageGridEfficiency = averageGridEfficiency
    record.averageFragmentation = averageFragmentation
    record.strategicPlayRating = strategicPlayRating
    record.challengeMaintained = challengeMaintained
    record.fallbackActivations = Int32(fallbackActivations)
    record.efficiencyGrade = efficiencyGrade
    record.strategicGrade = strategicGrade
    return record
}

// MARK: - Happy Path

@Suite("GameSession(record:): happy path")
struct GameSessionFromRecordHappyPathTests {
    @Test @MainActor
    func mapsAllRequiredFields() {
        let manager = CoreDataManager.makeInMemoryForTests()
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let record = makeRecord(
            in: manager,
            score: 1_234,
            difficulty: .hard,
            blocksPlaced: 42,
            linesCleared: 7,
            longestCombo: 3,
            gameTime: 180,
            date: date
        )

        let session = GameSession(record: record)

        #expect(session?.date == date)
        #expect(session?.score == 1_234)
        #expect(session?.difficulty == .hard)
        #expect(session?.blocksPlaced == 42)
        #expect(session?.linesCleared == 7)
        #expect(session?.gameTime == 180)
    }

    @Test @MainActor
    func mapsOptionalEfficiencyMetricsWhenPresent() {
        let manager = CoreDataManager.makeInMemoryForTests()
        let record = makeRecord(
            in: manager,
            averageGridEfficiency: 0.75,
            averageFragmentation: 0.4,
            strategicPlayRating: 0.6,
            challengeMaintained: 0.5,
            efficiencyGrade: "grade_a_plus",
            strategicGrade: "grade_master"
        )

        let session = GameSession(record: record)

        #expect(session?.averageGridEfficiency == 0.75)
        #expect(session?.averageFragmentation == 0.4)
        #expect(session?.strategicPlayRating == 0.6)
        #expect(session?.challengeMaintained == 0.5)
        #expect(session?.efficiencyGrade == "grade_a_plus")
        #expect(session?.strategicGrade == "grade_master")
    }
}

// MARK: - Optional Coercion

@Suite("GameSession(record:): optional coercion")
struct GameSessionFromRecordOptionalCoercionTests {
    @Test @MainActor
    func zeroEfficiencyMetricsBecomeNil() {
        // Records pre-dating the efficiency feature default these to 0.
        // The session model treats them as "absent" rather than "0%".
        let manager = CoreDataManager.makeInMemoryForTests()
        let record = makeRecord(in: manager) // all efficiency fields = 0

        let session = GameSession(record: record)

        #expect(session?.averageGridEfficiency == nil)
        #expect(session?.averageFragmentation == nil)
        #expect(session?.strategicPlayRating == nil)
        #expect(session?.challengeMaintained == nil)
    }

    @Test @MainActor
    func emptyStringGradesBecomeNil() {
        let manager = CoreDataManager.makeInMemoryForTests()
        let record = makeRecord(in: manager, efficiencyGrade: "", strategicGrade: "")

        let session = GameSession(record: record)

        #expect(session?.efficiencyGrade == nil)
        #expect(session?.strategicGrade == nil)
    }

    @Test @MainActor
    func zeroFallbackActivationsBecomesNil() {
        // Mirror the convention used for the Double metrics: a stored 0
        // means "no fallbacks triggered" or "field absent on this record"
        // — either way, surface as nil so the UI hides the field rather
        // than rendering "0 fallbacks" with no in-band signal that the
        // datum is meaningless.
        let manager = CoreDataManager.makeInMemoryForTests()
        let record = makeRecord(in: manager, fallbackActivations: 0)

        let session = GameSession(record: record)

        #expect(session?.fallbackActivations == nil)
    }
}

// MARK: - Fallback Activations (R1)

@Suite("GameSession(record:): fallbackActivations projection")
struct GameSessionFromRecordFallbackActivationsTests {
    @Test @MainActor
    func fallbackActivationsCarryThroughTheProjection() {
        // R1 regression: the projection used to hardcode `nil` here, so
        // every persisted run reported `fallbackActivations == nil`
        // regardless of what CoreDataManager.saveGameRecord wrote.
        // History / Summary screens that show fallback counts therefore
        // silently displayed nothing. Round 3 fix: thread the column
        // through with the same "zero means absent" convention as the
        // neighboring Double metrics.
        let manager = CoreDataManager.makeInMemoryForTests()
        let record = makeRecord(in: manager, fallbackActivations: 3)

        let session = GameSession(record: record)

        #expect(session?.fallbackActivations == 3)
    }
}

// MARK: - Failure Modes

@Suite("GameSession(record:): rejects invalid records")
struct GameSessionFromRecordFailureTests {
    @Test @MainActor
    func returnsNilWhenDateIsMissing() {
        let manager = CoreDataManager.makeInMemoryForTests()
        let record = makeRecord(in: manager)
        record.date = nil

        #expect(GameSession(record: record) == nil)
    }

    @Test @MainActor
    func returnsNilWhenDifficultyIsMissing() {
        let manager = CoreDataManager.makeInMemoryForTests()
        let record = makeRecord(in: manager)
        record.difficulty = nil

        #expect(GameSession(record: record) == nil)
    }

    @Test @MainActor
    func returnsNilWhenDifficultyIsUnknown() {
        let manager = CoreDataManager.makeInMemoryForTests()
        let record = makeRecord(in: manager)
        record.difficulty = "impossible"

        #expect(GameSession(record: record) == nil)
    }
}
