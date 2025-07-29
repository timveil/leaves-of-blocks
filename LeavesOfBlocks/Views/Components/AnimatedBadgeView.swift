import SwiftUI

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