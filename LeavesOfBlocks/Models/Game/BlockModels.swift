import Foundation

enum BlockColor: CaseIterable, Codable, Hashable {
    case blue, green, red, yellow, purple, orange, pink
}

enum BlockType: Codable, Hashable {
    case normal
    case horizontalClear  // Clears entire horizontal row
    case verticalClear    // Clears entire vertical column
}

struct BlockShape: Codable, Equatable, Hashable {
    let positions: [GridPosition]
    let color: BlockColor
    let type: BlockType
    
    // Convenience initializer for normal blocks
    init(positions: [GridPosition], color: BlockColor) {
        self.positions = positions
        self.color = color
        self.type = .normal
    }
    
    // Full initializer for special blocks
    init(positions: [GridPosition], color: BlockColor, type: BlockType) {
        self.positions = positions
        self.color = color
        self.type = type
    }
    
    static let allShapes: [BlockShape] = [
        // Single block
        BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .blue),
        
        // 2-block shapes
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1)], color: .green),
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 1, col: 0)], color: .green),
        
        // 3-block shapes
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 0, col: 2)], color: .red),
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 1, col: 0), GridPosition(row: 2, col: 0)], color: .red),
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 1, col: 0)], color: .yellow),
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 1, col: 1)], color: .yellow),
        
        // 4-block shapes
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 1, col: 0), GridPosition(row: 1, col: 1)], color: .purple),
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 0, col: 2), GridPosition(row: 0, col: 3)], color: .orange),
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 1, col: 0), GridPosition(row: 2, col: 0), GridPosition(row: 3, col: 0)], color: .orange),
        
        // L-shapes
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 1, col: 0), GridPosition(row: 2, col: 0), GridPosition(row: 2, col: 1)], color: .pink),
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 0, col: 2), GridPosition(row: 1, col: 0)], color: .pink),
        
        // T-shapes
        BlockShape(positions: [GridPosition(row: 0, col: 1), GridPosition(row: 1, col: 0), GridPosition(row: 1, col: 1), GridPosition(row: 1, col: 2)], color: .blue),
        
        // 5-block straight lines
        BlockShape(positions: [
            GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 0, col: 2), 
            GridPosition(row: 0, col: 3), GridPosition(row: 0, col: 4)
        ], color: .red),
        BlockShape(positions: [
            GridPosition(row: 0, col: 0), GridPosition(row: 1, col: 0), GridPosition(row: 2, col: 0), 
            GridPosition(row: 3, col: 0), GridPosition(row: 4, col: 0)
        ], color: .red),
        
        // 3x2 rectangles (6 blocks)
        BlockShape(positions: [
            GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 0, col: 2),
            GridPosition(row: 1, col: 0), GridPosition(row: 1, col: 1), GridPosition(row: 1, col: 2)
        ], color: .orange),
        BlockShape(positions: [
            GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1),
            GridPosition(row: 1, col: 0), GridPosition(row: 1, col: 1),
            GridPosition(row: 2, col: 0), GridPosition(row: 2, col: 1)
        ], color: .orange),
        
        // 3x3 L-shapes (7 blocks each)
        BlockShape(positions: [
            GridPosition(row: 0, col: 0), GridPosition(row: 1, col: 0), GridPosition(row: 2, col: 0),
            GridPosition(row: 2, col: 1), GridPosition(row: 2, col: 2)
        ], color: .purple),
        BlockShape(positions: [
            GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 0, col: 2),
            GridPosition(row: 1, col: 0), GridPosition(row: 2, col: 0)
        ], color: .purple),
        BlockShape(positions: [
            GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 0, col: 2),
            GridPosition(row: 1, col: 2), GridPosition(row: 2, col: 2)
        ], color: .purple),
        BlockShape(positions: [
            GridPosition(row: 0, col: 2), GridPosition(row: 1, col: 2), GridPosition(row: 2, col: 0),
            GridPosition(row: 2, col: 1), GridPosition(row: 2, col: 2)
        ], color: .purple),
        
        // 3x3 square (9 blocks)
        BlockShape(positions: [
            GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 0, col: 2),
            GridPosition(row: 1, col: 0), GridPosition(row: 1, col: 1), GridPosition(row: 1, col: 2),
            GridPosition(row: 2, col: 0), GridPosition(row: 2, col: 1), GridPosition(row: 2, col: 2)
        ], color: .green)
    ]
    
    // Special power-up shapes
    static let horizontalClearShape = BlockShape(
        positions: [GridPosition(row: 0, col: 0)],  // Single cell representation
        color: .red,
        type: .horizontalClear
    )
    
    static let verticalClearShape = BlockShape(
        positions: [GridPosition(row: 0, col: 0)],  // Single cell representation
        color: .blue,
        type: .verticalClear
    )
}