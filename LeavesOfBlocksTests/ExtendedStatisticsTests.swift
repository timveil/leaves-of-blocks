//
//  ExtendedStatisticsTests.swift
//  LeavesOfBlocksTests
//
//  Tests for the pure aggregation that powers the Statistics screen.
//

import Foundation
import Testing
@testable import LeavesOfBlocks

// MARK: - Helpers

private func snapshot(
    score: Int = 0,
    difficulty: DifficultyMode? = nil,
    blocksPlaced: Int = 0,
    linesCleared: Int = 0,
    longestCombo: Int = 0,
    gameTime: TimeInterval = 0,
    date: Date? = nil,
    averageGridEfficiency: Double = 0,
    efficiencyGrade: String? = nil
) -> GameRecordSnapshot {
    GameRecordSnapshot(
        score: score,
        difficulty: difficulty?.rawValue,
        blocksPlaced: blocksPlaced,
        linesCleared: linesCleared,
        longestCombo: longestCombo,
        gameTime: gameTime,
        date: date,
        averageGridEfficiency: averageGridEfficiency,
        efficiencyGrade: efficiencyGrade
    )
}

// 2023-11-14 12:00:00 UTC. Anchored at noon UTC so the small same-day offset
// stays within the same calendar day under any reasonable host time zone.
// (CI runs on macos-latest in UTC; the previous 22:13:20 UTC anchor put
// `day1` and `day1Later` on different UTC calendar days.)
private let day1 = Date(timeIntervalSince1970: 1_699_963_200)              // anchor (noon UTC)
private let day1Later = day1.addingTimeInterval(60 * 60)                   // same day, 1h later
private let day2 = day1.addingTimeInterval(24 * 60 * 60)                   // 1 day later
private let day3 = day1.addingTimeInterval(48 * 60 * 60)                   // 2 days later

// MARK: - Empty store

@Suite("ExtendedStatistics on empty input")
struct ExtendedStatisticsEmptyTests {
    @Test
    func emptyInputReturnsAllZeros() {
        let stats = ExtendedStatistics.aggregate([])

        #expect(stats.totalGames == 0)
        #expect(stats.highScore == 0)
        #expect(stats.bestCombo == 0)
        #expect(stats.mostLinesInGame == 0)
        #expect(stats.longestGameTime == 0)
        #expect(stats.totalPlayTime == 0)
        #expect(stats.daysPlayed == 0)
        #expect(stats.favoriteDifficulty == nil)
        #expect(stats.averageEfficiency == 0)
        #expect(stats.typicalEfficiencyGradeKey == nil)
    }
}

// MARK: - Records

@Suite("ExtendedStatistics records")
struct ExtendedStatisticsRecordsTests {
    @Test
    func bestComboIsTheMaxAcrossGames() {
        let snaps = [
            snapshot(longestCombo: 2),
            snapshot(longestCombo: 5),
            snapshot(longestCombo: 3)
        ]
        #expect(ExtendedStatistics.aggregate(snaps).bestCombo == 5)
    }

    @Test
    func mostLinesInGameIsTheMaxAcrossGames() {
        let snaps = [
            snapshot(linesCleared: 12),
            snapshot(linesCleared: 4),
            snapshot(linesCleared: 18)
        ]
        #expect(ExtendedStatistics.aggregate(snaps).mostLinesInGame == 18)
    }

    @Test
    func longestGameTimeIsTheMaxAcrossGames() {
        let snaps = [
            snapshot(gameTime: 90),
            snapshot(gameTime: 240),
            snapshot(gameTime: 150)
        ]
        #expect(ExtendedStatistics.aggregate(snaps).longestGameTime == 240)
    }
}

// MARK: - Activity

@Suite("ExtendedStatistics activity")
struct ExtendedStatisticsActivityTests {
    @Test
    func totalPlayTimeIsTheSum() {
        let snaps = [
            snapshot(gameTime: 60),
            snapshot(gameTime: 90),
            snapshot(gameTime: 30)
        ]
        #expect(ExtendedStatistics.aggregate(snaps).totalPlayTime == 180)
    }

    @Test
    func daysPlayedCollapsesSameDayRecords() {
        let snaps = [
            snapshot(date: day1),
            snapshot(date: day1Later), // same day as day1
            snapshot(date: day2),
            snapshot(date: day3)
        ]
        #expect(ExtendedStatistics.aggregate(snaps).daysPlayed == 3)
    }

