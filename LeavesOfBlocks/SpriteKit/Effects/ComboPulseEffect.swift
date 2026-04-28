import SpriteKit

// MARK: - Combo Pulse Effect

/// Creates a radial pulse ripple across the grid when combos occur.
///
/// `ComboPulseEffect` renders an expanding, fading ring that radiates outward
/// from the grid center. The ring color and scale intensity increase with
/// the combo count, providing escalating visual feedback.
///
/// ## Combo Tiers
/// - **1 line**: Subtle golden pulse
/// - **2 lines**: Brighter amber pulse
/// - **3+ lines**: Intense golden-white pulse with larger radius
///
/// ## Usage
/// ```swift
/// ComboPulseEffect.play(comboCount: 2, gridWidth: 341, in: gridNode)
/// ```
enum ComboPulseEffect {

    // MARK: - Configuration

    /// Base duration of the pulse expansion in seconds
    private static let baseDuration: TimeInterval = 0.5

    /// Base ring stroke width
    private static let baseStrokeWidth: CGFloat = 3

    // MARK: - Public API

    /// Plays a combo pulse effect centered on the grid.
    ///
    /// Creates an expanding ring that fades out, with visual intensity
    /// proportional to the combo count.
    ///
    /// - Parameters:
    ///   - comboCount: Number of lines cleared simultaneously (1+)
    ///   - gridWidth: Width of the grid in points (used for ring radius)
    ///   - parent: The parent node to attach the effect to
    static func play(comboCount: Int, gridWidth: CGFloat, in parent: SKNode) {
        guard comboCount > 0, !UIAccessibility.prefersReducedMotion else { return }

        let tier = min(comboCount, 3)
        let center = CGPoint(x: gridWidth / 2, y: gridWidth / 2)

        // Create expanding ring
        let maxRadius = gridWidth * (0.4 + CGFloat(tier) * 0.15)
        let ring = SKShapeNode(circleOfRadius: 1)
        ring.strokeColor = ringColor(for: tier)
        ring.lineWidth = baseStrokeWidth + CGFloat(tier)
        ring.fillColor = .clear
        ring.position = center
        ring.zPosition = 8
        ring.alpha = 0.9
        parent.addChild(ring)

        let duration = baseDuration + Double(tier) * 0.1

        // Scale ring outward while fading
        let expand = SKAction.scale(to: maxRadius, duration: duration)
        expand.timingMode = .easeOut
        let fade = SKAction.fadeOut(withDuration: duration)

        let group = SKAction.group([expand, fade])
        let sequence = SKAction.sequence([group, SKAction.removeFromParent()])
        ring.run(sequence)

        // For higher combos, add a second delayed ring
        if tier >= 2 {
            let ring2 = SKShapeNode(circleOfRadius: 1)
            ring2.strokeColor = ringColor(for: tier).withAlphaComponent(0.5)
            ring2.lineWidth = baseStrokeWidth
            ring2.fillColor = .clear
            ring2.position = center
            ring2.zPosition = 7
            ring2.alpha = 0.7
            parent.addChild(ring2)

            let delay = SKAction.wait(forDuration: 0.1)
            let expand2 = SKAction.scale(to: maxRadius * 0.8, duration: duration * 0.9)
            expand2.timingMode = .easeOut
            let fade2 = SKAction.fadeOut(withDuration: duration * 0.9)
            let group2 = SKAction.group([expand2, fade2])
            let sequence2 = SKAction.sequence([delay, group2, SKAction.removeFromParent()])
            ring2.run(sequence2)
        }

        // For 3+ combos, add a brief screen flash
        if tier >= 3 {
            let flash = SKShapeNode(rect: CGRect(x: -20, y: -20, width: gridWidth + 40, height: gridWidth + 40))
            flash.fillColor = SpriteKitColors.lineCompletionAccent.withAlphaComponent(0.2)
            flash.strokeColor = .clear
            flash.zPosition = 6
            parent.addChild(flash)

            let flashFade = SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.25),
                SKAction.removeFromParent()
            ])
            flash.run(flashFade)
        }
    }

    // MARK: - Private Helpers

    /// Returns the ring color for the given combo tier.
    private static func ringColor(for tier: Int) -> UIColor {
        switch tier {
        case 1:
            return SpriteKitColors.lineCompletionPrimary.withAlphaComponent(0.7)
        case 2:
            return SpriteKitColors.lineCompletionAccent.withAlphaComponent(0.8)
        default:
            return SpriteKitColors.lineCompletionPrimary.withAlphaComponent(0.9)
        }
    }
}
