import SpriteKit

// MARK: - Combo Banner Effect

/// Floats a short combo title and bonus-points label up from the grid center.
///
/// `ComboBannerEffect` is the in-scene replacement for the old SwiftUI combo
/// popup. It mirrors the lifetime and palette of `LineClearEffect` and
/// `ComboPulseEffect` so combo feedback stays diegetic instead of modal.
///
/// The banner attaches to `GridNode` (not `GridNode.contentNode`) because the
/// content node uses `yScale = -1` to flip the row layout — text added there
/// would render upside down.
///
/// ## Usage
/// ```swift
/// ComboBannerEffect.play(comboCount: 3, gridNode: gridNode)
/// ```
enum ComboBannerEffect {

    // MARK: - Configuration

    private static let containerName = "ComboBanner"
    private static let zPosition: CGFloat = 100

    // MARK: - Public API

    /// Plays the combo banner effect at the visual center of the grid.
    ///
    /// Posts a VoiceOver announcement unconditionally, then renders the visual
    /// banner unless `prefersReducedMotion` is enabled.
    ///
    /// - Parameters:
    ///   - comboCount: Total lines cleared simultaneously (must be `>= 2` to look right).
    ///   - gridNode: The grid node — used as the parent so text isn't subject
    ///     to the content node's vertical flip.
    static func play(comboCount: Int, gridNode: GridNode) {
        let bonus = max(0, comboCount - 1) * GameTheme.GameConfig.comboBonus
        let title = comboTitle(for: comboCount)

        UIAccessibility.post(
            notification: .announcement,
            argument: "ax_combo_format".localized(with: title, comboCount, bonus)
        )

        guard !UIAccessibility.prefersReducedMotion else { return }

        for child in gridNode.children where child.name == containerName {
            child.removeFromParent()
        }

        let gridWidth = gridNode.gridWidth
        let center = CGPoint(x: gridNode.totalSize / 2, y: gridNode.totalSize / 2)

        let container = SKNode()
        container.name = containerName
        container.position = CGPoint(x: center.x, y: center.y - gridWidth * 0.02)
        container.zPosition = zPosition
        container.alpha = 0
        container.setScale(0.6)

        let titleFontSize = gridWidth * 0.11
        let bonusFontSize = gridWidth * (comboCount >= 5 ? 0.20 : 0.18)
        let titleOffset = bonusFontSize * 0.55
        let bonusOffset = -titleFontSize * 0.55

        let textColor = SpriteKitColors.lineCompletionPrimary

        addOutlinedLabel(
            text: title,
            fontSize: titleFontSize,
            color: textColor,
            yPosition: titleOffset,
            maxWidth: gridWidth * 0.85,
            into: container
        )

        addOutlinedLabel(
            text: "+\(bonus)",
            fontSize: bonusFontSize,
            color: textColor,
            yPosition: bonusOffset,
            maxWidth: gridWidth * 0.85,
            into: container
        )

        gridNode.addChild(container)

        let drift = gridWidth * 0.06

        let popIn = SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.18),
            SKAction.fadeIn(withDuration: 0.12)
        ])
        popIn.timingMode = .easeOut

        let rebound = SKAction.sequence([
            SKAction.scale(to: 0.95, duration: 0.06),
            SKAction.scale(to: 1.0, duration: 0.06)
        ])

        let drifting = SKAction.moveBy(x: 0, y: drift, duration: 0.35)
        drifting.timingMode = .easeOut

        let fadeOut = SKAction.group([
            SKAction.fadeOut(withDuration: 0.30),
            SKAction.scale(to: 0.92, duration: 0.30),
            SKAction.moveBy(x: 0, y: drift * 0.4, duration: 0.30)
        ])

        let sequence = SKAction.sequence([
            popIn,
            rebound,
            drifting,
            fadeOut,
            SKAction.removeFromParent()
        ])
        container.run(sequence)
    }

    // MARK: - Private Helpers

    private static func comboTitle(for comboCount: Int) -> String {
        if comboCount >= 5 {
            return "mega_combo".localized
        } else if comboCount >= 3 {
            return "combo_excited".localized
        } else {
            return "combo".localized
        }
    }

    /// Adds a label rendered with a fill + black stroke via NSAttributedString,
    /// so the text reads cleanly over the white grid cells without the muddy
    /// fringe that a 1px shadow twin produces.
    private static func addOutlinedLabel(
        text: String,
        fontSize: CGFloat,
        color: UIColor,
        yPosition: CGFloat,
        maxWidth: CGFloat,
        into container: SKNode
    ) {
        let label = SKLabelNode()
        label.attributedText = outlinedAttributedString(text: text, fontSize: fontSize, color: color)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.numberOfLines = 1
        label.position = CGPoint(x: 0, y: yPosition)
        clampWidth(label: label, maxWidth: maxWidth)
        container.addChild(label)
    }

    /// Builds an attributed string that renders both the fill color and a
    /// thick black outline. `strokeWidth` is negative so the glyph is filled
    /// AND stroked (positive values render outline only). Width scales with
    /// font size so larger text gets a proportionally heavier outline.
    private static func outlinedAttributedString(text: String, fontSize: CGFloat, color: UIColor) -> NSAttributedString {
        let font = UIFont(name: "Helvetica-Bold", size: fontSize)
            ?? UIFont.boldSystemFont(ofSize: fontSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .strokeColor: UIColor.black,
            .strokeWidth: -8.0
        ]
        return NSAttributedString(string: text, attributes: attributes)
    }

    private static func clampWidth(label: SKLabelNode, maxWidth: CGFloat) {
        let measured = label.frame.width
        guard measured > maxWidth, measured > 0 else { return }
        label.xScale = maxWidth / measured
    }
}
