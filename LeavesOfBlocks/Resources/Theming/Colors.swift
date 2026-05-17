import SwiftUI

extension GameTheme {
    struct Colors {
        // MARK: - Paper Palette (Warm Cream Backgrounds)

        private static let paper50 = Color(red: 0.984, green: 0.965, blue: 0.925)
        private static let paper100 = Color(red: 0.961, green: 0.929, blue: 0.871)
        private static let paper200 = Color(red: 0.929, green: 0.890, blue: 0.812)
        private static let paper300 = Color(red: 0.867, green: 0.824, blue: 0.737)

        // MARK: - Ink Palette (Deep Slate Text)

        private static let ink200 = Color(red: 0.706, green: 0.737, blue: 0.792)
        private static let ink300 = Color(red: 0.545, green: 0.588, blue: 0.655)
        private static let ink500 = Color(red: 0.357, green: 0.396, blue: 0.451)
        private static let ink600 = Color(red: 0.227, green: 0.267, blue: 0.333)
        private static let ink800 = Color(red: 0.122, green: 0.157, blue: 0.216)

        // MARK: - Leaf Palette (Fresh Green)

        private static let leaf500 = Color(red: 0.133, green: 0.612, blue: 0.251)
        private static let leaf600 = Color(red: 0.239, green: 0.541, blue: 0.310)
        private static let leaf700 = Color(red: 0.114, green: 0.427, blue: 0.184)
        private static let leaf800 = Color(red: 0.082, green: 0.322, blue: 0.133)

        // MARK: - Sun Palette (Warm Saffron/Gold)

        private static let sun300 = Color(red: 0.906, green: 0.757, blue: 0.471)
        private static let sun400 = Color(red: 0.859, green: 0.678, blue: 0.341)
        private static let sun500 = Color(red: 0.804, green: 0.600, blue: 0.239)
        private static let sun600 = Color(red: 0.671, green: 0.494, blue: 0.169)

        // MARK: - Poppy Palette (Tomato/Energy Accent)

        private static let poppy500 = Color(red: 0.776, green: 0.384, blue: 0.251)

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
        /// Lighter gold reserved for header bands paired with dark text — gives
        /// the band the contrast needed against `Colors.primaryText`.
        static let headerBand = sun300

        // Text Colors
        static let primaryText = ink800
        static let secondaryText = ink500
        static let tertiaryText = ink300

        // Game Elements
        static let gridBorder = ink200
        static let blockBackground = paper300

        // Status Colors
        static let success = leaf500
        static let error = poppy500

        // Block Colors (drawn from the folk-art background illustration)
        static let blockBlue = Color(red: 0.082, green: 0.459, blue: 0.443)
        static let blockGreen = leaf600
        static let blockRed = Color(red: 0.753, green: 0.224, blue: 0.169)
        static let blockYellow = sun500
        static let blockPurple = Color(red: 0.384, green: 0.216, blue: 0.188)
        static let blockOrange = Color(red: 0.906, green: 0.530, blue: 0.200)
        static let blockPink = Color(red: 0.886, green: 0.561, blue: 0.388)

        // Card / Container Colors
        static let cardBackground = Color.white
        static let cardShadow = ink600.opacity(0.08)
        static let containerBackground = paper100.opacity(0.7)

        // Buttons
        static let buttonText = Color.white

        // Folk-art outlines (hairline borders, slider strokes, divider lines)
        /// Pure-black accent used for thin outline strokes (slider track and
        /// thumb, tick marks). Distinct from `primaryText` so it can be
        /// retuned without dragging body-text color with it.
        static let outline = Color.black

        // Game Effect Colors
        static let lineCompletionPrimary = sun400
        static let lineCompletionSecondary = sun500
        static let lineCompletionAccent = sun300
        static let gameOverDesaturation = Color(red: 0.835, green: 0.855, blue: 0.894)
        static let effectBorder = ink600
    }
}
