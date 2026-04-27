import SwiftUI

extension GameTheme {
    struct Layout {
        static let cellSize: CGFloat = 40
        static let gridSpacing: CGFloat = 4
        static let gridPadding: CGFloat = 12
        static let sectionSpacing: CGFloat = 24
        static let componentSpacing: CGFloat = 16
        static let blockSpacing: CGFloat = 40
        
        // Padding
        static let tinyPadding: CGFloat = 4
        static let smallPadding: CGFloat = 8
        static let mediumPadding: CGFloat = 16
        static let largePadding: CGFloat = 24
        static let extraLargePadding: CGFloat = 32
        
        // Spacing
        static let tinySpacing: CGFloat = 2
        static let smallSpacing: CGFloat = 4
        static let mediumSpacing: CGFloat = 8
        static let largeSpacing: CGFloat = 16
        static let extraLargeSpacing: CGFloat = 24
        
        // Corner Radius
        static let smallRadius: CGFloat = 8
        static let mediumRadius: CGFloat = 16
        static let largeRadius: CGFloat = 24
        static let extraLargeRadius: CGFloat = 28
        static let cardCornerRadius: CGFloat = 24
        static let buttonCornerRadius: CGFloat = 16
        static let overlayCornerRadius: CGFloat = 28
        
        // Stroke
        static let strokeWidth: CGFloat = 3
        
        // Shadows
        static let shadowRadius: CGFloat = 12
        static let shadowOffset: CGFloat = 6
        static let shadowOffsetSize = CGSize(width: 0, height: 6)
        
        // Cell Styling
        static let cellCornerRadius: CGFloat = 3

        // Special Block Styling
        static let specialBlockCornerRadius: CGFloat = 6
        static let specialBlockIconScale: CGFloat = 0.5
        
        // Opacity Constants for UI Elements
        static let lowOpacity: Double = 0.2
        static let mediumLowOpacity: Double = 0.3
        static let mediumOpacity: Double = 0.4
        static let mediumHighOpacity: Double = 0.6
        static let highOpacity: Double = 0.8
        static let veryHighOpacity: Double = 0.9
        
        // Scale Effects
        static let subtleScale: Double = 1.02
        static let minorScale: Double = 0.95
        static let reducedScale: Double = 0.88
        static let slightlyReducedScale: Double = 0.98
    }
}