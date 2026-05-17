//
//  MockGameCenterService.swift
//  LeavesOfBlocksTests
//
//  In-memory fake of the Game Center service for tests that exercise
//  call-sequence behavior (e.g. "GameService.saveGameRecord forwards a
//  successful save to GameCenterServicing.submitFinalScore"). Production
//  views keep using the concrete `GameCenterService` so SwiftUI
//  observation of `isAuthenticated` still drives view re-renders; the
//  protocol exists for service-layer injection only.
//

import Foundation
import UIKit
@testable import LeavesOfBlocks

@MainActor
final class MockGameCenterService: GameCenterServicing {

    // MARK: - Configuration

    /// Drives the `isAuthenticated` getter; tests flip this directly to
    /// model "signed in" vs "signed out" states.
    var isAuthenticated: Bool = false

    // MARK: - Captured Calls

    private(set) var authenticateCallCount = 0
    private(set) var userDisabledCallCount = 0
    private(set) var retryCallCount = 0
    private(set) var presentDashboardCallCount = 0

    struct SubmitCall: Equatable {
        let score: Int
        let longestCombo: Int
    }
    private(set) var submitFinalScoreCalls: [SubmitCall] = []

    // MARK: - GameCenterServicing

    func authenticateIfEnabled(presenter: ((UIViewController) -> Void)?) {
        authenticateCallCount += 1
    }

    func userDisabledPreference() {
        userDisabledCallCount += 1
    }

    func retryPendingSubmissions() {
        retryCallCount += 1
    }

    func submitFinalScore(
        score: Int,
        sessionMetrics: PlayerBehaviorTracker.SessionMetrics?,
        longestCombo: Int
    ) {
        submitFinalScoreCalls.append(SubmitCall(score: score, longestCombo: longestCombo))
    }

    func presentDashboard(leaderboardID: String?, from presenter: UIViewController?) {
        presentDashboardCallCount += 1
    }
}
