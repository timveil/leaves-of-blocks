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
                Color(red: 0.4, green: 0.25, blue: 0.1).opacity(0.1),
                Color.clear,
                Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.05)
            ],
            center: .topTrailing,
            startRadius: 50,
            endRadius: 400
        )
    }
}

// MARK: - View Style Extensions

extension View {
    func gameCardStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: GameTheme.Layout.largeRadius)
                    .fill(GameTheme.Colors.blockBackground.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: GameTheme.Layout.largeRadius)
                            .stroke(GameTheme.Gradients.accent, lineWidth: 2.5)
                    )
                    .shadow(
                        color: GameTheme.Colors.gridBorder.opacity(0.4),
                        radius: GameTheme.Layout.shadowRadius,
                        x: 0,
                        y: GameTheme.Layout.shadowOffset
                    )
            )
    }
    
    func gameButtonStyle() -> some View {
        self
            .background(
                Capsule()
                    .fill(GameTheme.Gradients.button)
            )
            .foregroundColor(GameTheme.Colors.primaryBackground)
            .font(GameTheme.Typography.bodyFont)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
    }
}