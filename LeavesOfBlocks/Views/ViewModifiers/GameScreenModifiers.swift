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
    func gameTitleStyle(color: Color = GameTheme.Colors.primaryText) -> some View {
        self
            .font(GameTheme.Typography.titleFont)
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
    
    // MARK: - Interaction Modifiers
    
    /// Applies tap feedback with scale animation
    func gameTapFeedback() -> some View {
        self
            .scaleEffect(1.0)
            .onTapGesture {}
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.1), value: UUID())
    }
    
    /// Applies disabled state styling
    func gameDisabledStyle(_ isDisabled: Bool) -> some View {
        self
            .opacity(isDisabled ? 0.5 : 1.0)
            .disabled(isDisabled)
            .animation(.easeInOut(duration: 0.2), value: isDisabled)
    }
}

// MARK: - Preview Provider

#if DEBUG
struct GameScreenModifiers_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("Card Style")
                .gameBodyStyle()
                .padding()
                .gameCardStyle()
            
            Text("Gradient Card")
                .gameHeadlineStyle()
                .padding()
                .gameGradientCardStyle()
            
            Text("Title Style")
                .gameTitleStyle()
            
            Text("Disabled Button")
                .gameBodyStyle()
                .padding()
                .gameCardStyle()
                .gameDisabledStyle(true)
        }
        .gameContentPadding()
        .background(GameBackgroundView())
    }
}
#endif