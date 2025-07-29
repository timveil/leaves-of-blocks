import Foundation

extension Array where Element == GridCell {
    
    /// Returns true if all cells in the array are filled
    var allFilled: Bool {
        return allSatisfy { $0.isFilled }
    }
    
    /// Returns the number of filled cells
    var filledCount: Int {
        return filter { $0.isFilled }.count
    }
    
    /// Returns the percentage of filled cells (0.0 to 1.0)
    var fillPercentage: Double {
        guard !isEmpty else { return 0.0 }
        return Double(filledCount) / Double(count)
    }
}

extension Array where Element == Array<GridCell> {
    
    /// Returns true if the entire grid is empty
    var isEmpty: Bool {
        return flatMap { $0 }.allSatisfy { !$0.isFilled }
    }
    
    /// Returns true if the entire grid is full
    var isFull: Bool {
        return flatMap { $0 }.allSatisfy { $0.isFilled }
    }
    
    /// Returns the total number of filled cells in the grid
    var totalFilledCells: Int {
        return flatMap { $0 }.filter { $0.isFilled }.count
    }
    
    /// Returns the fill percentage of the entire grid (0.0 to 1.0)
    var fillPercentage: Double {
        let totalCells = count * (first?.count ?? 0)
        guard totalCells > 0 else { return 0.0 }
        return Double(totalFilledCells) / Double(totalCells)
    }
}

extension Array where Element == BlockShape {
    
    /// Returns the total number of cells across all blocks
    var totalCells: Int {
        return reduce(0) { $0 + $1.positions.count }
    }
    
    /// Returns blocks sorted by size (smallest first)
    var sortedBySize: [BlockShape] {
        return sorted { $0.positions.count < $1.positions.count }
    }
    
    /// Returns blocks of a specific color
    func blocks(ofColor color: BlockColor) -> [BlockShape] {
        return filter { $0.color == color }
    }
}