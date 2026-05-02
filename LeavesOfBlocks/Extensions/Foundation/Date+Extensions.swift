import Foundation

extension DateFormatter {
    static let logTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}

extension TimeInterval {
    /// Returns the duration as a `m:ss` clock string (e.g. `2:05`).
    var formattedAsClock: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Returns the duration as a localized "Xh Ym" / "Xm" string for cumulative
    /// totals (e.g. total play time across many games). Hours are omitted when
    /// the duration is under one hour.
    var formattedAsHoursAndMinutes: String {
        let totalMinutes = max(0, Int(self) / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "stats_hours_minutes_format".localized(with: hours, minutes)
        }
        return "stats_minutes_only_format".localized(with: minutes)
    }
}