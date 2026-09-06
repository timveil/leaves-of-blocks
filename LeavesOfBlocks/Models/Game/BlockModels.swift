import Foundation

// MARK: - Block Types

/// Represents the visual color of game blocks.
///
/// Each block in the game is assigned one of these colors for visual distinction.
///
/// - Note: All cases are `Codable` for persistence and `Hashable` for efficient collections.
enum BlockColor: String, CaseIterable, Codable, Hashable {
    case blue, green, red, yellow, purple, orange, pink

    var accessibilityName: String {
        switch self {
        case .blue:   return "ax_color_blue".localized
        case .green:  return "ax_color_green".localized
        case .red:    return "ax_color_red".localized
        case .yellow: return "ax_color_yellow".localized
        case .purple: return "ax_color_purple".localized
        case .orange: return "ax_color_orange".localized
        case .pink:   return "ax_color_pink".localized
        }
    }
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
    /// Special block that clears a 3x3 area centered on placement when placed
    ///
    /// When this block type is placed on the grid, it clears all cells in a 3x3 area
    /// centered on the placement position. The clearing effect extends one cell in
    /// each direction (horizontal, vertical, and diagonal) from the center position.
    /// Cells outside the grid boundaries are safely ignored during the clearing process.
    ///
    /// - Note: This block type awards double the points of single-line clearing blocks
    /// - Visual Representation: Purple block with a 3D layered cube icon (`square.3.layers.3d`)
    case areaClear
    
    /// Returns the system icon name for special blocks
    var systemIconName: String {
        switch self {
        case .horizontalClear:
            return "arrow.left.and.right"
        case .verticalClear:
            return "arrow.up.and.down"
        case .areaClear:
            return "square.3.layers.3d"
        case .normal:
            return ""
        }
    }
}

// MARK: - Geometric Patterns

/// Defines geometric patterns used for structured grid initialization.
///
/// These patterns provide structured placement alternatives to random block placement,
/// creating more visually appealing and strategically interesting initial grid states.
/// Pattern usage varies by difficulty mode:
///
/// - **Easy**: Simple patterns (line2, diagonal, corner) with 8-10% grid fill
/// - **Moderate**: All patterns available with balanced weights and 12-15% fill  
/// - **Hard**: Complex patterns (cross, square2x2, zigzag) with 15-20% fill
///
/// Each pattern defines relative positions from a base coordinate, allowing flexible
/// placement anywhere on the grid while maintaining geometric structure.
enum GeometricPattern: String, CaseIterable {
    case line2 = "line_2"           // 2-cell horizontal line
    case line3 = "line_3"           // 3-cell horizontal line
    case corner = "corner"          // L-shaped corner (3 cells)
    case diagonal = "diagonal"      // 2-cell diagonal
    case square2x2 = "square_2x2"   // 2x2 square
    case cross = "cross"            // Plus/cross shape (5 cells)
    case triangle = "triangle"      // Triangle shape (3 cells)
    case zigzag = "zigzag"          // Zigzag pattern (4 cells)
    
    /// Returns the relative positions that make up this geometric pattern
    var positions: [GridPosition] {
        switch self {
        case .line2:
            return [
                GridPosition(row: 0, col: 0),
                GridPosition(row: 0, col: 1)
            ]
            
        case .line3:
            return [
                GridPosition(row: 0, col: 0),
                GridPosition(row: 0, col: 1),
                GridPosition(row: 0, col: 2)
            ]
            
        case .corner:
            return [
                GridPosition(row: 0, col: 0),
                GridPosition(row: 0, col: 1),
                GridPosition(row: 1, col: 0)
            ]
            
        case .diagonal:
            return [
                GridPosition(row: 0, col: 0),
                GridPosition(row: 1, col: 1)
            ]
            
        case .square2x2:
            return [
                GridPosition(row: 0, col: 0),
                GridPosition(row: 0, col: 1),
                GridPosition(row: 1, col: 0),
                GridPosition(row: 1, col: 1)
            ]
            
        case .cross:
            return [
                GridPosition(row: 0, col: 1),  // Top
                GridPosition(row: 1, col: 0),  // Left
                GridPosition(row: 1, col: 1),  // Center
                GridPosition(row: 1, col: 2),  // Right
                GridPosition(row: 2, col: 1)   // Bottom
            ]
            
        case .triangle:
            return [
                GridPosition(row: 0, col: 1),  // Top
                GridPosition(row: 1, col: 0),  // Bottom left
                GridPosition(row: 1, col: 2)   // Bottom right
            ]
            
        case .zigzag:
            return [
                GridPosition(row: 0, col: 0),
                GridPosition(row: 0, col: 1),
                GridPosition(row: 1, col: 1),
                GridPosition(row: 1, col: 2)
            ]
        }
    }
    
