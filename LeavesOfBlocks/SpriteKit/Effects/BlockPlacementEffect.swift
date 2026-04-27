import SpriteKit
import SwiftUI

// MARK: - Block Placement Effect

/// Animates cells popping into place when a block is placed on the grid.
///
/// `BlockPlacementEffect` creates a satisfying "pop" animation on each cell
/// of a newly placed block. Cells scale up slightly then settle, with a brief
/// glow overlay that fades out. The effect staggers across cells for a
/// cascading feel.
///
/// ## Usage
/// ```swift
/// BlockPlacementEffect.play(
///     block: placedBlock,
///     at: gridPosition,
///     in: gridNode,
///     cellSize: 40,
///     spacing: 3
/// )
/// ```
enum BlockPlacementEffect {

    // MARK: - Configuration

    /// Scale overshoot during the pop animation
    private static let popScale: CGFloat = 1.2

    /// Duration of each cell's pop animation
    private static let popDuration: TimeInterval = 0.15

    /// Settle-back duration after the pop
    private static let settleDuration: TimeInterval = 0.1

    /// Stagger delay between consecutive cells
    private static let staggerDelay: TimeInterval = 0.03

    /// Glow overlay opacity
    private static let glowOpacity: CGFloat = 0.5

    // MARK: - Public API

    /// Plays the block placement pop animation.
    ///
    /// Each cell of the block briefly scales up then settles back, with a
    /// white glow overlay that fades out. Cells are staggered for a cascade.
    ///
    /// - Parameters:
    ///   - block: The `BlockShape` that was placed
    ///   - position: The `GridPosition` where the block was placed
    ///   - parent: The parent node (typically `GridNode`) to attach effects to
    ///   - cellSize: Size of each grid cell in points
    ///   - spacing: Gap between cells in points
    static func play(
        block: BlockShape,
        at position: GridPosition,
        in parent: SKNode,
        cellSize: CGFloat,
        spacing: CGFloat
    ) {
        let color = SpriteKitColors.blockColor(for: block.color)

        for (index, blockPos) in block.positions.enumerated() {
            let row = position.row + blockPos.row
            let col = position.col + blockPos.col

            let delay = Double(index) * staggerDelay

            let cellName = GridNode.cellName(row: row, col: col)
            if let cellNode = parent.childNode(withName: cellName) as? SKShapeNode {
                animateCellPop(cellNode, delay: delay)
            }

            // Add a glow overlay at the cell position
            let cellPoint = CGPoint(
                x: CGFloat(col) * (cellSize + spacing),
                y: CGFloat(row) * (cellSize + spacing)
            )
            addGlowOverlay(at: cellPoint, color: color, cellSize: cellSize, delay: delay, in: parent)
        }
    }

    // MARK: - Private Helpers

    /// Animates a cell node with a pop-and-settle scale effect.
    private static func animateCellPop(_ node: SKShapeNode, delay: TimeInterval) {
        let popUp = SKAction.scale(to: popScale, duration: popDuration)
        popUp.timingMode = .easeOut
        let settle = SKAction.scale(to: 1.0, duration: settleDuration)
        settle.timingMode = .easeInEaseOut

        let sequence = SKAction.sequence([
            SKAction.wait(forDuration: delay),
            popUp,
            settle
        ])
        node.run(sequence)
    }

    /// Adds a brief white glow overlay that fades out.
    private static func addGlowOverlay(
        at position: CGPoint,
        color: UIColor,
        cellSize: CGFloat,
        delay: TimeInterval,
        in parent: SKNode
    ) {
        let rect = CGRect(x: 0, y: 0, width: cellSize, height: cellSize)
        let glow = SKShapeNode(rect: rect, cornerRadius: GameTheme.Layout.cellCornerRadius)
        glow.fillColor = color.withAlphaComponent(glowOpacity)
        glow.strokeColor = SpriteKitColors.effectBorder.withAlphaComponent(0.3)
        glow.lineWidth = 2
        glow.position = position
        glow.zPosition = 4
        glow.setScale(popScale)
        parent.addChild(glow)

        let sequence = SKAction.sequence([
            SKAction.wait(forDuration: delay),
            SKAction.group([
                SKAction.scale(to: 1.0, duration: popDuration + settleDuration),
                SKAction.fadeOut(withDuration: popDuration + settleDuration + 0.1)
            ]),
            SKAction.removeFromParent()
        ])
        glow.run(sequence)
    }
}
