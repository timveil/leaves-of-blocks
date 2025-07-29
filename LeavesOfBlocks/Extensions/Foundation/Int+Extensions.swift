import Foundation

extension Int {
    
    /// Returns a formatted string for score display
    var formattedScore: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
    
    /// Returns true if the number is within a valid grid range
    var isValidGridIndex: Bool {
        return self >= 0 && self < GameTheme.GameConfig.gridSize
    }
}