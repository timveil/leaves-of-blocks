import CoreData
import Foundation

extension GameSession {
    /// Projects a Core Data `GameRecord` into the immutable value type that
    /// the history and summary screens consume. Returns `nil` for records
    /// missing required fields (`date`, parsable `difficulty`) — these are
    /// treated as corrupt rows and filtered out at the call site rather than
    /// throwing.
    ///
    /// Older records (pre-efficiency feature) default their numeric metric
    /// columns to `0`; the initializer treats `0` as "absent" and exposes
    /// the optional Doubles as `nil` so the UI can hide unavailable fields
    /// instead of showing `0%`.
    init?(record: GameRecord) {
        guard
            let date = record.date,
            let difficultyString = record.difficulty,
            let difficulty = DifficultyMode(rawValue: difficultyString)
        else { return nil }

        self.init(
            date: date,
            score: Int(record.score),
            blocksPlaced: Int(record.blocksPlaced),
            linesCleared: Int(record.linesCleared),
            difficulty: difficulty,
            gameTime: record.gameTime,
            averageGridEfficiency: record.averageGridEfficiency > 0 ? record.averageGridEfficiency : nil,
            averageFragmentation: record.averageFragmentation > 0 ? record.averageFragmentation : nil,
            strategicPlayRating: record.strategicPlayRating > 0 ? record.strategicPlayRating : nil,
            challengeMaintained: record.challengeMaintained > 0 ? record.challengeMaintained : nil,
            fallbackActivations: nil,
            efficiencyGrade: record.efficiencyGrade?.nilIfEmpty,
            strategicGrade: record.strategicGrade?.nilIfEmpty,
            tierUsageDistribution: record.tierUsageDistribution?.nilIfEmpty
        )
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
