import SpriteKit
import SwiftUI
import UIKit

// MARK: - SpriteKit Color Bridge

/// Bridges the game's SwiftUI color system to `UIColor` for use in SpriteKit nodes.
///
/// SpriteKit uses `UIColor` (via `SKColor`) rather than SwiftUI's `Color` type.
/// All colors derive from `GameTheme.Colors` to maintain a single source of truth.
///
/// ## Usage
/// ```swift
/// let cellColor = SpriteKitColors.blockColor(for: .blue)
/// let bgColor = SpriteKitColors.gridCellEmpty
/// ```
enum SpriteKitColors {

    // MARK: - Block Colors

    /// Returns the `UIColor` for a given `BlockColor` case.
    static func blockColor(for blockColor: BlockColor) -> UIColor {
        UIColor(blockColor.color)
    }

    // MARK: - Grid Colors

    /// Empty grid cell background color
    static let gridCellEmpty = UIColor.white

    /// Grid line color (bold black for folk-art style)
    static let gridLineColor = UIColor.black

    // MARK: - Preview Colors

    /// Line completion highlight color (warm gold)
    static let lineCompletionPrimary = UIColor(GameTheme.Colors.lineCompletionPrimary)

    /// Line completion accent color
    static let lineCompletionAccent = UIColor(GameTheme.Colors.lineCompletionAccent)

    // MARK: - Block Cell Overlay

    /// Border overlay used on block cells (black outline for folk-art style)
    static let blockCellOverlay = UIColor.black.withAlphaComponent(0.3)

    // MARK: - Text Colors

    /// Light text color for icon overlays on special blocks
    static let buttonText = UIColor(GameTheme.Colors.buttonText)

    // MARK: - Effect Colors

    /// Desaturated wash color for game-over grid overlay
    static let gameOverDesaturation = UIColor(GameTheme.Colors.gameOverDesaturation)

    /// Dark ink color for effect glow borders
    static let effectBorder = UIColor(GameTheme.Colors.effectBorder)

    // MARK: - Scene Colors

    /// Scene background (transparent to let SwiftUI background show through)
    static let sceneBackground = UIColor.clear
}
