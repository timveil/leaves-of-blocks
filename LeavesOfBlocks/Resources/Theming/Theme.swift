import SwiftUI

// MARK: - Game Theme System

struct GameTheme {

    // MARK: - Game Configuration

    struct GameConfig {
        static let gridSize: Int = 8
        static let baseBlockScore: Int = 10
        static let lineScore: Int = 100
        static let comboBonus: Int = 50
        static let horizontalDriftRange: ClosedRange<Double> = -30...30

        // Animation timing
        static let lineClearDelay: Double = 0.05
        static let blockFadeOutDuration: Double = 0.2
    }
}

// MARK: - Gradient Extensions

extension GameTheme {

    struct Gradients {
        static let background = LinearGradient(
            colors: [Colors.primaryBackground, Colors.secondaryBackground, Colors.tertiaryBackground],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let accent = LinearGradient(
            colors: [Colors.primaryAccent, Colors.secondaryAccent, Colors.tertiaryAccent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let text = LinearGradient(
            colors: [Colors.primaryText, Colors.secondaryText],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let button = LinearGradient(
            colors: [Colors.primaryAccent, Colors.secondaryAccent],
            startPoint: .leading,
            endPoint: .trailing
        )

        static let overlay = RadialGradient(
            colors: [
                Colors.primaryAccent.opacity(0.06),
                Color.clear,
                Colors.accent.opacity(0.03)
            ],
            center: .topTrailing,
            startRadius: 50,
            endRadius: 400
        )

        // MARK: - Card & UI Gradients

        static let cardBorder = LinearGradient(
            colors: [Colors.gridBorder.opacity(0.25), Colors.gridBorder.opacity(0.10)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let verticalFade = LinearGradient(
            colors: [Color.clear, Color.clear],
            startPoint: .top,
            endPoint: .bottom
        )

        // MARK: - Combo Effect Gradients

        static let comboLow = LinearGradient(
            colors: [Colors.primaryAccent, Colors.primaryAccent.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let comboMedium = LinearGradient(
            colors: [Colors.secondaryAccent, Colors.secondaryAccent.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let comboHigh = LinearGradient(
            colors: [Colors.lineCompletionPrimary, Colors.lineCompletionSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // MARK: - Helper Methods

        static func blockVisual(from startColor: Color, to endColor: Color) -> LinearGradient {
            LinearGradient(
                colors: [startColor, endColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static func verticalFade(from startColor: Color, to endColor: Color) -> LinearGradient {
            LinearGradient(
                colors: [startColor, endColor],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        static func horizontalProgress(from startColor: Color, to endColor: Color) -> LinearGradient {
            LinearGradient(
                colors: [startColor, endColor],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}
