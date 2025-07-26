import SwiftUI
import Foundation

// MARK: - SwiftUI Extensions

extension View {
    
    // MARK: - Conditional Modifiers
    
    /// Conditionally applies a modifier to a view
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Conditionally applies one of two modifiers to a view
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        ifTrue: (Self) -> TrueContent,
        ifFalse: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTrue(self)
        } else {
            ifFalse(self)
        }
    }
    
    // MARK: - Debug Helpers
    
    /// Prints the frame of a view for debugging
    func debugFrame(_ label: String = "Frame") -> some View {
        self.background(
            GeometryReader { geometry in
                Color.clear.onAppear {
                    if AppConfiguration.FeatureFlags.enableDebugMode {
                        print("\(label): \(geometry.frame(in: .global))")
                    }
                }
            }
        )
    }
    
    /// Adds a colored border for debugging layout issues
    func debugBorder(_ color: Color = .red, width: CGFloat = 1) -> some View {
        self.overlay(
            Rectangle()
                .stroke(color, lineWidth: width)
                .opacity(AppConfiguration.FeatureFlags.enableDebugMode ? 1 : 0)
        )
    }
    
    // MARK: - Animation Helpers
    
    /// Applies a spring animation with consistent timing
    func gameAnimation<V: Equatable>(value: V) -> some View {
        self.animation(
            .spring(
                response: GameTheme.Animations.springResponse,
                dampingFraction: GameTheme.Animations.springDamping
            ),
            value: value
        )
    }
    
    /// Applies a bounce effect when a value changes
    func bounceEffect<V: Equatable>(value: V, scale: CGFloat = 1.1) -> some View {
        self.scaleEffect(1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: value)
    }
}

// MARK: - Color Extensions

extension Color {
    
    // MARK: - Game Colors
    
    static let gameBackground = GameTheme.Colors.primaryBackground
    static let gameAccent = GameTheme.Colors.primaryAccent
    static let gameText = GameTheme.Colors.primaryText
    static let gameSuccess = GameTheme.Colors.success
    static let gameWarning = GameTheme.Colors.warning
    static let gameError = GameTheme.Colors.error
    
    // MARK: - Hex Color Support
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // MARK: - Color Variations
    
    func lighter(by percentage: CGFloat = 0.2) -> Color {
        return self.opacity(1.0 - percentage)
    }
    
    func darker(by percentage: CGFloat = 0.2) -> Color {
        return self.opacity(1.0 + percentage)
    }
}

// MARK: - Array Extensions

extension Array where Element == GridCell {
    
    /// Returns true if all cells in the array are filled
    var allFilled: Bool {
        return allSatisfy { $0.isFilled }
    }
    
    /// Returns the number of filled cells
    var filledCount: Int {
        return filter { $0.isFilled }.count
    }
    
    /// Returns the percentage of filled cells (0.0 to 1.0)
    var fillPercentage: Double {
        guard !isEmpty else { return 0.0 }
        return Double(filledCount) / Double(count)
    }
}

extension Array where Element == Array<GridCell> {
    
    /// Returns true if the entire grid is empty
    var isEmpty: Bool {
        return flatMap { $0 }.allSatisfy { !$0.isFilled }
    }
    
    /// Returns true if the entire grid is full
    var isFull: Bool {
        return flatMap { $0 }.allSatisfy { $0.isFilled }
    }
    
    /// Returns the total number of filled cells in the grid
    var totalFilledCells: Int {
        return flatMap { $0 }.filter { $0.isFilled }.count
    }
    
    /// Returns the fill percentage of the entire grid (0.0 to 1.0)
    var fillPercentage: Double {
        let totalCells = count * (first?.count ?? 0)
        guard totalCells > 0 else { return 0.0 }
        return Double(totalFilledCells) / Double(totalCells)
    }
}

extension Array where Element == BlockShape {
    
    /// Returns the total number of cells across all blocks
    var totalCells: Int {
        return reduce(0) { $0 + $1.positions.count }
    }
    
    /// Returns blocks sorted by size (smallest first)
    var sortedBySize: [BlockShape] {
        return sorted { $0.positions.count < $1.positions.count }
    }
    
    /// Returns blocks of a specific color
    func blocks(ofColor color: BlockColor) -> [BlockShape] {
        return filter { $0.color == color }
    }
}

// MARK: - CGPoint Extensions

extension CGPoint {
    
    /// Returns the distance to another point
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
    
    /// Returns the midpoint between this point and another
    func midpoint(to point: CGPoint) -> CGPoint {
        return CGPoint(
            x: (x + point.x) / 2,
            y: (y + point.y) / 2
        )
    }
    
    /// Returns true if the point is within a given rectangle
    func isInside(_ rect: CGRect) -> Bool {
        return rect.contains(self)
    }
}

// MARK: - String Extensions

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

// MARK: - Int Extensions

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

// MARK: - Double Extensions

extension Double {
    
    /// Rounds to a specified number of decimal places
    func rounded(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
    /// Converts seconds to milliseconds
    var milliseconds: Int {
        return Int(self * 1000)
    }
}

// MARK: - UserDefaults Extensions

extension UserDefaults {
    
    /// Safely retrieves a Codable object from UserDefaults
    func codableObject<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    /// Safely stores a Codable object in UserDefaults
    func setCodableObject<T: Codable>(_ object: T?, forKey key: String) {
        guard let object = object else {
            removeObject(forKey: key)
            return
        }
        
        if let data = try? JSONEncoder().encode(object) {
            set(data, forKey: key)
        }
    }
}

// MARK: - Bundle Extensions

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

// MARK: - Notification Extensions

extension NotificationCenter {
    
    /// Posts a game state change notification
    func postGameStateChange() {
        post(name: AppConstants.NotificationNames.gameStateChanged, object: nil)
    }
    
    /// Posts a high score update notification
    func postHighScoreUpdate(newScore: Int) {
        post(
            name: AppConstants.NotificationNames.highScoreUpdated,
            object: nil,
            userInfo: ["newScore": newScore]
        )
    }
}

// MARK: - Date Extensions

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

// MARK: - FileManager Extensions

extension FileManager {
    
    /// Returns the app's documents directory URL
    var documentsDirectory: URL {
        return urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    /// Returns the app's caches directory URL
    var cachesDirectory: URL {
        return urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    /// Creates a directory if it doesn't exist
    func createDirectoryIfNeeded(at url: URL) throws {
        if !fileExists(atPath: url.path) {
            try createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    /// Returns the size of a file in bytes
    func fileSize(at url: URL) -> Int64? {
        guard let attributes = try? attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int64 else {
            return nil
        }
        return size
    }
}