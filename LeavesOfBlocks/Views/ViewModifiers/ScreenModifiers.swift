import SwiftUI

// MARK: - Game Screen Modifiers

extension View {

    // MARK: - Card Style Modifiers

    /// Applies the standard folk-art card border: clipped rounded rectangle with black stroke
    func folkArtCard(
        cornerRadius: CGFloat = GameTheme.Layout.cardCornerRadius,
        borderColor: Color = .black,
        borderWidth: CGFloat = GameTheme.Layout.cardBorderWidth
    ) -> some View {
        self
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }

    // MARK: - Typography Modifiers

    /// Applies section header text styling
    func sectionHeaderStyle(color: Color = GameTheme.Colors.primaryText) -> some View {
        self
            .font(GameTheme.Typography.headline)
            .foregroundColor(color)
    }

    /// Applies body text styling
    func sectionTextStyle(color: Color = GameTheme.Colors.primaryText) -> some View {
        self
            .font(GameTheme.Typography.body)
            .foregroundColor(color)
    }

    /// Applies caption text styling
    func gameCaptionStyle(color: Color = GameTheme.Colors.secondaryText) -> some View {
        self
            .font(GameTheme.Typography.caption)
            .foregroundColor(color)
    }

    // MARK: - Badge and Chip Modifiers

    /// Applies capsule badge styling for stat chips and indicators
    func gameBadgeStyle(
        backgroundColor: Color = GameTheme.Colors.accent.opacity(0.2),
        borderColor: Color = GameTheme.Colors.accent,
        borderWidth: CGFloat = 1
    ) -> some View {
        self
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(backgroundColor)
                    .overlay(
                        Capsule()
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
            )
    }

    /// Applies a vertical fade-out mask to the bottom 160pt of a scrolling view.
    func scrollFadeMask(height: CGFloat = 160) -> some View {
        self.mask(
            VStack(spacing: 0) {
                Color.black
                LinearGradient(
                    colors: [.black, .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: height)
            }
        )
    }

    /// Applies table header styling with gold background and black border
    func gameTableHeaderStyle(
        backgroundColor: Color = GameTheme.Colors.accent,
        borderColor: Color = Color.black
    ) -> some View {
        self
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: GameTheme.Layout.cardCornerRadius,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: GameTheme.Layout.cardCornerRadius
                )
                .fill(backgroundColor)
            )
            .overlay(
                Rectangle()
                    .frame(height: GameTheme.Layout.dividerHeight)
                    .foregroundColor(borderColor),
                alignment: .bottom
            )
    }
}
