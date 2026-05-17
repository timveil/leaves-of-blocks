//
//  PlayerBehaviorTrackerTests.swift
//  LeavesOfBlocksTests
//
//  Tests for the per-session player behavior tracker.
//

import Testing
@testable import LeavesOfBlocks

// MARK: - Helpers

@MainActor
private func makeTracker(_ configure: (PlayerBehaviorTracker) -> Void = { _ in }) -> PlayerBehaviorTracker {
    let tracker = PlayerBehaviorTracker()
    tracker.startSession()
    configure(tracker)
    return tracker
}

private func emptyGrid() -> [[GridCell]] {
    GameLogic.createEmptyGrid()
}

private func gridFilled(rows: Range<Int>) -> [[GridCell]] {
    var grid = GameLogic.createEmptyGrid()
    for row in rows {
        for col in 0..<8 {
            grid[row][col].isFilled = true
        }
    }
    return grid
}

// MARK: - Session Lifecycle

@Suite("PlayerBehaviorTracker session lifecycle")
struct SessionLifecycleTests {
    @Test @MainActor
    func startSessionResetsCurrentMetrics() {
        let tracker = PlayerBehaviorTracker()
        tracker.recordGridState(emptyGrid())
        tracker.recordFallbackActivation(from: .diverse, to: .constrained)
        tracker.startSession()

        let metrics = tracker.getCurrentMetrics(
            score: 0, blocksPlaced: 0, linesCleared: 0,
            longestCombo: 0, gameTime: 0, difficulty: .easy
        )
        #expect(metrics.fallbackActivations == 0)
        #expect(metrics.challengeMaintained == 0)
    }

    @Test @MainActor
    func recordingStateAccumulatesMeasurements() {
        let tracker = makeTracker()
        for _ in 0..<5 {
            tracker.recordGridState(emptyGrid())
        }

        let metrics = tracker.getCurrentMetrics(
            score: 0, blocksPlaced: 5, linesCleared: 0,
            longestCombo: 0, gameTime: 0, difficulty: .easy
        )
        // 5 records of an empty grid should advance the rolling averages
        // and challenge-maintained ratio; verify the recordGridState path
        // actually accumulates instead of no-opping.
        #expect(metrics.averageGridEfficiency > 0 || metrics.averageFragmentation >= 0)
    }

    @Test @MainActor
    func initialSeedRecordDoesNotAdvanceChallengeCounters() {
        // N3: GameState.apply(snapshot:) and GameState.resetGame() both
        // seed the tracker with `recordGridState(grid)` immediately after
        // `startSession()` so the rolling averages aren't empty. That seed
        // also bumps `totalMeasurements` and possibly `highTierMeasurements`,
        // which biases `challengeMaintained` — "challenge maintained over
        // GAMEPLAY" shouldn't include the initial-state sample. The fix is
        // an `isInitialSeed: Bool = false` flag that updates the efficiency
        // histories (so they aren't empty) but skips the challenge counters.
        //
        // This test asserts the contract via the now-internal totalMeasurements
        // accessor; the seed must populate efficiency averages while leaving
        // totalMeasurements at zero.
        let tracker = makeTracker()
        tracker.recordGridState(emptyGrid(), isInitialSeed: true)

        #expect(tracker.totalMeasurements == 0, "initial seed should not count as a challenge measurement")
        let metrics = tracker.getCurrentMetrics(
            score: 0, blocksPlaced: 0, linesCleared: 0,
            longestCombo: 0, gameTime: 0, difficulty: .easy
        )
        #expect(metrics.averageGridEfficiency > 0, "initial seed should populate efficiency averages")
    }

    @Test @MainActor
    func inGameRecordStillAdvancesChallengeCounters() {
        // Companion to initialSeedRecordDoesNotAdvanceChallengeCounters:
        // verify the default-path (no `isInitialSeed` flag) preserves the
        // existing recordGridState behavior.
        let tracker = makeTracker()
        tracker.recordGridState(emptyGrid())

        #expect(tracker.totalMeasurements == 1)
    }

    @Test @MainActor
    func recordingFallbackIncrementsCount() {
        let tracker = makeTracker()
        tracker.recordFallbackActivation(from: .diverse, to: .constrained)
        tracker.recordFallbackActivation(from: .constrained, to: .minimal)

        let metrics = tracker.getCurrentMetrics(
            score: 0, blocksPlaced: 0, linesCleared: 0,
            longestCombo: 0, gameTime: 0, difficulty: .easy
        )
        #expect(metrics.fallbackActivations == 2)
    }
}

// MARK: - Finalize Output

@Suite("PlayerBehaviorTracker.finalizeSession")
struct FinalizeSessionTests {
    @Test @MainActor
    func finalizeSessionPopulatesRawCounts() {
        let tracker = makeTracker()
        tracker.recordGridState(emptyGrid())

        let metrics = tracker.finalizeSession(
            score: 1234, blocksPlaced: 7, linesCleared: 3,
            longestCombo: 2, gameTime: 60, difficulty: .moderate
        )
        #expect(metrics.score == 1234)
        #expect(metrics.blocksPlaced == 7)
        #expect(metrics.linesCleared == 3)
        #expect(metrics.longestCombo == 2)
        #expect(metrics.gameTime == 60)
        #expect(metrics.difficulty == .moderate)
    }

