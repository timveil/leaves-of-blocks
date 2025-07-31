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
    
    /// Returns a localized version of the string in uppercase.
    ///
    /// This computed property is useful for UI elements that require uppercase text
    /// while maintaining localization support.
    ///
    /// ## Usage
    /// ```swift
    /// let title = "score".localizedUppercase
    /// ```
    ///
    /// - Returns: The localized string converted to uppercase
    var localizedUppercase: String {
        return localized.uppercased()
    }
}