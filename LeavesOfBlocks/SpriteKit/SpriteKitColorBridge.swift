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
    ///
    /// Maps each `BlockColor` to its autumn-themed `UIColor` equivalent,
    /// matching the SwiftUI colors defined in `BlockModels+Extensions.swift`.
    ///
    /// - Parameter blockColor: The `BlockColor` to convert
    /// - Returns: The corresponding `UIColor`
    static func blockColor(for blockColor: BlockColor) -> UIColor {
        switch blockColor {
        case .blue:   return UIColor(red: 0.4, green: 0.6, blue: 0.8, alpha: 1.0)
        case .green:  return UIColor(red: 0.3, green: 0.6, blue: 0.2, alpha: 1.0)
        case .red:    return UIColor(red: 0.8, green: 0.2, blue: 0.1, alpha: 1.0)
        case .yellow: return UIColor(red: 0.9, green: 0.7, blue: 0.1, alpha: 1.0)
        case .purple: return UIColor(red: 0.5, green: 0.3, blue: 0.4, alpha: 1.0)
        case .orange: return UIColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1.0)
        case .pink:   return UIColor(red: 0.8, green: 0.4, blue: 0.3, alpha: 1.0)
        }
    }

    // MARK: - Grid Colors

    /// Empty grid cell background color
    static let gridCellEmpty = UIColor(red: 0.2, green: 0.15, blue: 0.1, alpha: 0.3)

    /// Empty grid cell border color
    static let gridCellBorder = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 0.2)

    /// Filled grid cell border color
    static let gridCellFilledBorder = UIColor(red: 0.95, green: 0.9, blue: 0.8, alpha: 0.4)

    /// Grid card background color
    static let cardBackground = UIColor(red: 0.15, green: 0.1, blue: 0.05, alpha: 0.9)

    /// Card border color
    static let cardBorder = UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 0.4)

    // MARK: - Preview Colors

    /// Line completion highlight color (golden)
    static let lineCompletionPrimary = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)

    /// Line completion accent color
    static let lineCompletionAccent = UIColor(red: 1.0, green: 0.9, blue: 0.2, alpha: 1.0)

    // MARK: - Block Cell Overlay

    /// Cream overlay used on block cell borders
    static let blockCellOverlay = UIColor(red: 0.95, green: 0.9, blue: 0.8, alpha: 0.5)

    // MARK: - Scene Colors

    /// Scene background (transparent to let SwiftUI background show through)
    static let sceneBackground = UIColor.clear
}
