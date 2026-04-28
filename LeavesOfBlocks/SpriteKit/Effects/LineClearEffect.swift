import SpriteKit
import SwiftUI

// MARK: - Line Clear Effect

/// Produces a golden sparkle particle burst along cleared rows and columns.
///
/// `LineClearEffect` creates ephemeral particle emitter nodes that burst along
/// the cleared lines, then automatically remove themselves. The effect uses
/// the game's golden/amber color scheme for visual consistency.
///
/// ## Usage
/// ```swift
/// LineClearEffect.play(
///     clearedRows: [2, 5],
///     clearedCols: [3],
///     in: gridNode,
///     cellSize: 40,
///     spacing: 3,
///     gridSize: 8
/// )
/// ```
enum LineClearEffect {

    // MARK: - Configuration

    private static let particlesPerCell: Int = 6
    private static let burstDuration: TimeInterval = 0.4
    private static let particleLifetime: TimeInterval = 0.8
    private static let particleSpeed: CGFloat = 120
    private static let particleSize: CGFloat = 6

    /// Cached sparkle texture shared across all emitters to avoid per-emitter image creation
    private static let sparkleTexture: SKTexture = {
        let size = particleSize
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { context in
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: CGSize(width: size, height: size)))
        }
        return SKTexture(image: image)
    }()

    // MARK: - Public API

    /// Plays the line-clear sparkle effect on the specified rows and columns.
    ///
    /// Creates short-lived particle emitters at each cell along every cleared
    /// line. Emitters auto-remove after the effect completes.
    ///
    /// - Parameters:
    ///   - rows: Set of row indices that were cleared
    ///   - cols: Set of column indices that were cleared
    ///   - parent: The parent node to attach effects to (typically `GridNode`)
    ///   - cellSize: Size of each grid cell in points
    ///   - spacing: Gap between cells in points
    ///   - gridSize: Number of rows/columns in the grid
    static func play(
        clearedRows rows: Set<Int>,
        clearedCols cols: Set<Int>,
        in parent: SKNode,
        cellSize: CGFloat,
        spacing: CGFloat,
        gridSize: Int
    ) {
        guard !UIAccessibility.prefersReducedMotion else { return }

        let positions = collectPositions(rows: rows, cols: cols, gridSize: gridSize)

        for (index, pos) in positions.enumerated() {
            let delay = Double(index) * 0.015
            let cellCenter = CGPoint(
                x: CGFloat(pos.col) * (cellSize + spacing) + cellSize / 2,
                y: CGFloat(pos.row) * (cellSize + spacing) + cellSize / 2
            )

            let emitter = createSparkleEmitter()
            emitter.position = cellCenter
            emitter.zPosition = 10
            parent.addChild(emitter)

            let sequence = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.run { emitter.particleBirthRate = CGFloat(particlesPerCell) / CGFloat(burstDuration) },
                SKAction.wait(forDuration: burstDuration),
                SKAction.run { emitter.particleBirthRate = 0 },
                SKAction.wait(forDuration: particleLifetime),
                SKAction.removeFromParent()
            ])
            emitter.run(sequence)
        }

        flashCells(positions: positions, in: parent, cellSize: cellSize, spacing: spacing)
    }

    // MARK: - Private Helpers

    /// Collects unique cell positions from the given cleared rows and columns.
    private static func collectPositions(rows: Set<Int>, cols: Set<Int>, gridSize: Int) -> Set<GridPosition> {
        var positions: Set<GridPosition> = []
        for row in rows {
            for col in 0..<gridSize {
                positions.insert(GridPosition(row: row, col: col))
            }
        }
        for col in cols {
            for row in 0..<gridSize {
                positions.insert(GridPosition(row: row, col: col))
            }
        }
        return positions
    }

    /// Creates a sparkle particle emitter using the cached texture.
    private static func createSparkleEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()

        emitter.particleTexture = sparkleTexture
        emitter.particleBirthRate = 0
        emitter.numParticlesToEmit = 0
        emitter.emissionAngleRange = .pi * 2

        emitter.particleSpeed = particleSpeed
        emitter.particleSpeedRange = particleSpeed * 0.5

        emitter.particleLifetime = CGFloat(particleLifetime)
        emitter.particleLifetimeRange = CGFloat(particleLifetime) * 0.3

        emitter.particleScale = 1.0
        emitter.particleScaleRange = 0.5
        emitter.particleScaleSpeed = -0.8

        emitter.particleColor = SpriteKitColors.lineCompletionPrimary
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                SpriteKitColors.lineCompletionAccent,
                SpriteKitColors.lineCompletionPrimary,
                SpriteKitColors.lineCompletionPrimary.withAlphaComponent(0)
            ],
            times: [0, 0.3, 1.0]
        )

        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -1.0
        emitter.particleBlendMode = .add

        return emitter
    }

    /// Flashes cleared cells white for a brief highlight effect.
    private static func flashCells(
        positions: Set<GridPosition>,
        in parent: SKNode,
        cellSize: CGFloat,
        spacing: CGFloat
    ) {
        for pos in positions {
            let rect = CGRect(x: 0, y: 0, width: cellSize, height: cellSize)
            let flash = SKShapeNode(rect: rect, cornerRadius: GameTheme.Layout.cellCornerRadius)
            flash.fillColor = SpriteKitColors.lineCompletionAccent.withAlphaComponent(0.5)
            flash.strokeColor = .clear
            flash.position = CGPoint(
                x: CGFloat(pos.col) * (cellSize + spacing),
                y: CGFloat(pos.row) * (cellSize + spacing)
            )
            flash.zPosition = 5
            parent.addChild(flash)

            let fadeOut = SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.removeFromParent()
            ])
            flash.run(fadeOut)
        }
    }
}
