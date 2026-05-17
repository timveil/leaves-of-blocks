import Foundation
import GameKit
import UIKit

// MARK: - Pending Achievement

/// A leaderboard achievement that has been earned by a session.
///
/// Returned from `GameCenterService.evaluateAchievements(for:longestCombo:)` so the
/// mapping logic can be unit-tested without touching GameKit.
struct PendingAchievement: Equatable {
    let identifier: String
    let percentComplete: Double
}

// MARK: - Game Center IDs

/// Identifiers configured in App Store Connect. Centralized here so the
/// production code, tests, and any future leaderboard/achievement picker
/// reference the same strings.
enum GameCenterIDs {
    enum Leaderboards {
        static let allTimeHigh = "lob.leaderboard.allTimeHigh"
    }

    enum Achievements {
        static let firstClear = "lob.ach.firstClear"
        static let combo4 = "lob.ach.combo4"
        static let efficiencyAPlus = "lob.ach.efficiencyAPlus"
        static let strategicMaster = "lob.ach.strategicMaster"
        static let score10k = "lob.ach.score10k"
    }
}

// MARK: - Game Center Servicing Protocol

/// Abstract surface for the Game Center service so service-layer consumers
/// (chiefly `GameService.saveGameRecord`) can be tested against a fake
/// without a sandboxed Apple ID or a GameKit round-trip.
///
/// Views that observe the live auth state still type their property as the
/// concrete `GameCenterService` — protocol existentials erase `@Observable`,
/// so going through the protocol from a view would break the re-render
/// loop. Service-to-service wiring uses the protocol; UI keeps the concrete.
@MainActor
protocol GameCenterServicing: AnyObject {
    var isAuthenticated: Bool { get }
    func authenticateIfEnabled(presenter: ((UIViewController) -> Void)?)
    func userDisabledPreference()
    func retryPendingSubmissions()
    func submitFinalScore(
        score: Int,
        sessionMetrics: PlayerBehaviorTracker.SessionMetrics?,
        longestCombo: Int
    )
    func presentDashboard(leaderboardID: String?, from presenter: UIViewController?)
}

// MARK: - Game Center Service

/// Single entry point for Apple Game Center.
///
/// All entry points short-circuit to a no-op when `GameCenterPreference.isEnabled`
/// is `false` or the local player is not authenticated, so callers don't need
/// to gate their calls. Authentication itself is also gated by the preference.
@MainActor
@Observable
final class GameCenterService: GameCenterServicing {

    static let shared = GameCenterService()

    /// `true` once `GKLocalPlayer.local.isAuthenticated` becomes true.
    /// Driven by `authenticateIfEnabled()` and exposed for SwiftUI views.
    private(set) var isAuthenticated: Bool = false

    @ObservationIgnored private var didStartAuthentication: Bool = false

    @ObservationIgnored private let pendingStore: PendingGameCenterSubmissionStore

    private init(pendingStore: PendingGameCenterSubmissionStore = .shared) {
        self.pendingStore = pendingStore
    }

    // MARK: - Authentication

    /// Kicks off Game Center authentication if the user has opted in.
    ///
    /// Apple recommends calling this once per app launch. The handler may
    /// be invoked synchronously (already-signed-in case) or asynchronously
    /// (presents a sign-in VC). Calling more than once is a no-op.
    ///
    /// - Parameter presenter: Closure that presents the auth view controller
    ///   when GameKit returns one. The default implementation finds the
    ///   key-window root view controller.
    func authenticateIfEnabled(presenter: ((UIViewController) -> Void)? = nil) {
        guard GameCenterPreference.isEnabled else { return }
        guard !didStartAuthentication else { return }
        didStartAuthentication = true

        let player = GKLocalPlayer.local
        player.authenticateHandler = { [weak self] viewController, error in
            guard let self else { return }
            if let viewController {
                if let presenter {
                    presenter(viewController)
                } else {
                    Self.defaultPresent(viewController)
                }
                return
            }
            if let error {
                BuildConfiguration.log("Game Center auth error: \(error.localizedDescription)", level: .error)
                self.isAuthenticated = false
                return
            }
            self.isAuthenticated = player.isAuthenticated
            BuildConfiguration.log("Game Center authenticated: \(player.isAuthenticated)", level: .info)
            if player.isAuthenticated {
                self.retryPendingSubmissions()
            }
        }
    }

    // MARK: - Retry

    /// Replays any score / achievement submissions that failed on previous
    /// attempts. Called automatically when authentication succeeds; safe to
    /// call manually. Idempotent: GameKit takes the max for leaderboards and
    /// dedups already-completed achievements, so re-submitting is harmless.
    func retryPendingSubmissions() {
        guard GameCenterPreference.isEnabled, isAuthenticated else { return }

        let pendingScore = pendingStore.pendingScore
        if pendingScore > 0 {
            submitScoreToLeaderboard(pendingScore)
        }

        let pendingAchievements = pendingStore.pendingAchievementIdentifiers
        if !pendingAchievements.isEmpty {
            reportAchievementIdentifiers(Array(pendingAchievements))
        }
    }

    /// Called when the user disables the preference. Stops further submissions
    /// but does not sign the user out — Game Center accounts are device-level
    /// and shouldn't be torn down by an app.
    func userDisabledPreference() {
        BuildConfiguration.log("Game Center disabled by user preference", level: .info)
    }

    // MARK: - Score & Achievement Submission

