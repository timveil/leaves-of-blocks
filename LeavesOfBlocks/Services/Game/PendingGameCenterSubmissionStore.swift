import Foundation

/// Durable retry record for Game Center submissions that failed.
///
/// `GKLeaderboard.submitScore` and `GKAchievement.report` invoke their
/// completion handlers with an error on transient failures (network blips,
/// rate limiting, etc.). Without a retry mechanism, a single failure means
/// the player's score / achievement never makes it to Apple's servers. This
/// store keeps the highest unsubmitted score plus the set of unreported
/// achievement identifiers so the next successful authentication can replay
/// them. GameKit treats both replays as idempotent (best-score on the
/// leaderboard, completed-state dedup on achievements).
///
/// Backed by `UserDefaults` rather than its own JSON file — the payload is
/// trivial (one Int, one Set<String>) and tying it to `UserDefaults` makes
/// suite-based test isolation straightforward.
@MainActor
final class PendingGameCenterSubmissionStore {

    static let shared = PendingGameCenterSubmissionStore(defaults: .standard)

    private let defaults: UserDefaults
    private let scoreKey = "gamecenter.pendingScore"
    private let achievementsKey = "gamecenter.pendingAchievementIdentifiers"

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    // MARK: - Score

    /// The highest score that has been recorded but not yet confirmed-submitted
    /// to Game Center. `0` means the store has no pending score.
    var pendingScore: Int {
        defaults.integer(forKey: scoreKey)
    }

    /// Records that a score submission may have failed; persisted as the max
    /// of the current pending score and `score` so older lower scores are
    /// never replayed over a fresher higher one.
    func recordScoreSubmission(_ score: Int) {
        let next = Swift.max(pendingScore, score)
        defaults.set(next, forKey: scoreKey)
    }

    /// Clears the pending score after a confirmed-successful submission.
    func clearScore() {
        defaults.removeObject(forKey: scoreKey)
    }

    // MARK: - Achievements

    /// Set of achievement identifiers that have been recorded but not yet
    /// confirmed-reported to Game Center.
    var pendingAchievementIdentifiers: Set<String> {
        Set(defaults.stringArray(forKey: achievementsKey) ?? [])
    }

    /// Records achievement identifiers that may have failed to report.
    /// Achievement state is a set: re-reporting an already-completed
    /// achievement is a Game Center no-op, so accumulating duplicates is fine.
    func recordAchievementSubmissions(_ identifiers: [String]) {
        let next = pendingAchievementIdentifiers.union(identifiers)
        defaults.set(Array(next).sorted(), forKey: achievementsKey)
    }

    /// Clears the given identifiers after confirmed-successful reports.
    func clearAchievements(_ identifiers: [String]) {
        let remaining = pendingAchievementIdentifiers.subtracting(identifiers)
        if remaining.isEmpty {
            defaults.removeObject(forKey: achievementsKey)
        } else {
            defaults.set(Array(remaining).sorted(), forKey: achievementsKey)
        }
    }
}
