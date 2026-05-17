import SwiftUI

// MARK: - Game Theme System

/// Visual theming root. Pure styling — no gameplay rules live here.
/// Rule constants (grid size, scoring) live in `AppConfiguration.GameRules`
/// so `GameLogic` doesn't depend on the theme layer.
struct GameTheme {}

// MARK: - Gradient Extensions

extension GameTheme {

    struct Gradients {
        static let background = LinearGradient(
            colors: [Colors.primaryBackground, Colors.secondaryBackground, Colors.tertiaryBackground],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

    }
}