    @Test
    func daysPlayedIgnoresMissingDates() {
        let snaps = [
            snapshot(date: day1),
            snapshot(date: nil),
            snapshot(date: day2)
        ]
        #expect(ExtendedStatistics.aggregate(snaps).daysPlayed == 2)
    }

    @Test
    func favoriteDifficultyIsTheModalValue() {
        let snaps = [
            snapshot(difficulty: .easy),
            snapshot(difficulty: .moderate),
            snapshot(difficulty: .moderate),
            snapshot(difficulty: .hard)
        ]
        #expect(ExtendedStatistics.aggregate(snaps).favoriteDifficulty == .moderate)
    }

    @Test
    func favoriteDifficultyIsNilWhenNoneRecorded() {
        let snaps = [
            snapshot(difficulty: nil),
            snapshot(difficulty: nil)
        ]
        #expect(ExtendedStatistics.aggregate(snaps).favoriteDifficulty == nil)
    }
}

// MARK: - Skill

@Suite("ExtendedStatistics skill")
struct ExtendedStatisticsSkillTests {
    @Test
    func averageEfficiencyIsTheMeanOfNonZeroSamples() {
        let snaps = [
            snapshot(averageGridEfficiency: 0.5),
            snapshot(averageGridEfficiency: 0.7),
            snapshot(averageGridEfficiency: 0.9)
        ]
        let stats = ExtendedStatistics.aggregate(snaps)
        #expect(abs(stats.averageEfficiency - 0.7) < 0.0001)
    }

    @Test
    func averageEfficiencyIgnoresZeroLegacyRows() {
        let snaps = [
            snapshot(averageGridEfficiency: 0),     // legacy row with no analytics
            snapshot(averageGridEfficiency: 0.6),
            snapshot(averageGridEfficiency: 0.8)
        ]
        let stats = ExtendedStatistics.aggregate(snaps)
        #expect(abs(stats.averageEfficiency - 0.7) < 0.0001)
    }

    @Test
    func averageEfficiencyIsZeroWhenNoSamplesAvailable() {
        let snaps = [
            snapshot(averageGridEfficiency: 0),
            snapshot(averageGridEfficiency: 0)
        ]
        #expect(ExtendedStatistics.aggregate(snaps).averageEfficiency == 0)
    }

    @Test
    func typicalEfficiencyGradeIsTheModalKey() {
        let snaps = [
            snapshot(efficiencyGrade: "grade_a_plus"),
            snapshot(efficiencyGrade: "grade_a"),
            snapshot(efficiencyGrade: "grade_a_plus"),
            snapshot(efficiencyGrade: "grade_b")
        ]
        #expect(ExtendedStatistics.aggregate(snaps).typicalEfficiencyGradeKey == "grade_a_plus")
    }

    @Test
    func typicalEfficiencyGradeMapsLegacyEnglishValues() {
        let snaps = [
            snapshot(efficiencyGrade: "A+"),     // legacy
            snapshot(efficiencyGrade: "grade_a_plus"),
            snapshot(efficiencyGrade: "grade_b")
        ]
        // A+ collapses to "grade_a_plus", giving it 2 occurrences vs grade_b's 1.
        #expect(ExtendedStatistics.aggregate(snaps).typicalEfficiencyGradeKey == "grade_a_plus")
    }

    @Test
    func typicalEfficiencyGradeIgnoresNilAndEmptyValues() {
        let snaps = [
            snapshot(efficiencyGrade: nil),
            snapshot(efficiencyGrade: ""),
            snapshot(efficiencyGrade: "grade_b")
        ]
        #expect(ExtendedStatistics.aggregate(snaps).typicalEfficiencyGradeKey == "grade_b")
    }
}

// MARK: - Basic counts

@Suite("ExtendedStatistics basic counts")
struct ExtendedStatisticsBasicTests {
    @Test
    func basicTotalsMatchInputs() {
        let snaps = [
            snapshot(score: 100, blocksPlaced: 10),
            snapshot(score: 250, blocksPlaced: 15),
            snapshot(score: 50, blocksPlaced: 5)
        ]
        let stats = ExtendedStatistics.aggregate(snaps)

        #expect(stats.totalGames == 3)
        #expect(stats.totalScore == 400)
        #expect(stats.averageScore == 133)  // 400 / 3 = 133 (integer division)
        #expect(stats.highScore == 250)
        #expect(stats.totalBlocksPlaced == 30)
    }
}
