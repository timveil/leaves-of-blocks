import Foundation

struct GridPosition: Equatable, Codable, Hashable {
    let row: Int
    let col: Int
}

struct GridCell: Codable, Equatable {
    var isFilled: Bool = false
    var color: BlockColor = .blue
}

struct ClearedCell: Equatable, Codable {
    let row: Int
    let col: Int
    let color: BlockColor
}