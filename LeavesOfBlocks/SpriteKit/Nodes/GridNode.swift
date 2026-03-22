import SpriteKit

// MARK: - Grid Node

/// Renders the 8x8 game grid as a SpriteKit node tree.
///
/// `GridNode` manages 64 cell nodes arranged in an 8x8 grid layout, matching
/// the visual appearance of the SwiftUI `GameGridView`. Each cell reflects the
/// current state of the corresponding `GridCell` in the game model.
///
/// ## Coordinate System
/// The grid uses a top-left origin with Y increasing downward (matching SwiftUI layout).
/// Cell positions are calculated as:
/// ```
/// x = col * (cellSize + spacing)
/// y = row * (cellSize + spacing)
/// ```
///
/// ## Usage
/// ```swift
/// let gridNode = GridNode(cellSize: 40, spacing: 3)
/// gridNode.syncGrid(gameState.grid)
/// ```
class GridNode: SKNode {

    // MARK: - Properties

    /// Size of each grid cell in points
    let cellSize: CGFloat

    /// Spacing between grid cells in points
    let spacing: CGFloat

    /// Grid size (number of rows/columns)
    let gridSize: Int

    /// 2D array of cell shape nodes for O(1) lookup
    private var cellNodes: [[SKShapeNode]] = []

    /// Background card node behind the grid
    private let backgroundNode: SKShapeNode

    /// Total width of the grid including spacing
    var gridWidth: CGFloat {
        CGFloat(gridSize) * cellSize + CGFloat(gridSize - 1) * spacing
    }

    /// Total height of the grid including spacing
    var gridHeight: CGFloat {
        gridWidth // Square grid
    }

    // MARK: - Initialization

