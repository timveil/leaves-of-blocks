import Foundation
import CoreData

extension Notification.Name {
    static let coreDataSaveFailure = Notification.Name("CoreDataSaveFailure")
}

@MainActor
final class CoreDataManager {
    static let shared = CoreDataManager()

    private init() {}

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "LeavesOfBlocks")

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                BuildConfiguration.log("Core Data error: \(error.localizedDescription)", level: .error)

                #if DEBUG
                fatalError("Core Data failed to load: \(error)")
                #else
                self.handleCoreDataLoadFailure(container: container, error: error)
                #endif
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    func saveContext() {
        let context = persistentContainer.viewContext

        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            BuildConfiguration.log("Error saving context: \(nsError.localizedDescription)", level: .error)

            context.rollback()

            NotificationCenter.default.post(
                name: .coreDataSaveFailure,
                object: nil,
                userInfo: ["error": nsError]
            )
        }
    }

    // MARK: - Error Recovery

    /// Handles Core Data load failures by attempting to recreate the persistent store.
    private nonisolated func handleCoreDataLoadFailure(container: NSPersistentContainer, error: NSError) {
        BuildConfiguration.log("Attempting Core Data recovery...", level: .warning)

        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            BuildConfiguration.log("Could not get store URL for recovery", level: .error)
            return
        }

        do {
            try FileManager.default.removeItem(at: storeURL)
            BuildConfiguration.log("Deleted corrupted Core Data store", level: .info)

            container.loadPersistentStores { _, recoveryError in
                if let recoveryError = recoveryError {
                    BuildConfiguration.log("Core Data recovery failed: \(recoveryError.localizedDescription)", level: .error)
                } else {
                    BuildConfiguration.log("Core Data recovery successful", level: .info)
                }
            }
        } catch {
            BuildConfiguration.log("Failed to delete corrupted store: \(error.localizedDescription)", level: .error)
        }
    }

    // MARK: - Game History Operations

    /// Persists a completed game session as a new `GameRecord`.
    ///
    /// - Parameters:
    ///   - score: Final score for the session.
    ///   - difficulty: Difficulty mode the session was played in. Persisted as `rawValue`.
    ///   - blocksPlaced: Total blocks the player placed.
    ///   - linesCleared: Total lines cleared during the session.
    ///   - longestCombo: Maximum combo (lines cleared in a single placement).
    ///   - gameTime: Elapsed gameplay duration, in seconds.
    ///   - sessionMetrics: Optional analytics from `PlayerBehaviorTracker`. When
    ///     present, efficiency / strategic / fallback metrics are also persisted.
    func saveGameRecord(score: Int, difficulty: DifficultyMode, blocksPlaced: Int,
                       linesCleared: Int, longestCombo: Int, gameTime: TimeInterval,
                       sessionMetrics: PlayerBehaviorTracker.SessionMetrics? = nil) {
        let context = viewContext
        let gameRecord = GameRecord(context: context)

        gameRecord.id = UUID()
        gameRecord.score = Int32(score)
        gameRecord.difficulty = difficulty.rawValue
        gameRecord.blocksPlaced = Int32(blocksPlaced)
        gameRecord.linesCleared = Int32(linesCleared)
        gameRecord.longestCombo = Int32(longestCombo)
        gameRecord.gameTime = gameTime
        gameRecord.date = Date()

        if let metrics = sessionMetrics {
            gameRecord.averageGridEfficiency = metrics.averageGridEfficiency
            gameRecord.averageFragmentation = metrics.averageFragmentation
            gameRecord.strategicPlayRating = metrics.strategicPlayRating
            gameRecord.challengeMaintained = metrics.challengeMaintained
            gameRecord.fallbackActivations = Int32(metrics.fallbackActivations)
            gameRecord.efficiencyGrade = metrics.efficiencyGrade
            gameRecord.strategicGrade = metrics.strategicGrade

            do {
                let tierData = try JSONSerialization.data(withJSONObject: metrics.tierUsageDistribution)
                if let tierString = String(data: tierData, encoding: .utf8) {
                    gameRecord.tierUsageDistribution = tierString
                }
            } catch {
                BuildConfiguration.log("Failed to serialize tier usage distribution: \(error.localizedDescription)", level: .warning)
            }
        }

        #if DEBUG
        let metricsInfo = sessionMetrics != nil ? ", Efficiency: \(String(format: "%.2f", sessionMetrics?.averageGridEfficiency ?? 0.0))" : ""
        BuildConfiguration.log("Saving game record: Score=\(score), Difficulty=\(difficulty.rawValue), Time=\(Int(gameTime))s\(metricsInfo)", level: .debug)
        #endif

        saveContext()
    }

    /// Returns persisted game records, newest first.
    ///
    /// - Parameter limit: Optional cap on the number of rows returned.
    /// - Returns: Records sorted by `date` descending, or an empty array on error.
    func fetchGameHistory(limit: Int? = nil) -> [GameRecord] {
        let request: NSFetchRequest<GameRecord> = GameRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        request.fetchBatchSize = 20

        if let limit = limit {
            request.fetchLimit = limit
        }

        do {
            return try viewContext.fetch(request)
        } catch {
            BuildConfiguration.log("Error fetching game history: \(error.localizedDescription)", level: .error)
            return []
        }
    }

    /// Returns persisted game records for one difficulty, highest score first.
    ///
    /// - Parameter difficulty: Difficulty mode to filter by.
    /// - Returns: Records sorted by `score` descending, or an empty array on error.
    func fetchGameHistory(for difficulty: DifficultyMode) -> [GameRecord] {
        let request: NSFetchRequest<GameRecord> = GameRecord.fetchRequest()
        request.predicate = NSPredicate(format: "difficulty == %@", difficulty.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "score", ascending: false)]
        request.fetchBatchSize = 20

        do {
            return try viewContext.fetch(request)
        } catch {
            BuildConfiguration.log("Error fetching game history for difficulty: \(error.localizedDescription)", level: .error)
            return []
        }
    }

    /// Returns the top-scoring game records.
    ///
    /// - Parameter limit: Maximum number of high scores to fetch. Defaults to 10.
    /// - Returns: Records sorted by `score` descending, or an empty array on error.
    func fetchHighScores(limit: Int = 10) -> [GameRecord] {
        let request: NSFetchRequest<GameRecord> = GameRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "score", ascending: false)]
        request.fetchLimit = limit

        do {
            return try viewContext.fetch(request)
        } catch {
            BuildConfiguration.log("Error fetching high scores: \(error.localizedDescription)", level: .error)
            return []
        }
    }

    /// Deletes every persisted `GameRecord`.
    ///
    /// `NSBatchDeleteRequest` runs against the persistent store and bypasses the
    /// in-memory `viewContext`, so we ask for the deleted object IDs and merge
    /// them back into the context. Without this merge, any active fetched
    /// results / `@FetchRequest` continues to show stale rows until the screen
    /// is rebuilt.
    func deleteAllGameRecords() {
        let request: NSFetchRequest<NSFetchRequestResult> = GameRecord.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        deleteRequest.resultType = .resultTypeObjectIDs

        do {
            let result = try viewContext.execute(deleteRequest) as? NSBatchDeleteResult
            if let objectIDs = result?.result as? [NSManagedObjectID], !objectIDs.isEmpty {
                let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: changes,
                    into: [viewContext]
                )
            }
        } catch {
            BuildConfiguration.log("Error deleting all game records: \(error.localizedDescription)", level: .error)
        }
    }

    // MARK: - Statistics

    /// Aggregates totals across all persisted game records.
    ///
    /// - Returns: A `GameHistoryStatistics` with totals/averages/highscore. Returns
    ///   an all-zero value if the fetch fails.
    /// - Note: Currently fetches and reduces in Swift. With sufficient row counts,
    ///   prefer `NSExpressionDescription` aggregates against the store directly.
    func calculateStatistics() -> GameHistoryStatistics {
        let request: NSFetchRequest<GameRecord> = GameRecord.fetchRequest()

        do {
            let records = try viewContext.fetch(request)

            let totalGames = records.count
            let totalScore = records.reduce(0) { $0 + Int($1.score) }
            let averageScore = totalGames > 0 ? totalScore / totalGames : 0
            let totalBlocksPlaced = records.reduce(0) { $0 + Int($1.blocksPlaced) }
            let highScore = records.map { Int($0.score) }.max() ?? 0

            return GameHistoryStatistics(
                totalGames: totalGames,
                totalScore: totalScore,
                averageScore: averageScore,
                totalBlocksPlaced: totalBlocksPlaced,
                highScore: highScore
            )
        } catch {
            BuildConfiguration.log("Error calculating statistics: \(error.localizedDescription)", level: .error)
            return GameHistoryStatistics(totalGames: 0, totalScore: 0, averageScore: 0, totalBlocksPlaced: 0, highScore: 0)
        }
    }
}

struct GameHistoryStatistics {
    let totalGames: Int
    let totalScore: Int
    let averageScore: Int
    let totalBlocksPlaced: Int
    let highScore: Int
}
