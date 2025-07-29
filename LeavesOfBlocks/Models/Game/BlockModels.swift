import Foundation

enum BlockColor: CaseIterable, Codable, Hashable {
    case blue, green, red, yellow, purple, orange, pink
}

struct BlockShape: Codable, Equatable, Hashable {
    let positions: [GridPosition]
    let color: BlockColor
    
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
}