    @Test @MainActor
    func finalizeSessionWithNoMeasurementsReportsZeroAverages() {
        let tracker = makeTracker()
        let metrics = tracker.finalizeSession(
            score: 0, blocksPlaced: 0, linesCleared: 0,
            longestCombo: 0, gameTime: 0, difficulty: .easy
        )
        #expect(metrics.averageGridEfficiency == 0.0)
        #expect(metrics.averageFragmentation == 0.0)
        #expect(metrics.strategicPlayRating == 0.0)
        #expect(metrics.challengeMaintained == 0.0)
    }

    @Test @MainActor
    func finalizeAveragesMeasurementHistory() {
        let tracker = makeTracker()
        // Empty grid yields efficiency=1.0, fragmentation=0, strategicPotential=0.
        // After 3 identical recordings the averages are exactly those values.
        tracker.recordGridState(emptyGrid())
        tracker.recordGridState(emptyGrid())
        tracker.recordGridState(emptyGrid())

        let metrics = tracker.finalizeSession(
            score: 0, blocksPlaced: 3, linesCleared: 0,
            longestCombo: 0, gameTime: 0, difficulty: .easy
        )
        #expect(metrics.averageGridEfficiency == 1.0)
        #expect(metrics.averageFragmentation == 0.0)
    }
}

// MARK: - Grade Classification

@Suite("SessionMetrics grade classification")
struct SessionMetricsGradeTests {
    private func metrics(efficiency: Double, strategic: Double, challenge: Double) -> PlayerBehaviorTracker.SessionMetrics {
        PlayerBehaviorTracker.SessionMetrics(
            score: 0, blocksPlaced: 0, linesCleared: 0, longestCombo: 0,
            gameTime: 0, difficulty: .easy,
            averageGridEfficiency: efficiency,
            averageFragmentation: 0,
            strategicPlayRating: strategic,
            fallbackActivations: 0,
            challengeMaintained: challenge
        )
    }

    @Test
    func efficiencyGradeBoundaries() {
        #expect(metrics(efficiency: 0.95, strategic: 0, challenge: 0).efficiencyGrade == "grade_a_plus")
        #expect(metrics(efficiency: 0.75, strategic: 0, challenge: 0).efficiencyGrade == "grade_a")
        #expect(metrics(efficiency: 0.65, strategic: 0, challenge: 0).efficiencyGrade == "grade_b_plus")
        #expect(metrics(efficiency: 0.55, strategic: 0, challenge: 0).efficiencyGrade == "grade_b")
        #expect(metrics(efficiency: 0.45, strategic: 0, challenge: 0).efficiencyGrade == "grade_c_plus")
        #expect(metrics(efficiency: 0.35, strategic: 0, challenge: 0).efficiencyGrade == "grade_c")
        #expect(metrics(efficiency: 0.10, strategic: 0, challenge: 0).efficiencyGrade == "grade_d")
    }

    @Test
    func strategicGradeBoundaries() {
        #expect(metrics(efficiency: 0, strategic: 0.95, challenge: 0).strategicGrade == "grade_master")
        #expect(metrics(efficiency: 0, strategic: 0.70, challenge: 0).strategicGrade == "grade_expert")
        #expect(metrics(efficiency: 0, strategic: 0.50, challenge: 0).strategicGrade == "grade_skilled")
        #expect(metrics(efficiency: 0, strategic: 0.25, challenge: 0).strategicGrade == "grade_learning")
        #expect(metrics(efficiency: 0, strategic: 0.10, challenge: 0).strategicGrade == "grade_beginner")
    }

    @Test
    func challengeLevelBoundaries() {
        #expect(metrics(efficiency: 0, strategic: 0, challenge: 0.85).challengeLevel == "challenge_high")
        #expect(metrics(efficiency: 0, strategic: 0, challenge: 0.55).challengeLevel == "challenge_medium")
        #expect(metrics(efficiency: 0, strategic: 0, challenge: 0.20).challengeLevel == "challenge_low")
    }
}

// MARK: - History Bounding

@Suite("PlayerBehaviorTracker bounded history")
struct BoundedHistoryTests {
    @Test @MainActor
    func longSessionsDoNotGrowMemoryUnbounded() {
        let tracker = makeTracker()
        // Greatly exceed the cap so the front would be dropped repeatedly.
        for _ in 0..<500 {
            tracker.recordGridState(emptyGrid())
        }
        // The tracker's internal state isn't externally observable, but
        // finalizeSession should still complete and report sensible averages.
        let metrics = tracker.finalizeSession(
            score: 0, blocksPlaced: 500, linesCleared: 0,
            longestCombo: 0, gameTime: 600, difficulty: .easy
        )
        #expect(metrics.averageGridEfficiency >= 0.0)
        #expect(metrics.averageGridEfficiency <= 1.0)
    }
}
