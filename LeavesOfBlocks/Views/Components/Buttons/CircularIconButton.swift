import SwiftUI

/// A circular button with an SF Symbol icon and a colored background.
///
/// Used for primary in-game actions (start, save, exit, view summary). The
/// styling matches the folk-art aesthetic: filled circle, black stroke, white
/// glyph.
struct CircularIconButton: View {
    let icon: String
    let accessibilityLabel: String
    let color: Color
    let size: CGFloat
    let iconSize: CGFloat
    let action: () -> Void

    init(
        icon: String,
        accessibilityLabel: String,
        color: Color,
        size: CGFloat = 64,
        iconSize: CGFloat = 28,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.accessibilityLabel = accessibilityLabel
        self.color = color
        self.size = size
        self.iconSize = iconSize
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticFeedback.tap()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: iconSize))
                .foregroundColor(GameTheme.Colors.buttonText)
                .frame(width: size, height: size)
                .background(Circle().fill(color))
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: GameTheme.Layout.cardBorderWidth)
                )
        }
        .buttonStyle(.pressDarken)
        .accessibilityLabel(accessibilityLabel)
    }
}

#Preview {
    HStack(spacing: 24) {
        CircularIconButton(
            icon: "play.fill",
            accessibilityLabel: "new_game".localized,
            color: GameTheme.Colors.success,
            action: {}
        )
        CircularIconButton(
            icon: "list.bullet",
            accessibilityLabel: "view_summary".localized,
            color: GameTheme.Colors.accent,
            action: {}
        )
        CircularIconButton(
            icon: "play.fill",
            accessibilityLabel: "new_game".localized,
            color: GameTheme.Colors.success,
            size: 72,
            iconSize: 32,
            action: {}
        )
    }
    .padding()
}
