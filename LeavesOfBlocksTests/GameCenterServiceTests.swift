//
//  GameCenterServiceTests.swift
//  LeavesOfBlocksTests
//
//  Tests for the Game Center achievement evaluator and the opt-in preference.
//  GameKit-backed paths (auth, score submit, dashboard present) are intentionally
//  not exercised here — they require a sandboxed Apple ID and are covered by
//  manual TestFlight verification.
//

import Foundation
import Testing
@testable import LeavesOfBlocks

// MARK: - Helpers

private func metrics(
    score: Int = 0,
    blocksPlaced: Int = 0,
    linesCleared: Int = 0,
    longestCombo: Int = 0,
    averageGridEfficiency: Double = 0,
    strategicPlayRating: Double = 0
) -> PlayerBehaviorTracker.SessionMetrics {
    PlayerBehaviorTracker.SessionMetrics(
        score: score,
        blocksPlaced: blocksPlaced,
        linesCleared: linesCleared,
        longestCombo: longestCombo,
        gameTime: 0,
        difficulty: .moderate,
        averageGridEfficiency: averageGridEfficiency,
        averageFragmentation: 0,
        strategicPlayRating: strategicPlayRating,
        fallbackActivations: 0,
        challengeMaintained: 0
    )
}

// MARK: - Achievement Evaluator

@Suite("GameCenterService.evaluateAchievements")
struct GameCenterAchievementEvaluatorTests {

    @Test
    func emptySessionEarnsNothing() {
        let result = GameCenterService.evaluateAchievements(
            score: 0,
            sessionMetrics: nil,
            longestCombo: 0
        )
        #expect(result.isEmpty)
    }

    @Test
    func clearingASingleLineEarnsFirstClear() {
        let result = GameCenterService.evaluateAchievements(
            score: 100,
            sessionMetrics: metrics(linesCleared: 1),
            longestCombo: 1
        )
        #expect(result.contains(PendingAchievement(
            identifier: GameCenterIDs.Achievements.firstClear,
            percentComplete: 100
        )))
    }

    @Test
    func combo4EarnsComboAchievement() {
        let result = GameCenterService.evaluateAchievements(
            score: 500,
            sessionMetrics: metrics(linesCleared: 8),
            longestCombo: 4
        )
        #expect(result.contains(PendingAchievement(
            identifier: GameCenterIDs.Achievements.combo4,
            percentComplete: 100
        )))
    }

    @Test
    func combo3DoesNotEarnComboAchievement() {
        let result = GameCenterService.evaluateAchievements(
            score: 500,
            sessionMetrics: metrics(linesCleared: 5),
            longestCombo: 3
        )
        #expect(!result.contains(where: { $0.identifier == GameCenterIDs.Achievements.combo4 }))
    }

    @Test
    func gradeAPlusEarnsEfficiencyAchievement() {
        // efficiencyGrade derives from averageGridEfficiency; >= 0.8 → grade_a_plus
        let result = GameCenterService.evaluateAchievements(
            score: 1000,
            sessionMetrics: metrics(linesCleared: 10, averageGridEfficiency: 0.85),
            longestCombo: 1
        )
        #expect(result.contains(PendingAchievement(
            identifier: GameCenterIDs.Achievements.efficiencyAPlus,
            percentComplete: 100
        )))
    }

    @Test
    func gradeMasterEarnsStrategicAchievement() {
        // strategicGrade derives from strategicPlayRating; >= 0.8 → grade_master
        let result = GameCenterService.evaluateAchievements(
            score: 1000,
            sessionMetrics: metrics(linesCleared: 10, strategicPlayRating: 0.9),
            longestCombo: 1
        )
        #expect(result.contains(PendingAchievement(
            identifier: GameCenterIDs.Achievements.strategicMaster,
            percentComplete: 100
        )))
    }

    @Test
    func score10kEarnsScoreAchievement() {
        let result = GameCenterService.evaluateAchievements(
            score: 10_000,
            sessionMetrics: metrics(score: 10_000, linesCleared: 5),
            longestCombo: 2
        )
        #expect(result.contains(PendingAchievement(
            identifier: GameCenterIDs.Achievements.score10k,
            percentComplete: 100
        )))
    }

    @Test
    func scoreUnder10kSkipsScoreAchievement() {
        let result = GameCenterService.evaluateAchievements(
            score: 9_999,
            sessionMetrics: metrics(score: 9_999, linesCleared: 5),
            longestCombo: 2
        )
        #expect(!result.contains(where: { $0.identifier == GameCenterIDs.Achievements.score10k }))
    }

    @Test
    func multipleAchievementsCanCoexist() {
        let result = GameCenterService.evaluateAchievements(
            score: 12_000,
            sessionMetrics: metrics(
                score: 12_000,
                linesCleared: 20,
                averageGridEfficiency: 0.9,
                strategicPlayRating: 0.85
            ),
            longestCombo: 5
        )
        let identifiers = Set(result.map(\.identifier))
        #expect(identifiers == Set([
            GameCenterIDs.Achievements.firstClear,
            GameCenterIDs.Achievements.combo4,
            GameCenterIDs.Achievements.efficiencyAPlus,
            GameCenterIDs.Achievements.strategicMaster,
            GameCenterIDs.Achievements.score10k
        ]))
    }
}

// MARK: - Opt-In Preference

@Suite("GameCenterPreference round-trip", .serialized)
struct GameCenterPreferenceTests {

    @Test
    func defaultsToFalseWhenUnset() {
        // Save and reset to ensure a clean read.
        let original = GameCenterPreference.isEnabled
        defer { GameCenterPreference.isEnabled = original }

        UserDefaults.standard.removeObject(forKey: "gameCenter.enabled")
        #expect(GameCenterPreference.isEnabled == false)
    }

    @Test
    func setterPersistsToUserDefaults() {
        let original = GameCenterPreference.isEnabled
        defer { GameCenterPreference.isEnabled = original }

        GameCenterPreference.isEnabled = true
        #expect(GameCenterPreference.isEnabled == true)

        GameCenterPreference.isEnabled = false
        #expect(GameCenterPreference.isEnabled == false)
    }
}

// MARK: - Service No-Op Behavior

@Suite("GameCenterService no-op gating")
struct GameCenterServiceNoOpTests {

    /// When the preference is off and the player is not authenticated,
    /// `submitFinalScore` must not crash and must complete synchronously.
    @Test @MainActor
    func submitWithPreferenceOffIsHarmless() {
        let original = GameCenterPreference.isEnabled
        defer { GameCenterPreference.isEnabled = original }

        GameCenterPreference.isEnabled = false
        // Should not crash, throw, or hit GameKit. We can't directly assert "no
        // network call was made", but the absence of a crash plus the fact that
        // the singleton's isAuthenticated remains false is sufficient.
        GameCenterService.shared.submitFinalScore(
            score: 1_000,
            sessionMetrics: metrics(linesCleared: 5),
            longestCombo: 2
        )
        #expect(GameCenterService.shared.isAuthenticated == false)
    }
}
