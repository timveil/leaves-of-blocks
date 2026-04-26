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
        case .blue:   return UIColor(red: 0.278, green: 0.478, blue: 0.729, alpha: 1.0)
        case .green:  return UIColor(red: 0.133, green: 0.612, blue: 0.251, alpha: 1.0)
        case .red:    return UIColor(red: 0.776, green: 0.384, blue: 0.251, alpha: 1.0)
        case .yellow: return UIColor(red: 0.804, green: 0.600, blue: 0.239, alpha: 1.0)
        case .purple: return UIColor(red: 0.412, green: 0.318, blue: 0.580, alpha: 1.0)
        case .orange: return UIColor(red: 0.906, green: 0.530, blue: 0.200, alpha: 1.0)
        case .pink:   return UIColor(red: 0.875, green: 0.592, blue: 0.478, alpha: 1.0)
        }
    }

    // MARK: - Grid Colors

    /// Empty grid cell background color
    static let gridCellEmpty = UIColor(red: 0.929, green: 0.890, blue: 0.812, alpha: 0.4)

    /// Empty grid cell border color
    static let gridCellBorder = UIColor(red: 0.706, green: 0.737, blue: 0.792, alpha: 0.25)

    /// Filled grid cell border color
    static let gridCellFilledBorder = UIColor(red: 0.227, green: 0.267, blue: 0.333, alpha: 0.3)

    /// Grid card background color
    static let cardBackground = UIColor(red: 0.961, green: 0.929, blue: 0.871, alpha: 0.9)

    /// Card border color
    static let cardBorder = UIColor(red: 0.706, green: 0.737, blue: 0.792, alpha: 0.3)

    // MARK: - Preview Colors

    /// Line completion highlight color (warm gold)
    static let lineCompletionPrimary = UIColor(red: 0.859, green: 0.678, blue: 0.341, alpha: 1.0)

    /// Line completion accent color
    static let lineCompletionAccent = UIColor(red: 0.906, green: 0.757, blue: 0.471, alpha: 1.0)

    // MARK: - Block Cell Overlay

    /// Border overlay used on block cells
    static let blockCellOverlay = UIColor(red: 0.227, green: 0.267, blue: 0.333, alpha: 0.25)

    // MARK: - Scene Colors

    /// Scene background (transparent to let SwiftUI background show through)
    static let sceneBackground = UIColor.clear
}
