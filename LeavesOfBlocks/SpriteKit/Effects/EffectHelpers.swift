import SpriteKit
import UIKit

// MARK: - Shared Effect Helpers

/// Namespace for utilities reused across the SpriteKit effect files. The
/// effects (line clear, block placement, game over, combo pulse, combo banner)
/// previously inlined particle-texture creation, cell-position math, and
/// fade-and-remove sequences — five copies of the same scaffolding. Future
/// tuning (e.g. a global particle slowdown for accessibility) now lands in
/// one place.
enum SpriteKitEffects {

    // MARK: - Textures

    /// Builds a solid-white circle texture of the given pixel size. Callers
    /// cache the result in a `static let` so the texture is rasterized once
    /// per emitter family. White is intentional — actual particle color comes
    /// from `particleColor`, with the texture acting as an alpha mask.
    static func makeCircleTexture(size: CGFloat) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { context in
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fillEllipse(
                in: CGRect(origin: .zero, size: CGSize(width: size, height: size))
            )
        }
        return SKTexture(image: image)
    }

    // MARK: - Cell Geometry

    /// Cell origin in content-local coordinates, given the cell size and
    /// inter-cell spacing. Mirrors `GridNode.cellPosition(row:col:)` for sites
    /// that don't have a `GridNode` reference handy (the effect helpers take
    /// generic `SKNode` parents).
    static func cellPoint(row: Int, col: Int, cellSize: CGFloat, spacing: CGFloat) -> CGPoint {
        CGPoint(
            x: CGFloat(col) * (cellSize + spacing),
            y: CGFloat(row) * (cellSize + spacing)
        )
    }
}

// MARK: - SKAction Convenience

extension SKAction {
    /// `fadeOut(withDuration:)` followed by `removeFromParent()` — the
    /// standard terminator for ephemeral effect nodes.
    static func fadeOutAndRemove(duration: TimeInterval) -> SKAction {
        SKAction.sequence([
            SKAction.fadeOut(withDuration: duration),
            SKAction.removeFromParent()
        ])
    }
}
