//
//  PendingGameCenterSubmissionStoreTests.swift
//  LeavesOfBlocksTests
//
//  H2: tests the durable retry store for Game Center submissions. Game Center
//  failures (network blips, transient GameKit errors) previously vanished
//  into a log line; the store keeps the unsubmitted score + achievement set
//  so the next authentication can replay them.
//

import Foundation
import Testing
@testable import LeavesOfBlocks

// MARK: - Helpers

@MainActor
private func makeIsolatedDefaults() -> UserDefaults {
    // Each test gets its own UserDefaults suite so they don't leak into the
    // user's real preferences (or into each other).
    let suite = "PendingGameCenterSubmissionStoreTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    return defaults
}

// MARK: - Empty State

@Suite("PendingGameCenterSubmissionStore: empty state")
struct PendingGameCenterSubmissionStoreEmptyTests {
    @Test @MainActor
    func pendingScoreIsZeroByDefault() {
        let store = PendingGameCenterSubmissionStore(defaults: makeIsolatedDefaults())
        #expect(store.pendingScore == 0)
    }

    @Test @MainActor
    func pendingAchievementIdentifiersIsEmptyByDefault() {
        let store = PendingGameCenterSubmissionStore(defaults: makeIsolatedDefaults())
        #expect(store.pendingAchievementIdentifiers.isEmpty)
    }
}

// MARK: - Score

@Suite("PendingGameCenterSubmissionStore: score")
struct PendingGameCenterSubmissionStoreScoreTests {
    @Test @MainActor
    func recordingAScoreSetsIt() {
        let store = PendingGameCenterSubmissionStore(defaults: makeIsolatedDefaults())
        store.recordScoreSubmission(500)
        #expect(store.pendingScore == 500)
    }

    @Test @MainActor
    func recordingKeepsTheHighestScore() {
        let store = PendingGameCenterSubmissionStore(defaults: makeIsolatedDefaults())
        store.recordScoreSubmission(500)
        store.recordScoreSubmission(200)
        store.recordScoreSubmission(750)
        store.recordScoreSubmission(100)
        #expect(store.pendingScore == 750)
    }

    @Test @MainActor
    func clearScoreResetsToZero() {
        let store = PendingGameCenterSubmissionStore(defaults: makeIsolatedDefaults())
        store.recordScoreSubmission(500)
        store.clearScore()
        #expect(store.pendingScore == 0)
    }

    @Test @MainActor
    func scorePersistsAcrossInstancesSharingTheSameDefaults() {
        let defaults = makeIsolatedDefaults()
        PendingGameCenterSubmissionStore(defaults: defaults).recordScoreSubmission(1234)
        let reopened = PendingGameCenterSubmissionStore(defaults: defaults)
        #expect(reopened.pendingScore == 1234)
    }
}

// MARK: - Achievements

@Suite("PendingGameCenterSubmissionStore: achievements")
struct PendingGameCenterSubmissionStoreAchievementTests {
    @Test @MainActor
    func recordingAchievementIdentifiersAccumulatesAsSet() {
        let store = PendingGameCenterSubmissionStore(defaults: makeIsolatedDefaults())
        store.recordAchievementSubmissions(["a", "b"])
        store.recordAchievementSubmissions(["b", "c"])
        #expect(store.pendingAchievementIdentifiers == ["a", "b", "c"])
    }

    @Test @MainActor
    func clearAchievementsRemovesAllIdentifiers() {
        let store = PendingGameCenterSubmissionStore(defaults: makeIsolatedDefaults())
        store.recordAchievementSubmissions(["a", "b"])
        store.clearAchievements(["a", "b"])
        #expect(store.pendingAchievementIdentifiers.isEmpty)
    }

    @Test @MainActor
    func clearAchievementsRemovesOnlyTheGivenIdentifiers() {
        let store = PendingGameCenterSubmissionStore(defaults: makeIsolatedDefaults())
        store.recordAchievementSubmissions(["a", "b", "c"])
        store.clearAchievements(["b"])
        #expect(store.pendingAchievementIdentifiers == ["a", "c"])
    }

    @Test @MainActor
    func achievementsPersistAcrossInstancesSharingTheSameDefaults() {
        let defaults = makeIsolatedDefaults()
        PendingGameCenterSubmissionStore(defaults: defaults).recordAchievementSubmissions(["a", "b"])
        let reopened = PendingGameCenterSubmissionStore(defaults: defaults)
        #expect(reopened.pendingAchievementIdentifiers == ["a", "b"])
    }
}
