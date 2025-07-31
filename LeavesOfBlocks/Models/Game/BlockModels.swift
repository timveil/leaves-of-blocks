import Foundation

// MARK: - Block Types

/// Represents the visual color of game blocks.
///
/// Each block in the game is assigned one of these colors for visual distinction.
/// Colors follow an autumn theme that matches the game's visual design.
///
/// - Note: All cases are `Codable` for persistence and `Hashable` for efficient collections.
enum BlockColor: CaseIterable, Codable, Hashable {
    case blue, green, red, yellow, purple, orange, pink
}

/// Defines the functional behavior of game blocks.
///
/// Block types determine special abilities beyond normal placement behavior.
/// Most blocks are normal, but special power-up blocks have unique clearing effects.
enum BlockType: Codable, Hashable {
    /// Standard block with no special abilities
    case normal
    /// Special block that clears an entire horizontal row when placed
    case horizontalClear
    /// Special block that clears an entire vertical column when placed
    case verticalClear
}

// MARK: - Block Shape Model

/// Represents a complete block shape that can be placed on the game grid.
///
/// A `BlockShape` defines a collection of connected cells that form a specific pattern,
/// along with visual and behavioral properties. Blocks can range from single cells
/// to complex 9-cell arrangements.
///
/// ## Key Properties
/// - **positions**: Array of `GridPosition` values defining the block's shape
/// - **color**: Visual appearance using `BlockColor`
/// - **type**: Functional behavior using `BlockType`
///
/// ## Usage Example
/// ```swift
/// let singleBlock = BlockShape(
///     positions: [GridPosition(row: 0, col: 0)],
///     color: .blue
/// )
/// ```
struct BlockShape: Codable, Equatable, Hashable {
    /// The grid positions that make up this block shape, relative to the block's origin
    let positions: [GridPosition]
    /// The visual color of this block
    let color: BlockColor
    /// The functional type determining special abilities
    let type: BlockType
    
    /// Creates a normal block with the specified positions and color.
    ///
    /// This convenience initializer automatically sets the block type to `.normal`,
    /// which is appropriate for most game blocks.
    ///
    /// - Parameters:
    ///   - positions: Array of `GridPosition` values defining the block's shape
    ///   - color: The `BlockColor` for visual appearance
    init(positions: [GridPosition], color: BlockColor) {
        self.positions = positions
        self.color = color
        self.type = .normal
    }
    
    /// Creates a block with full specification of all properties.
    ///
    /// This initializer allows creation of special blocks with unique behaviors,
    /// such as power-ups that clear entire rows or columns.
    ///
    /// - Parameters:
    ///   - positions: Array of `GridPosition` values defining the block's shape
    ///   - color: The `BlockColor` for visual appearance
    ///   - type: The `BlockType` determining special abilities
    init(positions: [GridPosition], color: BlockColor, type: BlockType) {
        self.positions = positions
        self.color = color
        self.type = type
    }
    
    // MARK: - Predefined Shapes
    
    /// Collection of all standard block shapes available in the game.
    ///
    /// This array contains 21 predefined shapes ranging from single blocks to complex
    /// 9-cell arrangements. Shapes include straight lines, squares, L-shapes, T-shapes,
    /// and rectangles in various orientations.
    ///
    /// - Note: Used by `BlockGenerator` for weighted random selection based on difficulty.
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
    
    // MARK: - Special Power-Up Shapes
    
    /// Special power-up block that clears an entire horizontal row.
    ///
    /// When placed, this block clears all cells in its row regardless of their state.
    /// Represented visually as a single red cell with special marking.
    static let horizontalClearShape = BlockShape(
        positions: [GridPosition(row: 0, col: 0)],  // Single cell representation
        color: .red,
        type: .horizontalClear
    )
    
    /// Special power-up block that clears an entire vertical column.
    ///
    /// When placed, this block clears all cells in its column regardless of their state.
    /// Represented visually as a single blue cell with special marking.
    static let verticalClearShape = BlockShape(
        positions: [GridPosition(row: 0, col: 0)],  // Single cell representation
        color: .blue,
        type: .verticalClear
    )
}