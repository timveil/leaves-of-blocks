import Foundation

/// User-controlled opt-in for Apple Game Center integration.
///
/// Defaults to `false` so a fresh install does not contact Game Center
/// servers and behaves identically to the pre-integration build. The
/// flag is read on every score-submission attempt and on app launch
/// before authentication is requested.
enum GameCenterPreference {

    private static let enabledKey = "gameCenter.enabled"

    /// `true` when the user has explicitly opted into Game Center.
    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }
}
