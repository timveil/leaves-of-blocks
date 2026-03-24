import SpriteKit

// MARK: - Falling Leaves Effect

/// Produces ambient falling leaf particles that drift across the game grid.
///
/// `FallingLeavesEffect` creates a persistent `SKEmitterNode` that emits small
/// leaf-shaped particles from the top of the scene. Leaves gently drift downward
/// with horizontal sway, using autumn colors from the game's palette.
///
/// The emitter is designed to run continuously during gameplay as atmospheric
/// decoration. It respects `AppConfiguration.Performance.maxFallingLeaves`.
///
/// ## Usage
/// ```swift
/// let emitter = FallingLeavesEffect.createEmitter(sceneWidth: 373)
/// scene.addChild(emitter)
/// ```
enum FallingLeavesEffect {

    // MARK: - Constants

    /// Node name for the falling leaves emitter
    static let nodeName = "fallingLeaves"

    // MARK: - Configuration

    private static let birthRate: CGFloat = 3

    /// Leaf particle lifetime in seconds
    private static let lifetime: CGFloat = 8

    /// Leaf fall speed in points per second
    private static let fallSpeed: CGFloat = 30

    /// Leaf size in points
    private static let leafSize: CGFloat = 8

    /// Rotation speed (radians per second)
    private static let rotationSpeed: CGFloat = 1.5

    // MARK: - Leaf Colors

    /// Autumn leaf color palette
    private static let leafColors: [UIColor] = [
        UIColor(red: 0.9, green: 0.7, blue: 0.1, alpha: 0.6),  // Golden amber
        UIColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 0.5),  // Burnt orange
        UIColor(red: 0.8, green: 0.2, blue: 0.1, alpha: 0.4),  // Crimson red
        UIColor(red: 0.8, green: 0.4, blue: 0.1, alpha: 0.5),  // Deep orange
        UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 0.4)   // Brown
    ]

    // MARK: - Public API

    /// Creates a falling leaves particle emitter positioned at the top of the scene.
    ///
    /// The emitter runs continuously and should be added as a child of the main scene.
    /// Particles are low-alpha and use `.alpha` blend mode to remain subtle.
    ///
    /// - Parameter sceneWidth: Width of the scene in points (emitter spans this width)
    /// - Returns: A configured `SKEmitterNode` ready to be added to the scene
    static func createEmitter(sceneWidth: CGFloat) -> SKEmitterNode {
        let emitter = SKEmitterNode()

        // Leaf texture - small rounded diamond shape
        emitter.particleTexture = SKTexture(image: createLeafImage())

        // Emission from top, spanning full width
        emitter.position = CGPoint(x: sceneWidth / 2, y: -10)
        emitter.particlePositionRange = CGVector(dx: sceneWidth, dy: 0)

        // Birth rate capped by performance setting
        let maxLeaves = CGFloat(AppConfiguration.Performance.maxFallingLeaves)
        let cappedRate = min(birthRate, maxLeaves / lifetime)
        emitter.particleBirthRate = cappedRate
        emitter.numParticlesToEmit = 0 // Continuous

        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 8
        emitter.particleSpeed = fallSpeed
        emitter.particleSpeedRange = fallSpeed * 0.4
        emitter.xAcceleration = 0

        // Lifetime
        emitter.particleLifetime = lifetime
        emitter.particleLifetimeRange = lifetime * 0.3

        // Size with variation
        emitter.particleScale = 1.0
        emitter.particleScaleRange = 0.5
        emitter.particleScaleSpeed = -0.05

        // Rotation for tumbling effect
        emitter.particleRotation = 0
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = rotationSpeed

        // Color sequence through autumn palette
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColor = leafColors[0]
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: leafColors,
            times: [0, 0.25, 0.5, 0.75, 1.0] as [NSNumber]
        )
        emitter.particleColorBlendFactorSequence = SKKeyframeSequence(
            keyframeValues: [1.0, 1.0, 1.0, 1.0, 1.0] as [NSNumber],
            times: [0, 0.25, 0.5, 0.75, 1.0] as [NSNumber]
        )

        // Alpha - subtle presence
        emitter.particleAlpha = 0.5
        emitter.particleAlphaRange = 0.2
        emitter.particleAlphaSpeed = -0.05

        // Blend mode - normal for natural look
        emitter.particleBlendMode = .alpha

        emitter.zPosition = -5 // Behind grid
        emitter.name = FallingLeavesEffect.nodeName

        return emitter
    }

    /// Pauses or resumes the falling leaves emitter.
    ///
    /// - Parameters:
    ///   - paused: `true` to stop emitting new leaves (existing ones finish)
    ///   - parent: The scene containing the emitter
    static func setPaused(_ paused: Bool, in parent: SKNode) {
        if let emitter = parent.childNode(withName: FallingLeavesEffect.nodeName) as? SKEmitterNode {
            emitter.particleBirthRate = paused ? 0 : min(birthRate, CGFloat(AppConfiguration.Performance.maxFallingLeaves) / lifetime)
        }
    }

    // MARK: - Private Helpers

    /// Creates a small leaf-shaped image for the particle texture.
    private static func createLeafImage() -> UIImage {
        let size = CGSize(width: leafSize, height: leafSize * 1.4)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let ctx = context.cgContext
            ctx.setFillColor(UIColor.white.cgColor)

            // Draw a simple leaf/diamond shape
            let path = UIBezierPath()
            path.move(to: CGPoint(x: size.width / 2, y: 0))
            path.addQuadCurve(
                to: CGPoint(x: size.width / 2, y: size.height),
                controlPoint: CGPoint(x: size.width, y: size.height * 0.4)
            )
            path.addQuadCurve(
                to: CGPoint(x: size.width / 2, y: 0),
                controlPoint: CGPoint(x: 0, y: size.height * 0.4)
            )
            path.close()
            ctx.addPath(path.cgPath)
            ctx.fillPath()
        }
    }
}
