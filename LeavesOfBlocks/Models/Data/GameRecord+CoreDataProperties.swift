import Foundation
import CoreData

extension GameRecord {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GameRecord> {
        return NSFetchRequest<GameRecord>(entityName: "GameRecord")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var score: Int32
    @NSManaged public var difficulty: String?
    @NSManaged public var blocksPlaced: Int32
    @NSManaged public var linesCleared: Int32
    @NSManaged public var longestCombo: Int32
    @NSManaged public var gameTime: Double
    @NSManaged public var date: Date?
    
    // New efficiency metrics
    @NSManaged public var averageGridEfficiency: Double
    @NSManaged public var averageFragmentation: Double
    @NSManaged public var strategicPlayRating: Double
    @NSManaged public var challengeMaintained: Double
    @NSManaged public var fallbackActivations: Int32
    @NSManaged public var efficiencyGrade: String?
    @NSManaged public var strategicGrade: String?
    @NSManaged public var tierUsageDistribution: String?

}

extension GameRecord : Identifiable {

}