    /// Creates a new grid node with the specified cell dimensions.
    ///
    /// - Parameters:
    ///   - cellSize: The width and height of each cell in points (default: 40)
    ///   - spacing: The gap between cells in points (default: 3)
    ///   - gridSize: The number of rows and columns (default: 8)
    init(cellSize: CGFloat = 40, spacing: CGFloat = 3, gridSize: Int = 8) {
        self.cellSize = cellSize
        self.spacing = spacing
        self.gridSize = gridSize

        // Create background card
        let padding: CGFloat = 16 // GameTheme.Layout.mediumPadding
        let totalWidth = CGFloat(gridSize) * cellSize + CGFloat(gridSize - 1) * spacing + padding * 2
        let totalHeight = totalWidth
        let cornerRadius: CGFloat = 24 // GameTheme.Layout.cardCornerRadius

        let bgRect = CGRect(
            x: -padding,
            y: -padding,
            width: totalWidth,
            height: totalHeight
        )
        backgroundNode = SKShapeNode(rect: bgRect, cornerRadius: cornerRadius)
        backgroundNode.fillColor = SpriteKitColors.cardBackground
        backgroundNode.strokeColor = SpriteKitColors.cardBorder
        backgroundNode.lineWidth = 3 // GameTheme.Layout.strokeWidth
        backgroundNode.zPosition = -1

        super.init()

        addChild(backgroundNode)
        buildGrid()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Grid Construction

    /// Builds the initial 8x8 grid of cell shape nodes.
    private func buildGrid() {
        for row in 0..<gridSize {
            var rowNodes: [SKShapeNode] = []
            for col in 0..<gridSize {
                let cellNode = createCellNode()
                cellNode.position = cellPosition(row: row, col: col)
                cellNode.name = "cell_\(row)_\(col)"
                addChild(cellNode)
                rowNodes.append(cellNode)
            }
            cellNodes.append(rowNodes)
        }
    }

    /// Creates a single empty cell shape node.
    private func createCellNode() -> SKShapeNode {
        let rect = CGRect(x: 0, y: 0, width: cellSize, height: cellSize)
        let node = SKShapeNode(rect: rect, cornerRadius: 8)
        node.fillColor = SpriteKitColors.gridCellEmpty
        node.strokeColor = SpriteKitColors.gridCellBorder
        node.lineWidth = 1
        return node
    }

    /// Calculates the position of a cell node in the grid.
    ///
    /// - Parameters:
    ///   - row: The row index (0-based, from top)
    ///   - col: The column index (0-based, from left)
    /// - Returns: The `CGPoint` position for the cell node
    func cellPosition(row: Int, col: Int) -> CGPoint {
        let x = CGFloat(col) * (cellSize + spacing)
        let y = CGFloat(row) * (cellSize + spacing)
        return CGPoint(x: x, y: y)
    }

    // MARK: - Grid Synchronization

    /// Updates all cell visuals to match the current game grid state.
    ///
    /// Iterates through the model grid and updates each cell node's fill color,
    /// stroke color, and line width to reflect whether the cell is empty or filled.
    ///
    /// - Parameter grid: The 2D array of `GridCell` values from `GameState`
    func syncGrid(_ grid: [[GridCell]]) {
        for row in 0..<min(gridSize, grid.count) {
            for col in 0..<min(gridSize, grid[row].count) {
                let cell = grid[row][col]
                let node = cellNodes[row][col]

                if cell.isFilled {
                    node.fillColor = SpriteKitColors.blockColor(for: cell.color)
                    node.strokeColor = SpriteKitColors.gridCellFilledBorder
                    node.lineWidth = 2
                } else {
                    node.fillColor = SpriteKitColors.gridCellEmpty
                    node.strokeColor = SpriteKitColors.gridCellBorder
                    node.lineWidth = 1
                }
            }
        }
    }

    // MARK: - Preview Highlighting

    /// Shows a placement preview overlay for the given block at the specified position.
    ///
    /// Highlights cells that would be affected by placing the block, including
    /// normal block cells and special block effects (row/column/area clears).
    ///
    /// - Parameters:
    ///   - block: The `BlockShape` being previewed
    ///   - position: The grid position where the block would be placed
    ///   - canPlace: Whether the block can legally be placed at this position
    func showPreview(block: BlockShape, at position: GridPosition, canPlace: Bool) {
        guard canPlace else {
            clearPreview()
            return
        }

        let previewColor = SpriteKitColors.blockColor(for: block.color).withAlphaComponent(0.6)

        switch block.type {
        case .horizontalClear:
            for col in 0..<gridSize {
                highlightCell(row: position.row, col: col, color: previewColor)
            }
        case .verticalClear:
            for row in 0..<gridSize {
                highlightCell(row: row, col: position.col, color: previewColor)
            }
        case .areaClear:
            for dRow in -1...1 {
                for dCol in -1...1 {
                    let r = position.row + dRow
                    let c = position.col + dCol
                    if r >= 0 && r < gridSize && c >= 0 && c < gridSize {
                        highlightCell(row: r, col: c, color: previewColor)
                    }
                }
            }
        case .normal:
            for blockPos in block.positions {
                let r = position.row + blockPos.row
                let c = position.col + blockPos.col
                if r >= 0 && r < gridSize && c >= 0 && c < gridSize {
                    highlightCell(row: r, col: c, color: previewColor)
                }
            }
        }
    }

    /// Highlights a single cell with the given preview color.
    private func highlightCell(row: Int, col: Int, color: UIColor) {
        guard row >= 0 && row < gridSize && col >= 0 && col < gridSize else { return }
        let node = cellNodes[row][col]
        // Only override if not already filled
        if node.fillColor == SpriteKitColors.gridCellEmpty {
            node.fillColor = color
            node.strokeColor = color.withAlphaComponent(0.8)
            node.lineWidth = 2
        }
    }

    /// Shows line-completion highlights for rows and columns that would complete.
    ///
    /// - Parameters:
    ///   - rows: Set of row indices that would be completed
    ///   - cols: Set of column indices that would be completed
    func highlightCompletedLines(rows: Set<Int>, cols: Set<Int>) {
        let gold = SpriteKitColors.lineCompletionPrimary

        for row in rows {
            for col in 0..<gridSize {
                let node = cellNodes[row][col]
                node.fillColor = gold
                node.strokeColor = SpriteKitColors.lineCompletionAccent
                node.lineWidth = 3
            }
        }

        for col in cols {
            for row in 0..<gridSize {
                let node = cellNodes[row][col]
                node.fillColor = gold
                node.strokeColor = SpriteKitColors.lineCompletionAccent
                node.lineWidth = 3
            }
        }
    }

    /// Clears all preview highlighting, restoring cells to their model state.
    ///
    /// This should be called before re-applying previews or when the drag ends.
    /// Pass the current grid to restore accurate cell colors.
    func clearPreview() {
        // Reset all non-filled cells to empty state
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let node = cellNodes[row][col]
                // Check if this is currently showing a preview (not a filled cell color)
                if node.lineWidth != 2 || node.strokeColor == SpriteKitColors.gridCellBorder {
                    node.fillColor = SpriteKitColors.gridCellEmpty
                    node.strokeColor = SpriteKitColors.gridCellBorder
                    node.lineWidth = 1
                }
            }
        }
    }
}
