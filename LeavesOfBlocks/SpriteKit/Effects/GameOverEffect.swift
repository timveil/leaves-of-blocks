import SpriteKit
import SwiftUI

// MARK: - Game Over Effect

/// Provides visual effects for game-over and new-high-score events.
///
/// `GameOverEffect` offers two distinct effects:
/// - **Game Over**: Grid cells cascade-fade to grey with a downward sweep
/// - **New High Score**: Golden firework-style celebration burst from the grid center
///
/// Effects are played in the SpriteKit scene to add visual impact beyond what the
/// SwiftUI overlay provides.
///
/// ## Usage
/// ```swift
/// GameOverEffect.playGameOver(in: gridNode, cellSize: 40, spacing: 3, gridSize: 8)
/// GameOverEffect.playHighScoreCelebration(gridWidth: 341, in: gridNode)
/// ```
enum GameOverEffect {

    // MARK: - Game Over Sweep

    /// Plays a cascading grey-out sweep across the grid when the game ends.
    ///
    /// Each row fades to a desaturated brown with a staggered delay, creating
    /// a top-to-bottom sweep that visually "shuts down" the grid.
    ///
    /// - Parameters:
    ///   - parent: The parent node (typically `GridNode`)
    ///   - cellSize: Size of each grid cell in points
    ///   - spacing: Gap between cells in points
    ///   - gridSize: Number of rows/columns
    static func playGameOver(
        in parent: SKNode,
        cellSize: CGFloat,
        spacing: CGFloat,
        gridSize: Int
    ) {
        let desaturatedColor = SpriteKitColors.gameOverDesaturation.withAlphaComponent(0.7)

        for row in 0..<gridSize {
            let delay = Double(row) * 0.06

            for col in 0..<gridSize {
                let overlay = SKShapeNode(
                    rect: CGRect(x: 0, y: 0, width: cellSize, height: cellSize),
                    cornerRadius: GameTheme.Layout.cellCornerRadius
                )
                overlay.fillColor = desaturatedColor
                overlay.strokeColor = .clear
                overlay.alpha = 0
                overlay.position = SpriteKitEffects.cellPoint(
                    row: row, col: col,
                    cellSize: cellSize, spacing: spacing
                )
                overlay.zPosition = 15
                overlay.name = GridNode.gameOverOverlayName
                parent.addChild(overlay)

                let fadeIn = SKAction.sequence([
                    SKAction.wait(forDuration: delay),
                    SKAction.fadeAlpha(to: 0.6, duration: 0.2)
                ])
                overlay.run(fadeIn)
            }
        }
    }

    /// Removes all game-over overlay nodes, restoring the grid appearance.
    ///
    /// - Parameter parent: The parent node containing the overlays
    static func clearGameOver(in parent: SKNode) {
        parent.enumerateChildNodes(withName: GridNode.gameOverOverlayName) { node, _ in
            node.run(.fadeOutAndRemove(duration: 0.15))
        }
    }

    // MARK: - High Score Celebration

    /// Plays a golden firework celebration burst for a new high score.
    ///
    /// Creates multiple radial particle bursts from the grid center with golden
    /// and white sparkles, plus expanding rings for extra emphasis.
    ///
    /// - Parameters:
    ///   - gridWidth: Width of the grid in points
    ///   - parent: The parent node to attach effects to
    static func playHighScoreCelebration(gridWidth: CGFloat, in parent: SKNode) {
        guard !UIAccessibility.isReduceMotionEnabled else { return }

        let center = CGPoint(x: gridWidth / 2, y: gridWidth / 2)

        // Primary burst - golden sparkles
        let primaryBurst = createCelebrationEmitter(
            color: SpriteKitColors.lineCompletionPrimary,
            speed: 200,
            count: 40
        )
        primaryBurst.position = center
        primaryBurst.zPosition = 20
        parent.addChild(primaryBurst)

        // Secondary burst (delayed) - white sparkles
        let secondaryBurst = createCelebrationEmitter(
            color: SpriteKitColors.lineCompletionAccent,
            speed: 150,
            count: 25
        )
        secondaryBurst.position = center
        secondaryBurst.zPosition = 19
        parent.addChild(secondaryBurst)

        // Stagger the bursts
        let primarySequence = SKAction.sequence([
            SKAction.wait(forDuration: 0.0),
            SKAction.run { primaryBurst.particleBirthRate = 120 },
            SKAction.wait(forDuration: 0.3),
            SKAction.run { primaryBurst.particleBirthRate = 0 },
            SKAction.wait(forDuration: 1.5),
            SKAction.removeFromParent()
        ])
        primaryBurst.run(primarySequence)

        let secondarySequence = SKAction.sequence([
            SKAction.wait(forDuration: 0.15),
            SKAction.run { secondaryBurst.particleBirthRate = 80 },
            SKAction.wait(forDuration: 0.25),
            SKAction.run { secondaryBurst.particleBirthRate = 0 },
            SKAction.wait(forDuration: 1.5),
            SKAction.removeFromParent()
        ])
        secondaryBurst.run(secondarySequence)

        // Expanding golden rings
        for i in 0..<3 {
            let ring = SKShapeNode(circleOfRadius: 1)
            ring.strokeColor = SpriteKitColors.lineCompletionAccent.withAlphaComponent(0.8)
            ring.lineWidth = 4 - CGFloat(i)
            ring.fillColor = .clear
            ring.position = center
            ring.zPosition = 18
            parent.addChild(ring)

            let delay = Double(i) * 0.2
            let maxRadius = gridWidth * (0.3 + CGFloat(i) * 0.15)
            let expand = SKAction.scale(to: maxRadius, duration: 0.6)
            expand.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.6)

            let sequence = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([expand, fade]),
                SKAction.removeFromParent()
            ])
            ring.run(sequence)
        }
    }

    // MARK: - Private Helpers

    /// Cached circle texture shared across celebration emitters
    private static let celebrationTexture: SKTexture = SpriteKitEffects.makeCircleTexture(size: 5)

    private static func createCelebrationEmitter(
        color: UIColor,
        speed: CGFloat,
        count: Int
    ) -> SKEmitterNode {
        let emitter = SKEmitterNode()

        emitter.particleTexture = celebrationTexture

        // Emission
        emitter.particleBirthRate = 0 // Controlled by action sequence
        emitter.numParticlesToEmit = 0
        emitter.emissionAngleRange = .pi * 2

        // Motion
        emitter.particleSpeed = speed
        emitter.particleSpeedRange = speed * 0.5
        emitter.yAcceleration = 50 // Slight downward pull (gravity feel)

        // Lifetime
        emitter.particleLifetime = 1.2
        emitter.particleLifetimeRange = 0.4

        // Size
        emitter.particleScale = 1.2
        emitter.particleScaleRange = 0.6
        emitter.particleScaleSpeed = -0.6

        // Color
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                color,
                color.withAlphaComponent(0.8),
                color.withAlphaComponent(0)
            ],
            times: [0, 0.4, 1.0]
        )

        // Alpha
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -0.6

        // Glow effect
        emitter.particleBlendMode = .add

        return emitter
    }
}
