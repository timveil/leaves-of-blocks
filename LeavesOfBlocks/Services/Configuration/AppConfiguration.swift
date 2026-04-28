import Foundation

// MARK: - Application Configuration

/// Build/runtime tuning knobs that aren't user preferences.
///
/// Kept compile-time only — no dependencies on `UserDefaults`, no remote config.
enum AppConfiguration {

    // MARK: - Feature Flags

    enum FeatureFlags {
        /// True in DEBUG builds. Used to gate verbose logging and debug helpers.
        static let enableDebugMode = BuildConfiguration.isDebugBuild
    }

    // MARK: - Performance Settings

    enum Performance {
        static let maxFallingLeaves = 50
        static let animationFrameRate = 60.0
        static var dragUpdateThrottleInterval: TimeInterval { 1.0 / animationFrameRate }
    }
}
