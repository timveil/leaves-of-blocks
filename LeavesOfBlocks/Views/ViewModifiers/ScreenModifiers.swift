import SwiftUI

// MARK: - Game Screen Modifiers

extension View {
    
    // MARK: - Navigation Modifiers
    
    /// Applies standard game screen navigation settings
    func gameScreenNavigation() -> some View {
        self
            .toolbar(.hidden, for: .navigationBar)
            .ignoresSafeArea(.container, edges: [])
    }
    
    /// Applies navigation animation with spring effect
    func gameNavigationAnimation(action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation(GameTheme.Animations.springAnimation) {
                action()
            }
        }) {
            self
        }
        .buttonStyle(PlainButtonStyle())
    }
    
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
    
    // MARK: - Animation Modifiers
    
    /// Applies standard game transition animation
    func gameTransition() -> some View {
        self
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .scale.combined(with: .opacity)
            ))
            .animation(GameTheme.Animations.springAnimation, value: UUID())
    }
    
    /// Applies pulse animation for highlighting
    func gamePulseAnimation(isPulsing: Bool) -> some View {
        self
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .animation(
                isPulsing ? Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default,
                value: isPulsing
            )
    }
    
    // MARK: - Layout Modifiers
    
    /// Applies standard content padding
    func gameContentPadding(
        horizontal: CGFloat = GameTheme.Layout.largePadding,
        vertical: CGFloat = GameTheme.Layout.largePadding
    ) -> some View {
        self
            .padding(.horizontal, horizontal)
            .padding(.vertical, vertical)
    }
    
    /// Applies standard section spacing
    func gameSectionSpacing() -> some View {
        self
            .padding(.vertical, GameTheme.Layout.sectionSpacing)
    }
    
    // MARK: - Typography Modifiers
    
    /// Applies title text styling
    func pageTitleStyle(color: Color = GameTheme.Colors.primaryText) -> some View {
        self
            .font(GameTheme.Typography.title)
            .foregroundColor(color)
    }
    
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
    
    /// Applies container styling for game components (blocks, grids, etc.)
    func gameContainerStyle(
        backgroundColor: Color = GameTheme.Colors.blockBackground.opacity(0.8),
        cornerRadius: CGFloat = GameTheme.Layout.mediumRadius,
        borderColor: Color = GameTheme.Colors.gridBorder.opacity(0.5),
        borderWidth: CGFloat = 1
    ) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
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

    /// Applies table row styling for middle rows (no rounded corners)
    func gameTableRowStyle(
        backgroundColor: Color = Color.white
    ) -> some View {
        self
            .background(backgroundColor)
    }

    /// Applies table footer styling with bottom rounded corners
    func gameTableFooterStyle(
        backgroundColor: Color = Color.white
    ) -> some View {
        self
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: GameTheme.Layout.cardCornerRadius,
                    bottomTrailingRadius: GameTheme.Layout.cardCornerRadius,
                    topTrailingRadius: 0
                )
                .fill(backgroundColor)
            )
    }
    
    // MARK: - Interaction Modifiers
    
    /// Applies disabled state styling
    func gameDisabledStyle(_ isDisabled: Bool) -> some View {
        self
            .opacity(isDisabled ? 0.5 : 1.0)
            .disabled(isDisabled)
            .animation(.easeInOut(duration: 0.2), value: isDisabled)
    }
}

