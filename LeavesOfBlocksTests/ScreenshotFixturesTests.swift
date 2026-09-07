//
//  ScreenshotFixturesTests.swift
//  LeavesOfBlocksTests
//
//  The fixture the App Store screenshots pose against.
//

import Foundation
import Testing

@testable import LeavesOfBlocks

@Suite("Screenshot fixtures")
@MainActor
struct ScreenshotFixturesTests {

    private func installedRecord() async -> GameRecord? {
        let manager = CoreDataManager.makeInMemoryForTests()
        await ScreenshotFixtures.install(into: manager)
        return manager.fetchGameHistory().first
    }

    // The screenshots are the app's shop window, so the session they pose
    // against has to be one the app could actually produce. It was not: the
    // grades were typed in beside the metrics rather than derived from them,
    // and both disagreed with the ladders in PlayerBehaviorTracker — the
    // Strategy card showed a letter grade, which that ladder never returns.
    @Test("The fixture's grades are the ones its metrics would earn")
    func gradesAgreeWithTheMetricsBesideThem() async throws {
        let record = try #require(await installedRecord())

        let metrics = PlayerBehaviorTracker.SessionMetrics(
            score: Int(record.score),
            blocksPlaced: Int(record.blocksPlaced),
            linesCleared: Int(record.linesCleared),
            longestCombo: Int(record.longestCombo),
            gameTime: record.gameTime,
            difficulty: DifficultyMode(rawValue: record.difficulty ?? "") ?? .easy,
            averageGridEfficiency: record.averageGridEfficiency,
            averageFragmentation: record.averageFragmentation,
            strategicPlayRating: record.strategicPlayRating,
            fallbackActivations: Int(record.fallbackActivations),
            challengeMaintained: record.challengeMaintained
        )

        #expect(
            record.efficiencyGrade == metrics.efficiencyGrade,
            "efficiency \(record.averageGridEfficiency) earns \(metrics.efficiencyGrade), fixture says \(record.efficiencyGrade ?? "nil")"
        )
        #expect(
            record.strategicGrade == metrics.strategicGrade,
            "strategic play \(record.strategicPlayRating) earns \(metrics.strategicGrade), fixture says \(record.strategicGrade ?? "nil")"
        )
    }

    // The two ladders are different sets of words. A letter in the strategy
    // slot is not merely the wrong grade, it is a value from the other ladder
    // — and it meant no screenshot in any language ever showed the word ladder
    // that #114 through #117 translated.
    @Test("The strategy grade comes from the strategy ladder")
    func strategicGradeIsAWordGrade() async throws {
        let record = try #require(await installedRecord())
        let wordGrades = ["grade_master", "grade_expert", "grade_skilled", "grade_learning", "grade_beginner"]

        #expect(
            wordGrades.contains(record.strategicGrade ?? ""),
            "\(record.strategicGrade ?? "nil") is not on the strategy ladder"
        )
    }
}
