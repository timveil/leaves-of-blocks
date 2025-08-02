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
        
        // MARK: - Card & UI Gradients
        
        static let cardBorder = LinearGradient(
            colors: [Colors.accent.opacity(0.3), Colors.accent.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let verticalFade = LinearGradient(
            colors: [Color.clear, Color.clear], // Parameterized - use with custom colors
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
        
        /// Creates a block visual gradient with custom colors
        static func blockVisual(from startColor: Color, to endColor: Color) -> LinearGradient {
            LinearGradient(
                colors: [startColor, endColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        /// Creates a vertical fade gradient with custom colors
        static func verticalFade(from startColor: Color, to endColor: Color) -> LinearGradient {
            LinearGradient(
                colors: [startColor, endColor],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        
        /// Creates a horizontal progress gradient with custom colors
        static func horizontalProgress(from startColor: Color, to endColor: Color) -> LinearGradient {
            LinearGradient(
                colors: [startColor, endColor],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

