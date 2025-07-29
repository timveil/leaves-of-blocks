import SwiftUI

// MARK: - Specialized Game Button Components

/// A unified difficulty selection button component
struct GameDifficultyButton: View {
    let difficulty: DifficultyMode
    let isSelected: Bool
    let isCompact: Bool
    let onTap: () -> Void
    
    init(
        difficulty: DifficultyMode,
        isSelected: Bool,
        isCompact: Bool = false,
        onTap: @escaping () -> Void
    ) {
        self.difficulty = difficulty
        self.isSelected = isSelected
        self.isCompact = isCompact
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: GameTheme.Layout.mediumSpacing) {
                // Icon
                Image(systemName: difficulty.icon)
                    .font(.system(size: isCompact ? 16 : 20, weight: .semibold))
                    .foregroundColor(isSelected ? difficulty.color : GameTheme.Colors.secondaryText)
                
                if !isCompact {
                    VStack(alignment: .leading, spacing: 4) {
                        // Title
                        Text(difficulty.rawValue)
                            .font(GameTheme.Typography.headlineFont)
                            .foregroundColor(isSelected ? GameTheme.Colors.primaryText : GameTheme.Colors.secondaryText)
                        
                        // Description
                        Text(difficulty.description)
                            .font(GameTheme.Typography.captionFont)
                            .foregroundColor(GameTheme.Colors.secondaryText)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                }
            }
            .padding(isCompact ? GameTheme.Layout.mediumPadding : GameTheme.Layout.largePadding)
            .gameButtonCardStyle(
                isSelected: isSelected,
                selectedColor: difficulty.color
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// A unified start game button component with gradient styling
struct StartGameButton: View {
    let difficulty: DifficultyMode
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: GameTheme.Layout.mediumSpacing) {
                Image(systemName: "play.fill")
                    .font(.system(size: 20, weight: .bold))
                
                Text("Start Game")
                    .font(GameTheme.Typography.buttonFont)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, GameTheme.Layout.extraLargePadding)
            .padding(.vertical, GameTheme.Layout.largePadding)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                difficulty.color,
                                difficulty.color.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.5),
                                        difficulty.color.opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: difficulty.color.opacity(0.3), radius: 12, x: 0, y: 8)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: UUID())
    }
}

/// A unified action button component for game actions
struct GameActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let style: ActionButtonStyle
    let onTap: () -> Void
    
    enum ActionButtonStyle {
        case primary
        case secondary
        case danger
        
        var backgroundColor: Color {
            switch self {
            case .primary: return GameTheme.Colors.accent
            case .secondary: return GameTheme.Colors.containerBackground
            case .danger: return GameTheme.Colors.error
            }
        }
        
        var textColor: Color {
            switch self {
            case .primary, .danger: return .white
            case .secondary: return GameTheme.Colors.primaryText
            }
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: GameTheme.Layout.smallSpacing) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(title)
                    .font(GameTheme.Typography.bodyFont)
                    .fontWeight(.medium)
            }
            .foregroundColor(style.textColor)
            .padding(.horizontal, GameTheme.Layout.largePadding)
            .padding(.vertical, GameTheme.Layout.mediumPadding)
            .background(
                RoundedRectangle(cornerRadius: GameTheme.Layout.buttonCornerRadius)
                    .fill(style.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: GameTheme.Layout.buttonCornerRadius)
                            .stroke(
                                style == .secondary ? GameTheme.Colors.gridBorder : Color.clear,
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: style.backgroundColor.opacity(0.3),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

