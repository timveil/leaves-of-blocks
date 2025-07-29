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

}

extension GameRecord : Identifiable {

}