import SwiftUI

extension GameTheme {
    struct Typography {
        // MARK: - Typography System
        //
        // Fonts use SwiftUI text styles so they scale with the user's
        // Dynamic Type setting. Where a heavier weight or serif design
        // is needed, we apply it via system(_:design:) + .weight(_:).

        /// Display text for prominent numbers and titles. Scales with Dynamic Type.
        /// Use for: game scores, game-over text, large numbers
        static let display = Font.system(.largeTitle, design: .serif).weight(.bold)

        /// Title text for screen and section headers. Scales with Dynamic Type.
        /// Use for: screen titles, major section headers
        static let title = Font.system(.title, design: .serif).weight(.bold)

        /// Headline text for sub-headers and important labels. Scales with Dynamic Type.
        /// Use for: card headers, section sub-titles, prominent labels
        static let headline = Font.system(.title3, design: .serif).weight(.semibold)

        /// Body text for main content. Scales with Dynamic Type.
        /// Use for: general text, button labels, descriptions
        static let body = Font.system(.body, design: .serif).weight(.medium)

        /// Caption text for secondary information. Scales with Dynamic Type.
        /// Use for: small labels, hints, secondary details
        static let caption = Font.system(.subheadline, design: .serif).weight(.medium)
    }
}
