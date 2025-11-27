import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "LeavesOfBlocks")
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                BuildConfiguration.log("Core Data error: \(error.localizedDescription)", level: .error)

                #if DEBUG
                // In debug mode, we can crash to help identify issues
                fatalError("Core Data failed to load: \(error)")
                #else
                // In production, attempt recovery by deleting and recreating the store
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
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                BuildConfiguration.log("Error saving context: \(nsError.localizedDescription)", level: .error)

                // Attempt to rollback changes on save failure
                context.rollback()

                // Notify observers that save failed (could be used for user notification)
                NotificationCenter.default.post(
                    name: NSNotification.Name("CoreDataSaveFailure"),
                    object: nil,
                    userInfo: ["error": nsError]
                )
            }
        }
    }
    
    // MARK: - Error Recovery
    
    /// Handles Core Data load failures by attempting to recreate the persistent store
    private func handleCoreDataLoadFailure(container: NSPersistentContainer, error: NSError) {
        BuildConfiguration.log("Attempting Core Data recovery...", level: .warning)

        // Get the store URL
        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            BuildConfiguration.log("Could not get store URL for recovery", level: .error)
            return
        }

        // Attempt to delete the corrupted store
        do {
            try FileManager.default.removeItem(at: storeURL)
            BuildConfiguration.log("Deleted corrupted Core Data store", level: .info)

            // Try to reload the store
            container.loadPersistentStores { _, recoveryError in
                if let recoveryError = recoveryError {
                    BuildConfiguration.log("Core Data recovery failed: \(recoveryError.localizedDescription)", level: .error)
                    // At this point, the app will have to run without persistence
                    // You could implement a fallback storage mechanism here
                } else {
                    BuildConfiguration.log("Core Data recovery successful", level: .info)
                }
            }
        } catch {
            BuildConfiguration.log("Failed to delete corrupted store: \(error.localizedDescription)", level: .error)
        }
    }
    
    // MARK: - Game History Operations
    
    func saveGameRecord(score: Int, difficulty: DifficultyMode, blocksPlaced: Int, 
                       linesCleared: Int, longestCombo: Int, gameTime: TimeInterval,
                       sessionMetrics: PlayerBehaviorTracker.SessionMetrics? = nil) {
        let context = persistentContainer.viewContext
        let gameRecord = GameRecord(context: context)
        
        gameRecord.id = UUID()
        gameRecord.score = Int32(score)
        gameRecord.difficulty = difficulty.rawValue
        gameRecord.blocksPlaced = Int32(blocksPlaced)
        gameRecord.linesCleared = Int32(linesCleared)
        gameRecord.longestCombo = Int32(longestCombo)
        gameRecord.gameTime = gameTime
        gameRecord.date = Date()
        
        // Store efficiency metrics if available
        if let metrics = sessionMetrics {
            gameRecord.averageGridEfficiency = metrics.averageGridEfficiency
            gameRecord.averageFragmentation = metrics.averageFragmentation
            gameRecord.strategicPlayRating = metrics.strategicPlayRating
            gameRecord.challengeMaintained = metrics.challengeMaintained
            gameRecord.fallbackActivations = Int32(metrics.fallbackActivations)
            gameRecord.efficiencyGrade = metrics.efficiencyGrade
            gameRecord.strategicGrade = metrics.strategicGrade
            
            // Serialize tier usage distribution to JSON string
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
    
    func fetchGameHistory(limit: Int? = nil) -> [GameRecord] {
        let request: NSFetchRequest<GameRecord> = GameRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
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
    
    func fetchGameHistory(for difficulty: DifficultyMode) -> [GameRecord] {
        let request: NSFetchRequest<GameRecord> = GameRecord.fetchRequest()
        request.predicate = NSPredicate(format: "difficulty == %@", difficulty.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "score", ascending: false)]

        do {
            return try viewContext.fetch(request)
        } catch {
            BuildConfiguration.log("Error fetching game history for difficulty: \(error.localizedDescription)", level: .error)
            return []
        }
    }
    
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
    
    func deleteAllGameRecords() {
        let request: NSFetchRequest<NSFetchRequestResult> = GameRecord.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        do {
            try viewContext.execute(deleteRequest)
            saveContext()
        } catch {
            BuildConfiguration.log("Error deleting all game records: \(error.localizedDescription)", level: .error)
        }
    }
    
    // MARK: - Statistics
    
    func calculateStatistics() -> GameStatistics {
        let request: NSFetchRequest<GameRecord> = GameRecord.fetchRequest()
        
        do {
            let records = try viewContext.fetch(request)
            
            let totalGames = records.count
            let totalScore = records.reduce(0) { $0 + Int($1.score) }
            let averageScore = totalGames > 0 ? totalScore / totalGames : 0
            let totalBlocksPlaced = records.reduce(0) { $0 + Int($1.blocksPlaced) }
            let highScore = records.map { Int($0.score) }.max() ?? 0
            
            return GameStatistics(
                totalGames: totalGames,
                totalScore: totalScore,
                averageScore: averageScore,
                totalBlocksPlaced: totalBlocksPlaced,
                highScore: highScore
            )
        } catch {
            BuildConfiguration.log("Error calculating statistics: \(error.localizedDescription)", level: .error)
            return GameStatistics(totalGames: 0, totalScore: 0, averageScore: 0, totalBlocksPlaced: 0, highScore: 0)
        }
    }
}

struct GameStatistics {
    let totalGames: Int
    let totalScore: Int
    let averageScore: Int
    let totalBlocksPlaced: Int
    let highScore: Int
}