    /// Returns the size (number of cells) of this pattern
    var size: Int {
        return positions.count
    }
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
struct BlockShape: Codable, Equatable, Hashable, Identifiable {
    /// Stable instance identity assigned at construction time. Two blocks with
    /// the same shape, color, and type still receive distinct `id`s — this is
    /// what `GameState.placeBlock` keys removal on, so placing one of two
    /// look-alike offered blocks doesn't accidentally remove the other.
    ///
    /// `Equatable` and `Hashable` deliberately ignore `id` so that
    /// `[BlockShape: Weight]` dictionaries (BlockGenerator) and snapshot
    /// equality continue to compare blocks by shape.
    let id: UUID
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
        self.id = UUID()
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
        self.id = UUID()
        self.positions = positions
        self.color = color
        self.type = type
    }

    // MARK: - Equatable / Hashable (value-based)

    static func == (lhs: BlockShape, rhs: BlockShape) -> Bool {
        lhs.positions == rhs.positions && lhs.color == rhs.color && lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(positions)
        hasher.combine(color)
        hasher.combine(type)
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case id, positions, color, type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Older snapshots predate `id`; decoding gracefully assigns a fresh
        // UUID so the rest of the snapshot still loads.
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.positions = try container.decode([GridPosition].self, forKey: .positions)
        self.color = try container.decode(BlockColor.self, forKey: .color)
        self.type = try container.decode(BlockType.self, forKey: .type)
    }
    
    var accessibilityLabel: String {
        switch type {
        case .horizontalClear: return "ax_row_clear_block".localized
        case .verticalClear:   return "ax_column_clear_block".localized
        case .areaClear:       return "ax_area_clear_block".localized
        case .normal:          return "ax_block_format".localized(with: positions.count, color.accessibilityName)
        }
    }

    // MARK: - Predefined Shapes
    
    /// Collection of all standard block shapes available in the game.
    ///
    /// This array contains the predefined shapes, ranging from single blocks to
    /// complex 9-cell arrangements. Shapes include straight lines, squares, L-shapes, T-shapes,
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
    /// Each access mints a fresh `BlockShape` so the `id` is unique per
    /// generated instance — required for `GameState.placeBlock` to remove the
    /// exact block the player dragged.
    static var horizontalClearShape: BlockShape {
        BlockShape(
            positions: [GridPosition(row: 0, col: 0)],
            color: .red,
            type: .horizontalClear
        )
    }

    /// Special power-up block that clears an entire vertical column.
    ///
    /// Each access mints a fresh `BlockShape`; see `horizontalClearShape`.
    static var verticalClearShape: BlockShape {
        BlockShape(
            positions: [GridPosition(row: 0, col: 0)],
            color: .blue,
            type: .verticalClear
        )
    }

    /// Special power-up block that clears a 3x3 area centered on placement.
    ///
    /// When placed, this block clears all cells in a 3x3 area centered on the placement position.
    /// The clearing effect extends one cell in each direction from the center, creating a 3x3 grid
    /// of cleared cells. Cells outside the grid boundaries are safely ignored during clearing.
    ///
    /// Each access mints a fresh `BlockShape`; see `horizontalClearShape`.
    static var areaClearShape: BlockShape {
        BlockShape(
            positions: [GridPosition(row: 0, col: 0)],
            color: .purple,
            type: .areaClear
        )
    }
}