import Foundation

/// When to ask for an App Store rating.
///
/// The ask comes on the summary screen after a new personal best, so it lands
/// on a good moment rather than interrupting play. iOS has the final say: it
/// shows the system sheet at most three times in 365 days and may show none.
enum ReviewPrompt {

    /// Every first game is a personal best, so a best only counts once the
    /// player has a few games behind them.
    static let minimumGamesPlayed = 3

    private static let lastRequestedVersionKey = "reviewPrompt.lastRequestedVersion"

    /// Whether this game over should ask. At most once per app version, so a
    /// player who declines is not asked again until there is something new.
    nonisolated static func shouldRequest(
        isNewHighScore: Bool,
        gamesPlayed: Int,
        currentVersion: String,
        lastRequestedVersion: String?
    ) -> Bool {
        guard isNewHighScore else { return false }
        guard gamesPlayed >= minimumGamesPlayed else { return false }
        return lastRequestedVersion != currentVersion
    }

    /// The app version in which a rating was last requested, `nil` if never.
    static var lastRequestedVersion: String? {
        get { UserDefaults.standard.string(forKey: lastRequestedVersionKey) }
        set { UserDefaults.standard.set(newValue, forKey: lastRequestedVersionKey) }
    }
}
