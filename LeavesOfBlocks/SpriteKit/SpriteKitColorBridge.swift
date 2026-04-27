import SpriteKit
import UIKit

// MARK: - SpriteKit Color Bridge

/// Bridges the game's SwiftUI color system to `UIColor` for use in SpriteKit nodes.
///
/// SpriteKit uses `UIColor` (via `SKColor`) rather than SwiftUI's `Color` type.
/// This utility provides consistent color mappings so that the SpriteKit rendering
/// matches the existing SwiftUI appearance defined in `GameTheme.Colors`.
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
        switch blockColor {
        case .blue:   return UIColor(red: 0.082, green: 0.459, blue: 0.443, alpha: 1.0)
        case .green:  return UIColor(red: 0.239, green: 0.541, blue: 0.310, alpha: 1.0)
        case .red:    return UIColor(red: 0.753, green: 0.224, blue: 0.169, alpha: 1.0)
        case .yellow: return UIColor(red: 0.804, green: 0.600, blue: 0.239, alpha: 1.0)
        case .purple: return UIColor(red: 0.384, green: 0.216, blue: 0.188, alpha: 1.0)
        case .orange: return UIColor(red: 0.906, green: 0.530, blue: 0.200, alpha: 1.0)
        case .pink:   return UIColor(red: 0.886, green: 0.561, blue: 0.388, alpha: 1.0)
        }
    }

    // MARK: - Grid Colors

    /// Empty grid cell background color
    static let gridCellEmpty = UIColor(red: 0.929, green: 0.890, blue: 0.812, alpha: 0.4)

    /// Empty grid cell border color
    static let gridCellBorder = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.15)

    /// Filled grid cell border color
    static let gridCellFilledBorder = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3)

    /// Grid card background color (white)
    static let cardBackground = UIColor.white

    /// Card border color (solid black)
    static let cardBorder = UIColor.black

    // MARK: - Preview Colors

    /// Line completion highlight color (warm gold)
    static let lineCompletionPrimary = UIColor(red: 0.859, green: 0.678, blue: 0.341, alpha: 1.0)

    /// Line completion accent color
    static let lineCompletionAccent = UIColor(red: 0.906, green: 0.757, blue: 0.471, alpha: 1.0)

    // MARK: - Block Cell Overlay

    /// Border overlay used on block cells (black outline for folk-art style)
    static let blockCellOverlay = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3)

    // MARK: - Scene Colors

    /// Scene background (transparent to let SwiftUI background show through)
    static let sceneBackground = UIColor.clear
}
