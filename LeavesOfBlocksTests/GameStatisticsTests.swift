//
//  GameStatisticsTests.swift
//  LeavesOfBlocksTests
//
//  Created by Claude on 11/27/25.
//

import XCTest
@testable import LeavesOfBlocks

// MARK: - Average Block Score Tests

final class AverageBlockScoreTests: XCTestCase {

    func testAverageBlockScoreWithValidData() {
        let stats = GameSessionStatistics(
            score: 100,
            blocksPlaced: 10,
            linesCleared: 5,
            gameTime: 60,
            longestCombo: 2,
            currentCombo: 0,
            difficulty: .easy
        )

        XCTAssertEqual(stats.averageBlockScore, 10.0)
    }

    func testAverageBlockScoreReturnsZeroWhenNoBlocksPlaced() {
        let stats = GameSessionStatistics(
            score: 0,
            blocksPlaced: 0,
            linesCleared: 0,
            gameTime: 60,
            longestCombo: 0,
            currentCombo: 0,
            difficulty: .easy
        )

        XCTAssertEqual(stats.averageBlockScore, 0.0)
    }

    func testAverageBlockScoreHandlesLargeScore() {
        let stats = GameSessionStatistics(
            score: 10000,
            blocksPlaced: 50,
            linesCleared: 20,
            gameTime: 300,
            longestCombo: 5,
            currentCombo: 0,
            difficulty: .hard
        )

        XCTAssertEqual(stats.averageBlockScore, 200.0)
    }
}

// MARK: - Line Clear Percentage Tests

final class LineClearPercentageTests: XCTestCase {

    func testLineClearPercentageWithValidData() {
        let stats = GameSessionStatistics(
            score: 100,
            blocksPlaced: 10,
            linesCleared: 5,
            gameTime: 60,
            longestCombo: 2,
            currentCombo: 0,
            difficulty: .easy
        )

        XCTAssertEqual(stats.lineClearPercentage, 50.0)
    }

    func testLineClearPercentageReturnsZeroWhenNoBlocksPlaced() {
        let stats = GameSessionStatistics(
            score: 0,
            blocksPlaced: 0,
            linesCleared: 0,
            gameTime: 60,
            longestCombo: 0,
            currentCombo: 0,
            difficulty: .easy
        )

        XCTAssertEqual(stats.lineClearPercentage, 0.0)
    }
}

// MARK: - Score Per Minute Tests

final class ScorePerMinuteTests: XCTestCase {

    func testScorePerMinuteWithOneMinute() {
        let stats = GameSessionStatistics(
            score: 600,
            blocksPlaced: 10,
            linesCleared: 5,
            gameTime: 60,
            longestCombo: 2,
            currentCombo: 0,
            difficulty: .easy
        )

        XCTAssertEqual(stats.scorePerMinute, 600.0)
    }

    func testScorePerMinuteWithMultipleMinutes() {
        let stats = GameSessionStatistics(
            score: 1200,
            blocksPlaced: 20,
            linesCleared: 10,
            gameTime: 120,
            longestCombo: 3,
            currentCombo: 0,
            difficulty: .moderate
        )

        XCTAssertEqual(stats.scorePerMinute, 600.0)
    }

    func testScorePerMinuteReturnsZeroWhenNoTime() {
        let stats = GameSessionStatistics(
            score: 100,
            blocksPlaced: 5,
            linesCleared: 2,
            gameTime: 0,
            longestCombo: 1,
            currentCombo: 0,
            difficulty: .easy
        )

        XCTAssertEqual(stats.scorePerMinute, 0.0)
    }
}

// MARK: - Performance Grade Tests

final class PerformanceGradeTests: XCTestCase {

    func testPerformanceGradeS() {
        // Create stats that yield 90%+ efficiency
        let stats = GameSessionStatistics(
            score: 60000,
            blocksPlaced: 100,
            linesCleared: 600,
            gameTime: 60,
            longestCombo: 10,
            currentCombo: 0,
            difficulty: .hard
        )

        XCTAssertEqual(stats.performanceGrade, "S")
    }

    func testPerformanceGradeF() {
        // Create stats that yield low efficiency
        let stats = GameSessionStatistics(
            score: 10,
            blocksPlaced: 1,
            linesCleared: 0,
            gameTime: 600,
            longestCombo: 0,
            currentCombo: 0,
            difficulty: .easy
        )

        XCTAssertEqual(stats.performanceGrade, "F")
    }
}

// MARK: - Formatted Game Time Tests

final class FormattedGameTimeTests: XCTestCase {

    func testFormattedGameTimeUnderOneMinute() {
        let stats = GameSessionStatistics(
            score: 100,
            blocksPlaced: 5,
            linesCleared: 2,
            gameTime: 45,
            longestCombo: 1,
            currentCombo: 0,
            difficulty: .easy
        )

        XCTAssertEqual(stats.formattedGameTime, "0:45")
    }

    func testFormattedGameTimeExactMinute() {
        let stats = GameSessionStatistics(
            score: 100,
            blocksPlaced: 5,
            linesCleared: 2,
            gameTime: 60,
            longestCombo: 1,
            currentCombo: 0,
            difficulty: .easy
        )

        XCTAssertEqual(stats.formattedGameTime, "1:00")
    }

    func testFormattedGameTimeMultipleMinutes() {
        let stats = GameSessionStatistics(
            score: 500,
            blocksPlaced: 25,
            linesCleared: 10,
            gameTime: 185,
            longestCombo: 3,
            currentCombo: 0,
            difficulty: .moderate
        )

        XCTAssertEqual(stats.formattedGameTime, "3:05")
    }
}

