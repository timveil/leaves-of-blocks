//
//  GameStatisticsTests.swift
//  LeavesOfBlocksTests
//
//  Tests for GameSessionStatistics-derived metrics: averages, percentages,
//  rates, performance grades, and time formatting.
//

import Foundation
import Testing
@testable import LeavesOfBlocks

// MARK: - Helpers

private func statistics(
    score: Int = 0,
    blocksPlaced: Int = 0,
    linesCleared: Int = 0,
    gameTime: TimeInterval = 0,
    longestCombo: Int = 0,
    currentCombo: Int = 0,
    difficulty: DifficultyMode = .easy
) -> GameSessionStatistics {
    GameSessionStatistics(
        score: score,
        blocksPlaced: blocksPlaced,
        linesCleared: linesCleared,
        gameTime: gameTime,
        longestCombo: longestCombo,
        currentCombo: currentCombo,
        difficulty: difficulty
    )
}

// MARK: - Average Block Score

@Suite("GameSessionStatistics.averageBlockScore")
struct AverageBlockScoreTests {
    @Test("Score divided by blocks placed")
    func scoreDividedByBlocksPlaced() {
        let stats = statistics(score: 100, blocksPlaced: 10)
        #expect(stats.averageBlockScore == 10.0)
    }

    @Test("Returns zero when no blocks placed (avoid divide-by-zero)")
    func returnsZeroWhenNoBlocksPlaced() {
        #expect(statistics().averageBlockScore == 0.0)
    }

    @Test("Handles large scores")
    func handlesLargeScores() {
        let stats = statistics(score: 10_000, blocksPlaced: 50, difficulty: .hard)
        #expect(stats.averageBlockScore == 200.0)
    }
}

// MARK: - Line Clear Percentage

@Suite("GameSessionStatistics.lineClearPercentage")
struct LineClearPercentageTests {
    @Test("Lines per block as a percentage")
    func linesPerBlockAsAPercentage() {
        let stats = statistics(score: 100, blocksPlaced: 10, linesCleared: 5)
        #expect(stats.lineClearPercentage == 50.0)
    }

    @Test("Returns zero when no blocks placed")
    func returnsZeroWhenNoBlocksPlaced() {
        #expect(statistics().lineClearPercentage == 0.0)
    }
}

// MARK: - Score Per Minute

@Suite("GameSessionStatistics.scorePerMinute")
struct ScorePerMinuteTests {
    @Test("Score equals SPM when exactly one minute elapsed")
    func scoreEqualsSPMWhenExactlyOneMinuteElapsed() {
        let stats = statistics(score: 600, gameTime: 60)
        #expect(stats.scorePerMinute == 600.0)
    }

    @Test("SPM scales correctly over multiple minutes")
    func spmScalesCorrectlyOverMultipleMinutes() {
        let stats = statistics(score: 1200, gameTime: 120, difficulty: .moderate)
        #expect(stats.scorePerMinute == 600.0)
    }

    @Test("Returns zero when no time elapsed (avoid divide-by-zero)")
    func returnsZeroWhenNoTimeElapsed() {
        let stats = statistics(score: 100, gameTime: 0)
        #expect(stats.scorePerMinute == 0.0)
    }
}

// MARK: - Performance Grade

@Suite("GameSessionStatistics.performanceGrade")
struct PerformanceGradeTests {
    @Test("Top-tier efficiency yields S")
    func topTierEfficiencyYieldsS() {
        let stats = statistics(
            score: 60_000, blocksPlaced: 100, linesCleared: 600,
            gameTime: 60, longestCombo: 10, difficulty: .hard
        )
        #expect(stats.performanceGrade == "S")
    }

    @Test("Bottom-tier efficiency yields F")
    func bottomTierEfficiencyYieldsF() {
        let stats = statistics(
            score: 10, blocksPlaced: 1, linesCleared: 0,
            gameTime: 600
        )
        #expect(stats.performanceGrade == "F")
    }
}

// MARK: - Formatted Game Time

@Suite("GameSessionStatistics.formattedGameTime")
struct FormattedGameTimeTests {
    @Test("Under one minute renders as 0:SS")
    func underOneMinuteRendersAs0SS() {
        let stats = statistics(score: 100, blocksPlaced: 5, gameTime: 45)
        #expect(stats.formattedGameTime == "0:45")
    }

    @Test("Exactly one minute renders as 1:00")
    func exactlyOneMinuteRendersAs100() {
        let stats = statistics(score: 100, blocksPlaced: 5, gameTime: 60)
        #expect(stats.formattedGameTime == "1:00")
    }

    @Test("Multiple minutes render as M:SS")
    func multipleMinutesRenderAsMSS() {
        let stats = statistics(
            score: 500, blocksPlaced: 25, linesCleared: 10,
            gameTime: 185, longestCombo: 3, difficulty: .moderate
        )
        #expect(stats.formattedGameTime == "3:05")
    }
}
