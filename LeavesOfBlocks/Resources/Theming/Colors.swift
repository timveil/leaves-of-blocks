import SwiftUI

extension GameTheme {
    struct Colors {
        // MARK: - Paper Palette (Warm Cream Backgrounds)

        private static let paper50 = Color(red: 0.984, green: 0.965, blue: 0.925)
        private static let paper100 = Color(red: 0.961, green: 0.929, blue: 0.871)
        private static let paper200 = Color(red: 0.929, green: 0.890, blue: 0.812)
        private static let paper300 = Color(red: 0.867, green: 0.824, blue: 0.737)
        private static let paper400 = Color(red: 0.788, green: 0.741, blue: 0.647)
        private static let paper500 = Color(red: 0.702, green: 0.651, blue: 0.553)

        // MARK: - Ink Palette (Deep Slate Text)

        private static let ink100 = Color(red: 0.835, green: 0.855, blue: 0.894)
        private static let ink200 = Color(red: 0.706, green: 0.737, blue: 0.792)
        private static let ink300 = Color(red: 0.545, green: 0.588, blue: 0.655)
        private static let ink400 = Color(red: 0.396, green: 0.443, blue: 0.518)
        private static let ink500 = Color(red: 0.357, green: 0.396, blue: 0.451)
        private static let ink600 = Color(red: 0.227, green: 0.267, blue: 0.333)
        private static let ink700 = Color(red: 0.165, green: 0.200, blue: 0.267)
        private static let ink800 = Color(red: 0.122, green: 0.157, blue: 0.216)
        private static let ink900 = Color(red: 0.110, green: 0.133, blue: 0.188)

        // MARK: - Leaf Palette (Fresh Green)

        private static let leaf100 = Color(red: 0.784, green: 0.929, blue: 0.812)
        private static let leaf300 = Color(red: 0.345, green: 0.792, blue: 0.435)
        private static let leaf400 = Color(red: 0.196, green: 0.706, blue: 0.329)
        private static let leaf500 = Color(red: 0.133, green: 0.612, blue: 0.251)
        private static let leaf600 = Color(red: 0.239, green: 0.541, blue: 0.310)
        private static let leaf700 = Color(red: 0.114, green: 0.427, blue: 0.184)
        private static let leaf800 = Color(red: 0.082, green: 0.322, blue: 0.133)

        // MARK: - Sun Palette (Warm Saffron/Gold)

        private static let sun200 = Color(red: 0.945, green: 0.839, blue: 0.624)
        private static let sun300 = Color(red: 0.906, green: 0.757, blue: 0.471)
        private static let sun400 = Color(red: 0.859, green: 0.678, blue: 0.341)
        private static let sun500 = Color(red: 0.804, green: 0.600, blue: 0.239)
        private static let sun600 = Color(red: 0.671, green: 0.494, blue: 0.169)

        // MARK: - Poppy Palette (Tomato/Energy Accent)

        private static let poppy300 = Color(red: 0.875, green: 0.592, blue: 0.478)
        private static let poppy400 = Color(red: 0.831, green: 0.486, blue: 0.361)
        private static let poppy500 = Color(red: 0.776, green: 0.384, blue: 0.251)
        private static let poppy600 = Color(red: 0.659, green: 0.306, blue: 0.188)

        // MARK: - Special Colors

        private static let heroTeal = Color(red: 0.016, green: 0.427, blue: 0.420)

        // MARK: - Public Semantic Color Aliases

        // Background Colors
        static let primaryBackground = paper50
        static let secondaryBackground = paper100
        static let tertiaryBackground = paper200

        // Accent Colors
        static let primaryAccent = leaf600
        static let secondaryAccent = leaf700
        static let tertiaryAccent = leaf800
        static let accent = sun600

        // Text Colors
        static let primaryText = ink800
        static let secondaryText = ink500
        static let tertiaryText = ink300

        // Game Elements
        static let gridBackground = paper200
        static let gridBorder = ink200
        static let blockBackground = paper300

        // Status Colors
        static let success = leaf500
        static let warning = sun500
        static let error = poppy500

        // Block Colors (drawn from the folk-art background illustration)
        static let blockBlue = Color(red: 0.082, green: 0.459, blue: 0.443)
        static let blockGreen = leaf600
        static let blockRed = Color(red: 0.753, green: 0.224, blue: 0.169)
        static let blockYellow = sun500
        static let blockPurple = Color(red: 0.384, green: 0.216, blue: 0.188)
        static let blockOrange = Color(red: 0.906, green: 0.530, blue: 0.200)
        static let blockPink = Color(red: 0.886, green: 0.561, blue: 0.388)

        // Background Gradients
        static let backgroundGradient = [
            paper50,
            paper100,
            paper200
        ]

        // Overlay Colors
        static let overlayPrimary = ink200.opacity(0.08)
        static let overlaySecondary = ink100.opacity(0.05)

        // Card/Container Colors
        static let cardBackground = Color.white
        static let cardBorderGradient = [
            ink200.opacity(0.25),
            ink300.opacity(0.15),
            ink200.opacity(0.10)
        ]
        static let cardShadow = ink600.opacity(0.08)

        // Block Container Colors
        static let blockContainerBackground = paper200.opacity(0.6)
        static let blockContainerBorder = ink200.opacity(0.2)
        static let blockContainerShadow = ink600.opacity(0.08)

        // General Container Colors
        static let containerBackground = paper100.opacity(0.7)
        static let containerBorder = ink200.opacity(0.15)
        static let containerShadow = ink600.opacity(0.06)

        // Overlay/Modal Colors
        static let overlayBackground = paper50.opacity(0.95)
        static let overlayBorderGradient = [
            poppy500.opacity(0.3),
            sun500.opacity(0.2)
        ]
        static let overlayDeepShadow = ink700.opacity(0.12)

        // Button Colors
        static let buttonText = Color.white
        static let buttonGradient = [
            leaf500,
            leaf600
        ]

        // Grass Colors
        static let grassPrimary = leaf700
        static let grassSecondary = leaf500
        static let grassTertiary = leaf400

        // Game Effect Colors
        static let lineCompletionPrimary = sun400
        static let lineCompletionSecondary = sun500
        static let lineCompletionAccent = sun300
        static let gameOverDesaturation = ink100
        static let effectBorder = ink600
    }
}
