import SwiftUI

extension GameTheme {
    struct Typography {
        // MARK: - Base Font Definitions
        
        // Large Display Fonts
        static let extraLargeDisplay = Font.system(size: 48, weight: .bold, design: .default)
        static let largeDisplay = Font.system(size: 32, weight: .bold, design: .default)
        static let mediumDisplay = Font.system(size: 28, weight: .bold, design: .default)
        static let regularDisplay = Font.system(size: 26, weight: .bold, design: .default)
        
        // Header Fonts
        static let primaryHeader = Font.system(size: 22, weight: .bold, design: .default)
        static let secondaryHeader = Font.system(size: 20, weight: .bold, design: .default)
        
        // Body Fonts
        static let primaryBody = Font.system(size: 18, weight: .medium, design: .default)
        static let standardBody = Font.system(size: 16, weight: .medium, design: .default)
        static let compactBody = Font.system(size: 13, weight: .medium, design: .default)
        static let smallBody = Font.system(size: 12, weight: .medium, design: .default)
        
    }
}
