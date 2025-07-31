import SwiftUI

extension GameTheme {
    struct Typography {
        // MARK: - Private Base Fonts (Unique Fonts)
        
        // Large Display Fonts
        private static let extraLargeDisplay = Font.system(size: 48, weight: .bold, design: .default)
        private static let largeDisplay = Font.system(size: 32, weight: .semibold, design: .default)
        private static let mediumDisplay = Font.system(size: 28, weight: .bold, design: .default)
        private static let regularDisplay = Font.system(size: 26, weight: .bold, design: .default)
        
        // Header Fonts
        private static let primaryHeader = Font.system(size: 22, weight: .bold, design: .default)
        private static let secondaryHeader = Font.system(size: 20, weight: .bold, design: .default)
        
        // Body Fonts
        private static let primaryBody = Font.system(size: 18, weight: .medium, design: .default)
        private static let standardBody = Font.system(size: 16, weight: .medium, design: .default)
        private static let compactBody = Font.system(size: 13, weight: .semibold, design: .default)
        private static let smallBody = Font.system(size: 12, weight: .medium, design: .default)
        
        // System Fonts
        private static let systemTitle2 = Font.title2
        
        // MARK: - Public Semantic Font Aliases
        
        // Display & Title Fonts
        static let title = largeDisplay
        static let titleFont = mediumDisplay
        
        // Header Fonts
        static let sectionHeaderFont = primaryHeader
        static let headlineFont = secondaryHeader
        static let headline = systemTitle2
        
        // Body & Text Fonts
        static let sectionTextFont = primaryBody
        static let body = standardBody
        static let bodyFont = standardBody
        static let caption = standardBody
        static let captionFont = compactBody
        static let subtitleFont = smallBody
        
        // Button Fonts
        static let buttonFont = mediumDisplay
        
        // Score Fonts
        static let scoreFont = regularDisplay
        static let largeScore = extraLargeDisplay
        static let finalScoreFont = extraLargeDisplay
    }
}
