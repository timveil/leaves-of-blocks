import SwiftUI

extension GameTheme {
    struct Layout {
        // Grid sizing (canonical values for the game grid)
        static let cellSize: CGFloat = 40
        static let gridSpacing: CGFloat = 4
        static let gridPadding: CGFloat = 12
        static let sectionSpacing: CGFloat = 24

        // Padding
        static let smallPadding: CGFloat = 8
        static let mediumPadding: CGFloat = 16
        static let largePadding: CGFloat = 24
        static let extraLargePadding: CGFloat = 32

        // Spacing
        static let smallSpacing: CGFloat = 4
        static let mediumSpacing: CGFloat = 8
        static let extraLargeSpacing: CGFloat = 24

        // Corner Radius
        static let mediumRadius: CGFloat = 10
        static let cardCornerRadius: CGFloat = 12
        static let buttonCornerRadius: CGFloat = 10

        // Stroke and Borders
        static let cardBorderWidth: CGFloat = 2.5
        static let dividerHeight: CGFloat = 2.5

        // Cell Styling
        static let cellCornerRadius: CGFloat = 3
        static let gridLineWidth: CGFloat = 2
        static let gridBorderWidth: CGFloat = 3

        // Special Block Styling
        static let specialBlockCornerRadius: CGFloat = 6
        static let specialBlockIconScale: CGFloat = 0.5

        // Opacity
        static let mediumLowOpacity: Double = 0.3
    }
}
