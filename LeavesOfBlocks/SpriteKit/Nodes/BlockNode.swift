import SpriteKit

// MARK: - Block Node

/// Renders a `BlockShape` as a SpriteKit node tree.
///
/// `BlockNode` creates a visual representation of a game block using `SKShapeNode`
/// children for each cell position. It supports both normal multi-cell blocks and
/// special power-up blocks with icon overlays.
///
/// ## Visual Style
/// Normal blocks render as rounded rectangles with the block's color, a cream
/// border overlay, and subtle shadows — matching the SwiftUI `BlockView` appearance.
///
/// Special blocks (horizontal clear, vertical clear, area clear) render as a single
/// colored cell with an SF Symbol icon overlay.
///
/// ## Usage
/// ```swift
/// let blockNode = BlockNode(block: someBlockShape, cellSize: 40)
/// scene.addChild(blockNode)
/// ```
class BlockNode: SKNode {

    // MARK: - Properties

    /// The block shape this node represents
    let block: BlockShape

    /// Size of each cell in points
    let cellSize: CGFloat

    // MARK: - Initialization

    /// Creates a new block node for the given shape.
    ///
    /// - Parameters:
    ///   - block: The `BlockShape` to render
    ///   - cellSize: The width and height of each cell in points
    init(block: BlockShape, cellSize: CGFloat) {
        self.block = block
        self.cellSize = cellSize
        super.init()
        buildBlock()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Block Construction

    /// Builds the visual representation of the block.
    private func buildBlock() {
        let color = SpriteKitColors.blockColor(for: block.color)

        switch block.type {
        case .horizontalClear, .verticalClear, .areaClear:
            buildSpecialBlock(color: color)
        case .normal:
            buildNormalBlock(color: color)
        }
    }

    /// Builds a normal multi-cell block.
    private func buildNormalBlock(color: UIColor) {
        let bounds = block.getBounds()

        for position in block.positions {
            let cellRect = CGRect(x: 0, y: 0, width: cellSize - 2, height: cellSize - 2)
            let cellNode = SKShapeNode(rect: cellRect, cornerRadius: 8)
            cellNode.fillColor = color
            cellNode.strokeColor = SpriteKitColors.blockCellOverlay
            cellNode.lineWidth = 1.5

            let offsetX = CGFloat(position.col - bounds.minCol) * cellSize
            let offsetY = CGFloat(position.row - bounds.minRow) * cellSize
            cellNode.position = CGPoint(x: offsetX + 1, y: offsetY + 1)

            addChild(cellNode)
        }
    }

    /// Builds a special power-up block with icon overlay.
    private func buildSpecialBlock(color: UIColor) {
        let cellRect = CGRect(x: 0, y: 0, width: cellSize - 2, height: cellSize - 2)
        let cellNode = SKShapeNode(rect: cellRect, cornerRadius: 12)
        cellNode.fillColor = color
        cellNode.strokeColor = SpriteKitColors.blockCellOverlay
        cellNode.lineWidth = 1.5

        addChild(cellNode)

        // Add icon label using SF Symbol name rendered as text
        let iconName = block.type.systemIconName
        if !iconName.isEmpty {
            let iconLabel = SKLabelNode(text: iconSymbol(for: block.type))
            iconLabel.fontSize = cellSize * 0.4
            iconLabel.fontColor = UIColor(red: 0.984, green: 0.965, blue: 0.925, alpha: 1.0)
            iconLabel.fontName = "Helvetica-Bold"
            iconLabel.verticalAlignmentMode = .center
            iconLabel.horizontalAlignmentMode = .center
            iconLabel.position = CGPoint(x: (cellSize - 2) / 2, y: (cellSize - 2) / 2)
            iconLabel.zPosition = 1
            addChild(iconLabel)
        }
    }

    /// Returns a text symbol for the block type since SpriteKit doesn't natively support SF Symbols.
    private func iconSymbol(for type: BlockType) -> String {
        switch type {
        case .horizontalClear: return "\u{2194}" // ↔
        case .verticalClear:   return "\u{2195}" // ↕
        case .areaClear:       return "\u{25A3}" // ▣
        case .normal:          return ""
        }
    }

    // MARK: - Visual State

    /// Applies drag appearance to the block node.
    ///
    /// Scales up slightly and adds emphasis when the block is being dragged.
    ///
    /// - Parameter active: `true` to show drag state, `false` for resting state
    func setDragAppearance(active: Bool) {
        let scale: CGFloat = active ? 1.1 : 1.0
        let action = SKAction.scale(to: scale, duration: 0.1)
        action.timingMode = .easeInEaseOut
        run(action)
    }

    /// Returns the bounding size of this block in points.
    var boundingSize: CGSize {
        let bounds = block.getBounds()
        return CGSize(
            width: CGFloat(bounds.width) * cellSize,
            height: CGFloat(bounds.height) * cellSize
        )
    }
}
