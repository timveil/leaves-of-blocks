import Foundation

private let scoreFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter
}()

extension Int {

    /// Returns a formatted string for score display
    var formattedScore: String {
        scoreFormatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }

    /// Returns an abbreviated score string (e.g., 87.2K, 1.2M) for compact display
    var abbreviatedScore: String {
        if self >= 1_000_000 {
            let value = Double(self) / 1_000_000
            return value.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(value))M"
                : String(format: "%.1fM", value)
        } else if self >= 10_000 {
            let value = Double(self) / 1_000
            return value.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(value))K"
                : String(format: "%.1fK", value)
        } else {
            return formattedScore
        }
    }
    
    /// Returns `true` if the value is within `[0, gridSize)` — a valid grid axis index.
    func isValidGridIndex(in gridSize: Int) -> Bool {
        return self >= 0 && self < gridSize
    }
}