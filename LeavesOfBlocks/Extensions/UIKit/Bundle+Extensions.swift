import Foundation

extension Bundle {
    
    /// Returns the app's display name
    var displayName: String {
        return infoDictionary?["CFBundleDisplayName"] as? String
            ?? infoDictionary?["CFBundleName"] as? String
            ?? "Leaves of Blocks"
    }
    
    /// Returns the app's version string
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    /// Returns the app's build number
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    /// Returns a combined version string
    var versionAndBuild: String {
        return "\(appVersion) (\(buildNumber))"
    }
}