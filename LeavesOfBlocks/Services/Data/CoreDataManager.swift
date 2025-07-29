import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "LeavesOfBlocks")
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // In production, this should be handled more gracefully
                fatalError("Unresolved error \(error), \(error.userInfo)")
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
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // MARK: - Game History Operations
    
    func saveGameRecord(score: Int, difficulty: DifficultyMode, blocksPlaced: Int, 
                       linesCleared: Int, longestCombo: Int, gameTime: TimeInterval) {
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
            print("Error fetching game history: \(error)")
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
            print("Error fetching game history for difficulty: \(error)")
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
            print("Error fetching high scores: \(error)")
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
            print("Error deleting all game records: \(error)")
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
            print("Error calculating statistics: \(error)")
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