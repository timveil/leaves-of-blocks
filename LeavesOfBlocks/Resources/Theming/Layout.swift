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
        /// Halfway between `smallSpacing` and `mediumSpacing`; used by
        /// How-To-Play row content and similar tight vertical stacks.
        static let tightSpacing: CGFloat = 6
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
        /// Inset applied when rendering special-block tiles inside a cell
        /// (cellSize minus this on each axis) so the colored fill doesn't
        /// touch the cell border.
        static let specialBlockInset: CGFloat = 2

        // Home Screen
        /// Visual height of the three acorn icons in the difficulty selector.
        static let acornIconHeight: CGFloat = 60
        /// Height of the custom AcornSlider control.
        static let sliderHeight: CGFloat = 36
        /// Height of the slider's track shape (filled + unfilled).
        static let sliderTrackHeight: CGFloat = 8
        /// Horizontal padding applied to the slider's tick-mark row so the
        /// first/last ticks align with the thumb travel.
        static let sliderTickPadding: CGFloat = 15

        // About / Settings Screens
        /// Width and height of the Whitman portrait next to a quote.
        static let whitmanPortraitSize: CGFloat = 88

        // Opacity
        static let mediumLowOpacity: Double = 0.3
    }
}
