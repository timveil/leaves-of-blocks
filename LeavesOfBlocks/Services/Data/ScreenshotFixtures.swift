import CoreData
import Foundation

// MARK: - Screenshot Fixtures

/// Sample game data used when the app launches in `-screenshot-mode`.
///
/// Populates Core Data with a deterministic high-score session before the
/// home / history screens render so Fastlane snapshot output stays consistent
/// across builds and locales.
enum ScreenshotFixtures {

    /// Replaces all existing game records with a deterministic sample session.
    @MainActor
    static func install(into manager: CoreDataManager) async {
        // Brief settling delay so the first frame is composited before mutations.
        try? await Task.sleep(for: .seconds(0.5))

        let context = manager.viewContext
        context.performAndWait {
            clearAllRecords(in: context)
            insertHighScoreFixture(into: context)

            do {
                try context.save()
                BuildConfiguration.log("Sample game history created for screenshots", level: .debug)
            } catch {
                BuildConfiguration.log("Failed to save sample game history: \(error.localizedDescription)", level: .warning)
            }
        }
    }

    /// Deletes every persisted `GameRecord` in `context`.
    ///
    /// `nonisolated` because it runs inside `performAndWait`, whose closure is
    /// not main-actor isolated. It touches no actor state — only the context
    /// it is handed, on whatever queue that context owns.
    nonisolated private static func clearAllRecords(in context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = GameRecord.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
        } catch {
            BuildConfiguration.log("Failed to clear existing game records: \(error.localizedDescription)", level: .warning)
        }
    }

    /// Inserts the single deterministic high-score session the screenshots pose against.
    ///
    /// `nonisolated` for the same reason as `clearAllRecords`: it is called
    /// from inside `performAndWait` and touches only the passed context.
    /// The session the screenshots pose against, described the way the game
    /// describes one.
    ///
    /// Written as `SessionMetrics` so the grades are *derived* rather than
    /// typed alongside the numbers they are supposed to follow from. They were
    /// typed, and both were wrong: an efficiency of 0.85 earns A+ and the
    /// fixture claimed A, while the strategy slot held `grade_a_plus` — a
    /// value from the efficiency ladder, which the strategy ladder never
    /// returns. The App Store screenshots showed a screen the app could not
    /// produce, in every language.
    nonisolated private static let highScoreSession = PlayerBehaviorTracker.SessionMetrics(
        score: 941,
        blocksPlaced: 45,
        linesCleared: 12,
        longestCombo: 3,
        gameTime: 385.2, // 6:25
        difficulty: .easy,
        averageGridEfficiency: 0.85,
        averageFragmentation: 0.23,
        strategicPlayRating: 0.92,
        fallbackActivations: 2,
        challengeMaintained: 0.78
    )

    nonisolated private static func insertHighScoreFixture(into context: NSManagedObjectContext) {
        let session = highScoreSession
        let highScoreGame = GameRecord(context: context)
        highScoreGame.id = UUID()
        highScoreGame.score = Int32(session.score)
        highScoreGame.difficulty = session.difficulty.rawValue
        highScoreGame.blocksPlaced = Int32(session.blocksPlaced)
        highScoreGame.linesCleared = Int32(session.linesCleared)
        highScoreGame.longestCombo = Int32(session.longestCombo)
        highScoreGame.gameTime = session.gameTime
        highScoreGame.date = sampleDate

        highScoreGame.averageGridEfficiency = session.averageGridEfficiency
        highScoreGame.averageFragmentation = session.averageFragmentation
        highScoreGame.strategicPlayRating = session.strategicPlayRating
        highScoreGame.challengeMaintained = session.challengeMaintained
        highScoreGame.fallbackActivations = Int32(session.fallbackActivations)
        highScoreGame.efficiencyGrade = session.efficiencyGrade
        highScoreGame.strategicGrade = session.strategicGrade
    }

    /// Anchored to May 31, 1819 — a recognizable date that unambiguously signals
    /// "screenshot fixture" rather than real user data.
    ///
    /// `nonisolated` because it is read from `insertHighScoreFixture`, which is
    /// itself off the main actor. An immutable `Date` is `Sendable`, so the
    /// value crosses isolation domains safely.
    nonisolated private static let sampleDate: Date = {
        var components = DateComponents()
        components.year = 1819
        components.month = 5
        components.day = 31
        components.hour = 14
        components.minute = 30
        return Calendar.current.date(from: components) ?? Date()
    }()
}
