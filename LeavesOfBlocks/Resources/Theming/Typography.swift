import SwiftUI

extension GameTheme {
    struct Typography {
        // MARK: - Font Definitions (Size-Based)
        
        // Extra Large Fonts (48pt+)
        static let fontXXLarge = Font.system(size: 48, weight: .bold, design: .default)
        
        // Large Fonts (28pt-32pt)
        static let fontXLarge = Font.system(size: 32, weight: .bold, design: .default)
        static let fontLarge = Font.system(size: 28, weight: .bold, design: .default)
        
        // Medium Fonts (20pt-26pt)
        static let fontMediumLarge = Font.system(size: 26, weight: .bold, design: .default)
        static let fontMedium = Font.system(size: 22, weight: .bold, design: .default)
        static let fontMediumSmall = Font.system(size: 20, weight: .bold, design: .default)
        
        // Small Fonts (12pt-18pt)
        static let fontSmallLarge = Font.system(size: 18, weight: .medium, design: .default)
        static let fontSmall = Font.system(size: 16, weight: .medium, design: .default)
        static let fontXSmall = Font.system(size: 13, weight: .medium, design: .default)
        static let fontXXSmall = Font.system(size: 12, weight: .medium, design: .default)
        
    }
}
