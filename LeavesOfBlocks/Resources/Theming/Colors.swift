import SwiftUI

extension GameTheme {
    struct Colors {
        // Background Colors
        static let primaryBackground = Color(red: 0.1, green: 0.05, blue: 0.02)
        static let secondaryBackground = Color(red: 0.2, green: 0.15, blue: 0.1)
        static let tertiaryBackground = Color(red: 0.15, green: 0.1, blue: 0.05)
        
        // Accent Colors
        static let primaryAccent = Color(red: 0.9, green: 0.7, blue: 0.1)      // Golden amber
        static let secondaryAccent = Color(red: 0.9, green: 0.5, blue: 0.1)    // Burnt orange
        static let tertiaryAccent = Color(red: 0.8, green: 0.4, blue: 0.1)     // Deep orange
        static let accent = Color.yellow.opacity(0.9)
        
        // Text Colors
        static let primaryText = Color(red: 0.95, green: 0.9, blue: 0.8)       // Cream
        static let secondaryText = Color(red: 0.9, green: 0.8, blue: 0.7)    // Light brown
        static let tertiaryText = Color(red: 0.7, green: 0.5, blue: 0.3)       // Medium brown
        
        // Game Elements
        static let gridBackground = Color(red: 0.15, green: 0.1, blue: 0.05)
        static let gridBorder = Color(red: 0.4, green: 0.25, blue: 0.1)
        static let blockBackground = Color(red: 0.2, green: 0.15, blue: 0.1)
        
        // Status Colors
        static let success = Color(red: 0.3, green: 0.6, blue: 0.2)             // Forest green
        static let warning = Color(red: 0.9, green: 0.7, blue: 0.1)             // Golden amber
        static let error = Color(red: 0.8, green: 0.2, blue: 0.1)               // Deep crimson
        
        // Block colors
        static let blockBlue = Color(red: 0.4, green: 0.6, blue: 0.8)
        static let blockGreen = Color(red: 0.3, green: 0.6, blue: 0.2)
        static let blockRed = Color(red: 0.8, green: 0.2, blue: 0.1)
        static let blockYellow = Color(red: 0.9, green: 0.7, blue: 0.1)
        static let blockPurple = Color(red: 0.5, green: 0.3, blue: 0.4)
        static let blockOrange = Color(red: 0.9, green: 0.5, blue: 0.1)
        static let blockPink = Color(red: 0.8, green: 0.4, blue: 0.3)
        
        // Background gradients
        static let backgroundGradient = [
            Color(red: 0.1, green: 0.05, blue: 0.02),
            Color(red: 0.2, green: 0.15, blue: 0.1),
            Color(red: 0.15, green: 0.1, blue: 0.05)
        ]
        
        // Overlay colors
        static let overlayPrimary = Color(red: 0.4, green: 0.25, blue: 0.1).opacity(0.1)
        static let overlaySecondary = Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.05)
        
        // Card/Container colors
        static let cardBackground = Color(red: 0.15, green: 0.1, blue: 0.05).opacity(0.9)
        static let cardBorderGradient = [
            Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.4),
            Color(red: 0.4, green: 0.25, blue: 0.1).opacity(0.6),
            Color(red: 0.8, green: 0.5, blue: 0.2).opacity(0.3)
        ]
        static let cardShadow = Color(red: 0.3, green: 0.2, blue: 0.1).opacity(0.4)
        
        // Block container colors
        static let blockContainerBackground = Color(red: 0.2, green: 0.15, blue: 0.1).opacity(0.6)
        static let blockContainerBorder = Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.3)
        static let blockContainerShadow = Color(red: 0.1, green: 0.05, blue: 0.02).opacity(0.4)
        
        // General container colors
        static let containerBackground = Color(red: 0.12, green: 0.08, blue: 0.04).opacity(0.7)
        static let containerBorder = Color(red: 0.4, green: 0.25, blue: 0.1).opacity(0.2)
        static let containerShadow = Color(red: 0.1, green: 0.05, blue: 0.02).opacity(0.3)
        
        // Overlay/modal colors
        static let overlayBackground = Color(red: 0.15, green: 0.1, blue: 0.05).opacity(0.95)
        static let overlayBorderGradient = [
            Color(red: 0.8, green: 0.2, blue: 0.1).opacity(0.6),
            Color(red: 0.9, green: 0.5, blue: 0.1).opacity(0.4)
        ]
        static let overlayDeepShadow = Color(red: 0.3, green: 0.1, blue: 0.05).opacity(0.6)
        
        // Button colors
        static let buttonText = Color(red: 0.1, green: 0.05, blue: 0.02)
        static let buttonGradient = [
            Color(red: 0.9, green: 0.7, blue: 0.1),
            Color(red: 0.9, green: 0.5, blue: 0.1)
        ]
        
        // Grass Colors
        static let grassPrimary = Color(red: 0.15, green: 0.6, blue: 0.05)
        static let grassSecondary = Color(red: 0.25, green: 0.7, blue: 0.15)
        static let grassTertiary = Color(red: 0.2, green: 0.65, blue: 0.1)
    }
}
