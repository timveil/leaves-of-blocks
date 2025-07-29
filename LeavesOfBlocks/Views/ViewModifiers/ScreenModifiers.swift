import SwiftUI

// MARK: - Game Screen Modifiers

extension View {
    
    // MARK: - Navigation Modifiers
    
    /// Applies standard game screen navigation settings
    func gameScreenNavigation() -> some View {
        self
            .navigationBarHidden(true)
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
    
    /// Applies standard game card styling with customizable parameters
    func gameCardStyle(
        cornerRadius: CGFloat = GameTheme.Layout.cardCornerRadius,
        borderColor: Color = GameTheme.Colors.gridBorder,
        borderWidth: CGFloat = 1,
        shadowRadius: CGFloat = GameTheme.Layout.shadowRadius,
        shadowOffset: CGFloat = GameTheme.Layout.shadowOffset
    ) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(GameTheme.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                    .shadow(
                        color: GameTheme.Colors.cardShadow,
                        radius: shadowRadius,
                        x: 0,
                        y: shadowOffset
                    )
            )
    }
    
    /// Applies button card styling with conditional selection state
    func gameButtonCardStyle(
        isSelected: Bool = false,
        cornerRadius: CGFloat = GameTheme.Layout.buttonCornerRadius,
        selectedColor: Color = GameTheme.Colors.accent,
        unselectedColor: Color = GameTheme.Colors.containerBackground
    ) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(isSelected ? selectedColor.opacity(0.2) : unselectedColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                isSelected ? selectedColor : GameTheme.Colors.gridBorder.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(
                        color: GameTheme.Colors.cardShadow.opacity(isSelected ? 0.3 : 0.1),
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: isSelected ? 4 : 2
                    )
            )
    }
    
    /// Applies 3D elevated card styling for prominent elements
    func game3DCardStyle(
        cornerRadius: CGFloat = GameTheme.Layout.cardCornerRadius,
        elevation: CGFloat = 8
    ) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(GameTheme.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        GameTheme.Colors.accent.opacity(0.3),
                                        GameTheme.Colors.accent.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: .black.opacity(0.1), radius: elevation * 0.5, x: 0, y: elevation * 0.25)
                    .shadow(color: .black.opacity(0.05), radius: elevation, x: 0, y: elevation * 0.5)
                    .shadow(color: GameTheme.Colors.accent.opacity(0.1), radius: elevation * 0.75, x: 0, y: elevation * 0.125)
            )
    }
    
    /// Applies gradient card styling
    func gameGradientCardStyle(
        cornerRadius: CGFloat = GameTheme.Layout.cardCornerRadius,
        gradient: LinearGradient? = nil,
        borderWidth: CGFloat = 2
    ) -> some View {
        let defaultGradient = LinearGradient(
            gradient: Gradient(colors: [
                GameTheme.Colors.accent.opacity(0.3),
                GameTheme.Colors.accent.opacity(0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        return self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(GameTheme.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(gradient ?? defaultGradient, lineWidth: borderWidth)
                    )
                    .shadow(
                        color: GameTheme.Colors.cardShadow,
                        radius: GameTheme.Layout.shadowRadius,
                        x: 0,
                        y: GameTheme.Layout.shadowOffset
                    )
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
            .font(GameTheme.Typography.titleFont)
            .foregroundColor(color)
    }
    
    /// Applies section header text styling
    func sectionHeaderStyle(color: Color = GameTheme.Colors.primaryText) -> some View {
        self
            .font(GameTheme.Typography.sectionHeaderFont)
            .foregroundColor(color)
    }
    
    /// Applies headline text styling
    func sectionTextStyle(color: Color = GameTheme.Colors.primaryText) -> some View {
        self
            .font(GameTheme.Typography.sectionTextFont)
            .foregroundColor(color)
    }
    
    
    /// Applies headline text styling
    func gameHeadlineStyle(color: Color = GameTheme.Colors.primaryText) -> some View {
        self
            .font(GameTheme.Typography.headlineFont)
            .foregroundColor(color)
    }
    
    /// Applies body text styling
    func gameBodyStyle(color: Color = GameTheme.Colors.primaryText) -> some View {
        self
            .font(GameTheme.Typography.bodyFont)
            .foregroundColor(color)
    }
    
    /// Applies caption text styling
    func gameCaptionStyle(color: Color = GameTheme.Colors.secondaryText) -> some View {
        self
            .font(GameTheme.Typography.captionFont)
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
    
    /// Applies table header styling with uneven rounded corners
    func gameTableHeaderStyle(
        backgroundColor: Color = GameTheme.Colors.accent.opacity(0.1),
        borderColor: Color = GameTheme.Colors.accent.opacity(0.3)
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
                .overlay(
                    UnevenRoundedRectangle(
                        topLeadingRadius: GameTheme.Layout.cardCornerRadius,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: GameTheme.Layout.cardCornerRadius
                    )
                    .stroke(borderColor, lineWidth: 1)
                )
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

