import Foundation

// MARK: - String Localization Extensions

/// Extensions for String localization support.
///
/// These extensions provide convenient methods for localizing strings throughout the app.
/// While the current implementation uses `NSLocalizedString`, it's designed to support
/// future internationalization efforts.
extension String {
    
    /// Returns a localized version of the string.
    ///
    /// This computed property looks up the string in the app's localization files.
    /// If no localized version is found, returns the original string.
    ///
    /// ## Usage
    /// ```swift
    /// let title = "Game Over".localized
    /// ```
    ///
    /// - Returns: The localized string, or the original string if no localization exists
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// Returns a localized version with formatted arguments.
    ///
    /// This method allows for localized strings with placeholder values that can be
    /// filled in at runtime. Particularly useful for dynamic content like scores.
    ///
    /// ## Usage
    /// ```swift
    /// let message = "Score: %d".localized(with: 2500)
    /// ```
    ///
    /// - Parameter arguments: Variable arguments to insert into the localized string
    /// - Returns: The localized and formatted string
    func localized(with arguments: CVarArg...) -> String {
        return String(format: localized, arguments: arguments)
    }

    /// Localizes a grade or challenge value persisted in Core Data.
    ///
    /// Handles both new stable keys (e.g. `"grade_a_plus"`, `"grade_master"`)
    /// and legacy English values (`"A+"`, `"Master"`) saved by older builds.
    var localizedGrade: String {
        let key = Self.legacyGradeMap[self] ?? self
        return key.localized
    }

    private static let legacyGradeMap: [String: String] = [
        "A+": "grade_a_plus",
        "A": "grade_a",
        "B+": "grade_b_plus",
        "B": "grade_b",
        "C+": "grade_c_plus",
        "C": "grade_c",
        "D": "grade_d",
        "Master": "grade_master",
        "Expert": "grade_expert",
        "Skilled": "grade_skilled",
        "Learning": "grade_learning",
        "Beginner": "grade_beginner",
        "High": "challenge_high",
        "Medium": "challenge_medium",
        "Low": "challenge_low"
    ]
}