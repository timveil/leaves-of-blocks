import Foundation

extension String {
    
    /// Returns a localized version of the string
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// Returns a localized version with arguments
    func localized(with arguments: CVarArg...) -> String {
        return String(format: localized, arguments: arguments)
    }
}