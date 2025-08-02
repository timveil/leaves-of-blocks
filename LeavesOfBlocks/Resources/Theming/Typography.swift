import SwiftUI

extension GameTheme {
    struct Typography {
        // MARK: - Simplified Typography System
        
        /// Display text for large, prominent numbers and titles (48pt, bold)
        /// Use for: game scores, game over text, large numbers
        static let display = Font.system(size: 48, weight: .bold, design: .default)
        
        /// Title text for screen and section headers (28pt, bold)
        /// Use for: screen titles, major section headers
        static let title = Font.system(size: 28, weight: .bold, design: .default)
        
        /// Headline text for sub-headers and important labels (20pt, semibold)
        /// Use for: card headers, section sub-titles, prominent labels
        static let headline = Font.system(size: 20, weight: .semibold, design: .default)
        
        /// Body text for main content (16pt, medium)
        /// Use for: general text, button labels, descriptions
        static let body = Font.system(size: 16, weight: .medium, design: .default)
        
        /// Caption text for secondary information (13pt, medium)
        /// Use for: small labels, hints, secondary details
        static let caption = Font.system(size: 13, weight: .medium, design: .default)
        
        /// Tiny text for minimal UI elements (10pt, medium)
        /// Use for: timestamps, small badges, tertiary information
        static let tiny = Font.system(size: 10, weight: .medium, design: .default)
        
        /// Serif text for decorative quotes (18pt, regular, serif)
        /// Use for: quotes in about screen, decorative text
        static let serif = Font.system(size: 18, weight: .regular, design: .serif)
        
        // MARK: - Dynamic Font Helper (for special cases only)
        
        /// Creates a dynamic font for special cases that need custom sizing
        /// Avoid using this unless absolutely necessary (e.g., dynamic icon sizing)
        static func dynamic(size: CGFloat, weight: Font.Weight = .medium) -> Font {
            Font.system(size: size, weight: weight, design: .default)
        }
        
    }
}
