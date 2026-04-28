import CoreData
import Foundation

// MARK: - Screenshot Fixtures

/// Sample game data used when the app launches in `-screenshot-mode`.
///
/// Populates Core Data with a deterministic high-score session before the
/// home / history screens render so Fastlane snapshot output stays consistent
/// across builds and locales.
@MainActor
enum ScreenshotFixtures {

    /// Replaces all existing game records with a deterministic sample session.
    static func install(into manager: CoreDataManager = .shared) async {
        // Brief settling delay so the first frame is composited before mutations.
        try? await Task.sleep(for: .seconds(0.5))

        let context = manager.viewContext

        await context.perform {
            clearAllRecords(in: context)

            let highScoreGame = GameRecord(context: context)
            highScoreGame.id = UUID()
            highScoreGame.score = 941
            highScoreGame.difficulty = DifficultyMode.easy.rawValue
            highScoreGame.blocksPlaced = 45
            highScoreGame.linesCleared = 12
            highScoreGame.longestCombo = 3
            highScoreGame.gameTime = 385.2 // 6:25
            highScoreGame.date = sampleDate

            highScoreGame.averageGridEfficiency = 0.85
            highScoreGame.averageFragmentation = 0.23
            highScoreGame.strategicPlayRating = 0.92
            highScoreGame.challengeMaintained = 0.78
            highScoreGame.fallbackActivations = 2
            highScoreGame.efficiencyGrade = "grade_a"
            highScoreGame.strategicGrade = "grade_a_plus"

            do {
                try context.save()
                BuildConfiguration.log("Sample game history created for screenshots", level: .debug)
            } catch {
                BuildConfiguration.log("Failed to save sample game history: \(error.localizedDescription)", level: .warning)
            }
        }
    }

    private static func clearAllRecords(in context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = GameRecord.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
        } catch {
            BuildConfiguration.log("Failed to clear existing game records: \(error.localizedDescription)", level: .warning)
        }
    }

    /// Anchored to May 31, 1819 — a recognizable date that unambiguously signals
    /// "screenshot fixture" rather than real user data.
    private static let sampleDate: Date = {
        var components = DateComponents()
        components.year = 1819
        components.month = 5
        components.day = 31
        components.hour = 14
        components.minute = 30
        return Calendar.current.date(from: components) ?? Date()
    }()
}
