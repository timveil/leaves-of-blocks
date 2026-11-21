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
        abbreviatedScore(locale: .current)
    }

    /// `abbreviatedScore` in a given locale. The K and M suffixes stay as they
    /// are in every language; only the number follows the locale, so German
    /// reads "12,5K" and "9.876" rather than "12.5K" beside "9.876".
    func abbreviatedScore(locale: Locale) -> String {
        if self >= 1_000_000 {
            return Self.abbreviate(Double(self) / 1_000_000, suffix: "M", locale: locale)
        } else if self >= 10_000 {
            return Self.abbreviate(Double(self) / 1_000, suffix: "K", locale: locale)
        } else {
            return formatted(.number.locale(locale))
        }
    }

    private static func abbreviate(_ value: Double, suffix: String, locale: Locale) -> String {
        let fractionDigits = value.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 1
        let number = value.formatted(
            .number
                .locale(locale)
                .grouping(.never)
                .precision(.fractionLength(fractionDigits))
        )
        return number + suffix
    }
    
    /// Returns `true` if the value is within `[0, gridSize)` — a valid grid axis index.
    func isValidGridIndex(in gridSize: Int) -> Bool {
        return self >= 0 && self < gridSize
    }
}