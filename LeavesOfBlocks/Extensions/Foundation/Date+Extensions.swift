import Foundation

extension Date {
    
    /// Returns a relative time string (e.g., "2 hours ago")
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Returns true if the date is today
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    /// Returns true if the date is within the current week
    var isThisWeek: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
}