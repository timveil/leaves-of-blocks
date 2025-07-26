import SwiftUI

// MARK: - Game Theme System

struct GameTheme {
    
    // MARK: - Color Palette
    
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
        static let secondaryText = Color(red: 0.9, green: 0.8, blue: 0.7).opacity(0.7)      // Light brown
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
    
    // MARK: - Typography
    
    struct Typography {
        static let title = Font.system(size: 32, weight: .semibold, design: .serif)
        static let titleFont = Font.system(size: 28, weight: .bold, design: .serif)
        static let subtitleFont = Font.system(size: 12, weight: .medium, design: .serif)
        static let headline = Font.title2
        static let headlineFont = Font.system(size: 20, weight: .bold, design: .monospaced)
        static let body = Font.system(size: 16, weight: .medium, design: .default)
        static let bodyFont = Font.system(size: 16, weight: .medium, design: .default)
        static let caption = Font.system(size: 16, weight: .medium)
        static let captionFont = Font.system(size: 13, weight: .semibold, design: .serif)
        static let scoreFont = Font.system(size: 26, weight: .bold, design: .monospaced)
        static let largeScore = Font.system(size: 48, weight: .bold, design: .monospaced)
        static let finalScoreFont = Font.system(size: 48, weight: .bold, design: .monospaced)
    }
    
    // MARK: - Spacing & Layout
    
    struct Layout {
        static let cellSize: CGFloat = 40
        static let gridSpacing: CGFloat = 4
        static let gridPadding: CGFloat = 12
        static let sectionSpacing: CGFloat = 24
        static let componentSpacing: CGFloat = 16
        static let blockSpacing: CGFloat = 40
        
        // Padding
        static let tinyPadding: CGFloat = 4
        static let smallPadding: CGFloat = 8
        static let mediumPadding: CGFloat = 16
        static let largePadding: CGFloat = 24
        static let extraLargePadding: CGFloat = 32
        
        // Spacing
        static let tinySpacing: CGFloat = 2
        static let smallSpacing: CGFloat = 4
        static let mediumSpacing: CGFloat = 8
        static let largeSpacing: CGFloat = 16
        static let extraLargeSpacing: CGFloat = 24
        
        // Corner Radius
        static let smallRadius: CGFloat = 8
        static let mediumRadius: CGFloat = 16
        static let largeRadius: CGFloat = 24
        static let extraLargeRadius: CGFloat = 28
        static let cardCornerRadius: CGFloat = 24
        static let buttonCornerRadius: CGFloat = 16
        static let overlayCornerRadius: CGFloat = 28
        
        // Stroke
        static let strokeWidth: CGFloat = 3
        
        // Shadows
        static let shadowRadius: CGFloat = 12
        static let shadowOffset: CGFloat = 6
        static let shadowOffsetSize = CGSize(width: 0, height: 6)
    }
    
    // MARK: - Animations
    
    struct Animations {
        // Faster, more responsive animations
        static let springResponse: Double = 0.15
        static let springDamping: Double = 0.7
        static let fallDuration: Double = 1.0
        static let leafRemovalDelay: Double = 1.2
        static let springAnimation: Animation = .spring(response: 0.15, dampingFraction: 0.7)
        static let leafFallDuration: Double = 1.0
        
        // Line clearing specific animations
        static let lineClearAnimation: Animation = .easeOut(duration: 0.2)
        static let lineHighlightAnimation: Animation = .easeInOut(duration: 0.1)
        static let blockPlaceAnimation: Animation = .spring(response: 0.1, dampingFraction: 0.6)
        
        // Enhanced animations for different effects
        static let fastSpring: Animation = .spring(response: 0.1, dampingFraction: 0.6)
        static let mediumSpring: Animation = .spring(response: 0.15, dampingFraction: 0.7)
        static let smoothEase: Animation = .easeInOut(duration: 0.15)
    }
    
    // MARK: - Game Configuration
    
    struct GameConfig {
        static let gridSize: Int = 8
        static let baseBlockScore: Int = 10
        static let lineScore: Int = 100
        static let comboBonus: Int = 50
        static let leafSizeRange: ClosedRange<CGFloat> = 16...24
        static let fallSpeedRange: ClosedRange<Double> = 100...200
        static let rotationSpeedRange: ClosedRange<Double> = -180...180
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