import SwiftUI

// MARK: - Reusable UI Components

// MARK: - Score Display Component

struct ScoreDisplayView: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text(icon)
                    .font(.caption)
                Text(title)
                    .font(GameTheme.Typography.captionFont)
                    .foregroundColor(color)
                    .tracking(1.5)
            }
            Text("\(value)")
                .font(GameTheme.Typography.scoreFont)
                .foregroundStyle(GameTheme.Gradients.text)
                .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - Game Card Component

struct GameCardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .gameCardStyle()
    }
}

// MARK: - Animated Badge Component

struct AnimatedBadgeView: View {
    let text: String
    let icon: String
    let value: Int
    let isVisible: Bool
    
    var body: some View {
        if isVisible {
            HStack(spacing: 8) {
                Text(icon)
                    .font(.headline)
                Text(text)
                    .font(GameTheme.Typography.captionFont)
                    .foregroundColor(GameTheme.Colors.success)
                    .tracking(1)
                Text("\(value)")
                    .font(GameTheme.Typography.headlineFont)
                    .foregroundStyle(GameTheme.Gradients.text)
                    .shadow(color: GameTheme.Colors.success.opacity(0.4), radius: 2, x: 0, y: 1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(GameTheme.Colors.blockBackground.opacity(0.6))
                    .overlay(
                        Capsule()
                            .stroke(GameTheme.Colors.success.opacity(0.4), lineWidth: 1.5)
                    )
            )
            .transition(.scale.combined(with: .opacity))
            .animation(
                .spring(
                    response: GameTheme.Animations.springResponse,
                    dampingFraction: GameTheme.Animations.springDamping
                ),
                value: isVisible
            )
        }
    }
}

// MARK: - Styled Button Component

struct GameButtonView: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .tracking(0.5)
        }
        .gameButtonStyle()
        .scaleEffect(1.0)
        .animation(.spring(response: GameTheme.Animations.springResponse), value: title)
    }
}

// MARK: - Loading State Component

struct LoadingStateView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(GameTheme.Colors.primaryAccent)
            
            Text(message)
                .font(GameTheme.Typography.bodyFont)
                .foregroundColor(GameTheme.Colors.secondaryText)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: GameTheme.Layout.mediumRadius)
                .fill(GameTheme.Colors.blockBackground.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: GameTheme.Layout.mediumRadius)
                        .stroke(GameTheme.Colors.gridBorder.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Error State Component

struct ErrorStateView: View {
    let title: String
    let message: String
    let retryAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(GameTheme.Colors.error)
            
            Text(title)
                .font(GameTheme.Typography.headlineFont)
                .foregroundColor(GameTheme.Colors.primaryText)
            
            Text(message)
                .font(GameTheme.Typography.bodyFont)
                .foregroundColor(GameTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            if let retryAction = retryAction {
                GameButtonView(title: "Try Again", action: retryAction)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: GameTheme.Layout.mediumRadius)
                .fill(GameTheme.Colors.blockBackground.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: GameTheme.Layout.mediumRadius)
                        .stroke(GameTheme.Colors.error.opacity(0.3), lineWidth: 2)
                )
        )
    }
}

// MARK: - Grass Block Component

struct GrassBlockView: View {
    let color: Color
    let height: CGFloat
    let width: CGFloat = 12
    
    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(color.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.4), radius: 3, x: 0, y: 2)
    }
}

// MARK: - Preview Helpers

#if DEBUG
struct UIComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ScoreDisplayView(
                title: "Score",
                value: 1250,
                icon: "🎯",
                color: GameTheme.Colors.primaryAccent
            )
            
            AnimatedBadgeView(
                text: "Leaves Cleared:",
                icon: "🍃",
                value: 5,
                isVisible: true
            )
            
            GameButtonView(title: "New Game") { }
            
            ErrorStateView(
                title: "Oops!",
                message: "Something went wrong",
                retryAction: { }
            )
        }
        .padding()
        .background(GameTheme.Colors.primaryBackground)
        .previewLayout(.sizeThatFits)
    }
}
#endif