    /// Submits the final score to the all-time leaderboard and reports any
    /// earned achievements derived from the session metrics.
    ///
    /// No-op when the preference is off or the player isn't authenticated.
    /// Submission failures are durably recorded in `pendingStore` so the
    /// next successful authentication can replay them.
    func submitFinalScore(
        score: Int,
        sessionMetrics: PlayerBehaviorTracker.SessionMetrics?,
        longestCombo: Int
    ) {
        guard GameCenterPreference.isEnabled, isAuthenticated else { return }

        submitScoreToLeaderboard(score)

        let achievements = Self.evaluateAchievements(
            score: score,
            sessionMetrics: sessionMetrics,
            longestCombo: longestCombo
        )
        guard !achievements.isEmpty else { return }

        reportAchievements(achievements)
    }

    // MARK: - GameKit Wrappers

    /// Submits a score and records / clears the pending store based on outcome.
    private func submitScoreToLeaderboard(_ score: Int) {
        pendingStore.recordScoreSubmission(score)
        GKLeaderboard.submitScore(
            score,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [GameCenterIDs.Leaderboards.allTimeHigh]
        ) { [weak self] error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let error {
                    BuildConfiguration.log("Leaderboard submit failed: \(error.localizedDescription)", level: .error)
                } else {
                    self.pendingStore.clearScore()
                }
            }
        }
    }

    /// Reports achievements and records / clears the pending store based on outcome.
    private func reportAchievements(_ achievements: [PendingAchievement]) {
        let identifiers = achievements.map(\.identifier)
        pendingStore.recordAchievementSubmissions(identifiers)

        let gkAchievements: [GKAchievement] = achievements.map { pending in
            let achievement = GKAchievement(identifier: pending.identifier)
            achievement.percentComplete = pending.percentComplete
            achievement.showsCompletionBanner = true
            return achievement
        }
        GKAchievement.report(gkAchievements) { [weak self] error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let error {
                    BuildConfiguration.log("Achievement report failed: \(error.localizedDescription)", level: .error)
                } else {
                    self.pendingStore.clearAchievements(identifiers)
                }
            }
        }
    }

    /// Reports a set of identifier-only achievements (no per-session percent),
    /// used by the retry path. Defaults each to 100% complete on the
    /// assumption that the original `submitFinalScore` already established
    /// that the achievement was earned.
    private func reportAchievementIdentifiers(_ identifiers: [String]) {
        let achievements = identifiers.map { id in
            PendingAchievement(identifier: id, percentComplete: 100)
        }
        reportAchievements(achievements)
    }

    // MARK: - Dashboard

    /// Presents the system Game Center dashboard. No-op when not authenticated.
    ///
    /// - Parameters:
    ///   - leaderboardID: When non-nil, opens directly to that leaderboard
    ///     instead of the generic dashboard home. Use this from "View
    ///     Leaderboard" entry points so users land on the scores instead of
    ///     the empty profile placeholder.
    ///   - presenter: Host view controller. Defaults to the topmost VC.
    func presentDashboard(leaderboardID: String? = nil, from presenter: UIViewController? = nil) {
        guard isAuthenticated else { return }
        let viewController: GKGameCenterViewController
        if let leaderboardID {
            viewController = GKGameCenterViewController(
                leaderboardID: leaderboardID,
                playerScope: .global,
                timeScope: .allTime
            )
        } else {
            viewController = GKGameCenterViewController(state: .default)
        }
        viewController.gameCenterDelegate = GameCenterDismissCoordinator.shared

        let host = presenter ?? Self.topViewController()
        host?.present(viewController, animated: true)
    }

    // MARK: - Achievement Evaluation (testable)

    /// Maps a finished session into the set of achievements that should be
    /// reported. Pure function — no GameKit dependency, no side effects.
    nonisolated static func evaluateAchievements(
        score: Int,
        sessionMetrics: PlayerBehaviorTracker.SessionMetrics?,
        longestCombo: Int
    ) -> [PendingAchievement] {
        var results: [PendingAchievement] = []

        let linesCleared = sessionMetrics?.linesCleared ?? 0
        if linesCleared >= 1 {
            results.append(PendingAchievement(identifier: GameCenterIDs.Achievements.firstClear, percentComplete: 100))
        }

        if longestCombo >= 4 {
            results.append(PendingAchievement(identifier: GameCenterIDs.Achievements.combo4, percentComplete: 100))
        }

        if sessionMetrics?.efficiencyGrade == "grade_a_plus" {
            results.append(PendingAchievement(identifier: GameCenterIDs.Achievements.efficiencyAPlus, percentComplete: 100))
        }

        if sessionMetrics?.strategicGrade == "grade_master" {
            results.append(PendingAchievement(identifier: GameCenterIDs.Achievements.strategicMaster, percentComplete: 100))
        }

        if score >= 10_000 {
            results.append(PendingAchievement(identifier: GameCenterIDs.Achievements.score10k, percentComplete: 100))
        }

        return results
    }

    // MARK: - View Controller Helpers

    private static func defaultPresent(_ viewController: UIViewController) {
        topViewController()?.present(viewController, animated: true)
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })
            ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first

        var top = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

// MARK: - Dismiss Coordinator

/// `GKGameCenterViewController` requires a delegate to be dismissable. The
/// dashboard is presented modally from many call sites; using a single shared
/// coordinator avoids each call site managing its own delegate object.
@MainActor
private final class GameCenterDismissCoordinator: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterDismissCoordinator()

    nonisolated func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        Task { @MainActor in
            gameCenterViewController.dismiss(animated: true)
        }
    }
}
