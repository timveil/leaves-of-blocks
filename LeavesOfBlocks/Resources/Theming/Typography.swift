import SwiftUI

extension GameTheme {
    struct Typography {
        static let title = Font.system(size: 32, weight: .semibold, design: .default)
        static let titleFont = Font.system(size: 28, weight: .bold, design: .default)
        
        static let sectionHeaderFont = Font.system(size: 22, weight: .bold, design: .default)
        
        static let sectionTextFont = Font.system(size: 18, weight: .medium, design: .default)
        
        
        static let buttonFont = Font.system(size: 28, weight: .bold, design: .default)
        static let subtitleFont = Font.system(size: 12, weight: .medium, design: .default)
        static let headline = Font.title2
        static let headlineFont = Font.system(size: 20, weight: .bold, design: .default)
        static let body = Font.system(size: 16, weight: .medium, design: .default)
        static let bodyFont = Font.system(size: 16, weight: .medium, design: .default)
        static let caption = Font.system(size: 16, weight: .medium, design: .default)
        static let captionFont = Font.system(size: 13, weight: .semibold, design: .default)
        static let scoreFont = Font.system(size: 26, weight: .bold, design: .default)
        static let largeScore = Font.system(size: 48, weight: .bold, design: .default)
        static let finalScoreFont = Font.system(size: 48, weight: .bold, design: .default)
    }
}
