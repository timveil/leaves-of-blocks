import Foundation

// MARK: - Game Session

/// A completed game session — either an in-progress game projected forward,
/// or a row from `GameRecord` materialized into a value type.
///
/// Used by the history list and the summary view; passed across screens via
/// the navigation enum so views don't need to share a `NSManagedObjectContext`.
struct GameSession: Equatable {
    let date: Date
    let score: Int
    let blocksPlaced: Int
    let linesCleared: Int
    let difficulty: DifficultyMode
    let gameTime: TimeInterval
    let averageGridEfficiency: Double?
    let averageFragmentation: Double?
    let strategicPlayRating: Double?
    let challengeMaintained: Double?
    let fallbackActivations: Int?
    let efficiencyGrade: String?
    let strategicGrade: String?
    let tierUsageDistribution: String?

    /// Game time as a `m:ss` clock string.
    var formattedGameTime: String {
        gameTime.formattedAsClock
    }

    /// Localized medium-style date with short time.
    var formattedDate: String {
        Self.dateFormatter.string(from: date)
    }

    /// Cached so we don't allocate a new `DateFormatter` per row during scroll.
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
