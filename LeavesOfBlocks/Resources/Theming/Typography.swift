import SwiftUI

extension GameTheme {
    struct Typography {
        // MARK: - Font Definitions (Size-Based)
        
        // Extra Large Fonts (48pt+)
        static let fontXXLarge = Font.system(size: 48, weight: .bold, design: .default)
        
        // Large Fonts (28pt-32pt)
        static let fontXLarge = Font.system(size: 32, weight: .bold, design: .default)
        static let fontLarge = Font.system(size: 28, weight: .bold, design: .default)
        static let fontLargeSemibold = Font.system(size: 28, weight: .semibold, design: .default)
        
        // Medium Fonts (20pt-26pt)
        static let fontMediumLarge = Font.system(size: 26, weight: .bold, design: .default)
        static let font24Bold = Font.system(size: 24, weight: .bold, design: .rounded)
        static let font24Semibold = Font.system(size: 24, weight: .semibold, design: .default)
        static let fontMedium = Font.system(size: 22, weight: .bold, design: .default)
        static let fontMediumSmall = Font.system(size: 20, weight: .bold, design: .default)
        static let fontMediumSmallSemibold = Font.system(size: 20, weight: .semibold, design: .default)
        static let fontMediumSmallMedium = Font.system(size: 20, weight: .medium, design: .default)
        
        // Small Fonts (12pt-18pt)
        static let fontSmallLarge = Font.system(size: 18, weight: .medium, design: .default)
        static let fontSmallLargeSemibold = Font.system(size: 18, weight: .semibold, design: .default)
        static let fontSmall = Font.system(size: 16, weight: .medium, design: .default)
        static let fontSmallSemibold = Font.system(size: 16, weight: .semibold, design: .default)
        static let font14Medium = Font.system(size: 14, weight: .medium, design: .default)
        static let font14Semibold = Font.system(size: 14, weight: .semibold, design: .default)
        static let fontXSmall = Font.system(size: 13, weight: .medium, design: .default)
        static let fontXXSmall = Font.system(size: 12, weight: .medium, design: .default)
        static let fontXXSmallSemibold = Font.system(size: 12, weight: .semibold, design: .default)
        static let fontXXSmallBold = Font.system(size: 12, weight: .bold, design: .default)
        
        // Tiny Fonts (10pt)
        static let fontTiny = Font.system(size: 10, weight: .medium, design: .default)
        static let fontTinyBold = Font.system(size: 10, weight: .bold, design: .default)
        
        // MARK: - Serif Fonts (for Quotes/Decorative Text)
        
        static let fontSerifMedium = Font.system(size: 18, weight: .medium, design: .serif)
        static let fontSerifRegular = Font.system(size: 18, weight: .regular, design: .serif)
        static let fontSerifSmall = Font.system(size: 14, weight: .medium, design: .serif)
        
        // MARK: - Dynamic Font Helper
        
        /// Creates a dynamic font based on size
        static func dynamicFont(size: CGFloat, weight: Font.Weight = .medium) -> Font {
            Font.system(size: size, weight: weight, design: .default)
        }
        
    }
}
