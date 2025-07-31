import SwiftUI

extension GameTheme {
    struct Colors {
        // MARK: - Private Base Colors (Unique Colors)
        
        // Browns & Earth Tones
        private static let darkChocolate = Color(red: 0.1, green: 0.05, blue: 0.02)
        private static let mediumBrown = Color(red: 0.2, green: 0.15, blue: 0.1)
        private static let lightBrown = Color(red: 0.15, green: 0.1, blue: 0.05)
        private static let warmBrown = Color(red: 0.12, green: 0.08, blue: 0.04)
        private static let rustBrown = Color(red: 0.4, green: 0.25, blue: 0.1)
        private static let caramel = Color(red: 0.6, green: 0.4, blue: 0.2)
        private static let darkShadow = Color(red: 0.3, green: 0.2, blue: 0.1)
        private static let deepShadow = Color(red: 0.3, green: 0.1, blue: 0.05)
        
        // Creams & Light Tones
        private static let cream = Color(red: 0.95, green: 0.9, blue: 0.8)
        private static let lightCream = Color(red: 0.9, green: 0.8, blue: 0.7)
        private static let tan = Color(red: 0.7, green: 0.5, blue: 0.3)
        private static let brightAmber = Color(red: 0.8, green: 0.5, blue: 0.2)
        
        // Vibrant Colors
        private static let goldenAmber = Color(red: 0.9, green: 0.7, blue: 0.1)
        private static let burntOrange = Color(red: 0.9, green: 0.5, blue: 0.1)
        private static let deepOrange = Color(red: 0.8, green: 0.4, blue: 0.1)
        private static let crimsonRed = Color(red: 0.8, green: 0.2, blue: 0.1)
        private static let forestGreen = Color(red: 0.3, green: 0.6, blue: 0.2)
        private static let skyBlue = Color(red: 0.4, green: 0.6, blue: 0.8)
        private static let plumPurple = Color(red: 0.5, green: 0.3, blue: 0.4)
        private static let rosePink = Color(red: 0.8, green: 0.4, blue: 0.3)
        private static let brightYellow = Color.yellow.opacity(0.9)
        
        // Greens
        private static let darkGreen = Color(red: 0.15, green: 0.6, blue: 0.05)
        private static let mediumGreen = Color(red: 0.25, green: 0.7, blue: 0.15)
        private static let lightGreen = Color(red: 0.2, green: 0.65, blue: 0.1)
        
        // Game Effects
        private static let brightGold = Color(red: 1.0, green: 0.8, blue: 0.0)
        private static let mediumGold = Color(red: 1.0, green: 0.6, blue: 0.0)
        private static let lightGold = Color(red: 1.0, green: 0.9, blue: 0.2)
        
        // MARK: - Public Semantic Color Aliases
        
        // Background Colors
        static let primaryBackground = darkChocolate
        static let secondaryBackground = mediumBrown
        static let tertiaryBackground = lightBrown
        
        // Accent Colors
        static let primaryAccent = goldenAmber
        static let secondaryAccent = burntOrange
        static let tertiaryAccent = deepOrange
        static let accent = brightYellow
        
        // Text Colors
        static let primaryText = cream
        static let secondaryText = lightCream
        static let tertiaryText = tan
        
        // Game Elements
        static let gridBackground = lightBrown
        static let gridBorder = rustBrown
        static let blockBackground = mediumBrown
        
        // Status Colors
        static let success = forestGreen
        static let warning = goldenAmber
        static let error = crimsonRed
        
        // Block Colors
        static let blockBlue = skyBlue
        static let blockGreen = forestGreen
        static let blockRed = crimsonRed
        static let blockYellow = goldenAmber
        static let blockPurple = plumPurple
        static let blockOrange = burntOrange
        static let blockPink = rosePink
        
        // Background Gradients
        static let backgroundGradient = [
            darkChocolate,
            mediumBrown,
            lightBrown
        ]
        
        // Overlay Colors
        static let overlayPrimary = rustBrown.opacity(0.1)
        static let overlaySecondary = caramel.opacity(0.05)
        
        // Card/Container Colors
        static let cardBackground = lightBrown.opacity(0.9)
        static let cardBorderGradient = [
            caramel.opacity(0.4),
            rustBrown.opacity(0.6),
            brightAmber.opacity(0.3)
        ]
        static let cardShadow = darkShadow.opacity(0.4)
        
        // Block Container Colors
        static let blockContainerBackground = mediumBrown.opacity(0.6)
        static let blockContainerBorder = caramel.opacity(0.3)
        static let blockContainerShadow = darkChocolate.opacity(0.4)
        
        // General Container Colors
        static let containerBackground = warmBrown.opacity(0.7)
        static let containerBorder = rustBrown.opacity(0.2)
        static let containerShadow = darkChocolate.opacity(0.3)
        
        // Overlay/Modal Colors
        static let overlayBackground = lightBrown.opacity(0.95)
        static let overlayBorderGradient = [
            crimsonRed.opacity(0.6),
            burntOrange.opacity(0.4)
        ]
        static let overlayDeepShadow = deepShadow.opacity(0.6)
        
        // Button Colors
        static let buttonText = darkChocolate
        static let buttonGradient = [
            goldenAmber,
            burntOrange
        ]
        
        // Grass Colors
        static let grassPrimary = darkGreen
        static let grassSecondary = mediumGreen
        static let grassTertiary = lightGreen
        
        // Game Effect Colors
        static let lineCompletionPrimary = brightGold
        static let lineCompletionSecondary = mediumGold
        static let lineCompletionAccent = lightGold
    }
}
