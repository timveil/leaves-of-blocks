import SwiftUI

// MARK: - Game Over Overlay

struct GameOverOverlayView: View {
    @ObservedObject var gameState: GameState
    let onViewSummary: () -> Void
    @State private var buttonPressed = false
    @State private var trophyScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: GameTheme.Layout.largePadding) {
            // Header section with new high score celebration
            VStack(spacing: GameTheme.Layout.mediumSpacing) {
                if gameState.isNewHighScore {
                    VStack(spacing: GameTheme.Layout.smallSpacing) {
                        Text("🏆")
                            .font(.system(size: 40))
                            .scaleEffect(trophyScale)
                            .shadow(color: GameTheme.Colors.accent.opacity(0.6), radius: 8, x: 0, y: 4)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                                    trophyScale = 1.2
                                }
                            }
                            .onDisappear {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    trophyScale = 1.0
                                }
                            }
                        
                        Text("NEW HIGH SCORE!")
                            .font(GameTheme.Typography.titleFont)
                            .foregroundColor(GameTheme.Colors.accent)
                            .tracking(1.5)
                            .multilineTextAlignment(.center)
                            .shadow(color: GameTheme.Colors.accent.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .padding(.vertical, GameTheme.Layout.mediumPadding)
                    .frame(maxWidth: .infinity)
                    .background(
                        ZStack {
                            // 3D depth background layers
                            RoundedRectangle(cornerRadius: GameTheme.Layout.buttonCornerRadius)
                                .fill(GameTheme.Colors.accent.opacity(0.15))
                                .offset(x: 2, y: 2)
                            
                            RoundedRectangle(cornerRadius: GameTheme.Layout.buttonCornerRadius)
                                .fill(GameTheme.Colors.accent.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: GameTheme.Layout.buttonCornerRadius)
                                        .stroke(
                                            LinearGradient(
                                                colors: [GameTheme.Colors.accent.opacity(0.4), GameTheme.Colors.accent.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                        }
                    )
                }
                
                Text("Game Over")
                    .font(GameTheme.Typography.title)
                    .foregroundColor(GameTheme.Colors.primaryText)
                    .tracking(1)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
            
            // Score section with enhanced 3D effect
            VStack(spacing: GameTheme.Layout.mediumSpacing) {
                Text("Final Score")
                    .font(GameTheme.Typography.headlineFont)
                    .foregroundColor(GameTheme.Colors.secondaryText)
                    .tracking(1)
                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                
                Text("\(gameState.score)")
                    .font(GameTheme.Typography.largeScore)
                    .foregroundColor(GameTheme.Colors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .shadow(color: GameTheme.Colors.accent.opacity(0.4), radius: 6, x: 0, y: 3)
            }
            .padding(.vertical, GameTheme.Layout.largePadding)
            .padding(.horizontal, GameTheme.Layout.largePadding)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    // Multiple shadow layers for deep 3D effect
                    RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                        .fill(Color.black.opacity(0.1))
                        .offset(x: 4, y: 6)
                    
                    RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                        .fill(Color.black.opacity(0.05))
                        .offset(x: 2, y: 3)
                    
                    RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    GameTheme.Colors.cardBackground.opacity(0.9),
                                    GameTheme.Colors.cardBackground.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.2),
                                            Color.clear,
                                            Color.black.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                }
            )
            
            // Enhanced 3D button
            Button(action: onViewSummary) {
                HStack(spacing: GameTheme.Layout.smallSpacing) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 16, weight: .bold))
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                    
                    Text("View Summary")
                        .font(GameTheme.Typography.headlineFont)
                        .lineLimit(1)
                        .fixedSize()
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                }
                .foregroundColor(GameTheme.Colors.buttonText)
                .padding(.horizontal, GameTheme.Layout.largePadding)
                .padding(.vertical, GameTheme.Layout.mediumPadding)
                .background(
                    ZStack {
                        // Deep shadow layers for 3D effect
                        Capsule()
                            .fill(Color.black.opacity(0.2))
                            .offset(x: 0, y: 6)
                        
                        Capsule()
                            .fill(Color.black.opacity(0.1))
                            .offset(x: 0, y: 3)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        GameTheme.Colors.accent,
                                        GameTheme.Colors.accent.opacity(0.8),
                                        GameTheme.Colors.accent.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.3),
                                                Color.clear,
                                                Color.black.opacity(0.2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: GameTheme.Colors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                )
            }
            .scaleEffect(buttonPressed ? 0.95 : 1.0)
            .offset(y: buttonPressed ? 3 : 0)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    buttonPressed = pressing
                }
            }, perform: {})
        }
        .padding(.horizontal, GameTheme.Layout.largePadding)
        .padding(.vertical, GameTheme.Layout.extraLargePadding)
        .frame(maxWidth: 280) // Narrower width for iPhone visibility
        .background(
            ZStack {
                // Multiple shadow layers for deep dialog 3D effect
                RoundedRectangle(cornerRadius: GameTheme.Layout.overlayCornerRadius)
                    .fill(Color.black.opacity(0.15))
                    .offset(x: 0, y: 8)
                
                RoundedRectangle(cornerRadius: GameTheme.Layout.overlayCornerRadius)
                    .fill(Color.black.opacity(0.08))
                    .offset(x: 0, y: 4)
                
                RoundedRectangle(cornerRadius: GameTheme.Layout.overlayCornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                GameTheme.Colors.overlayBackground,
                                GameTheme.Colors.overlayBackground.opacity(0.95)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: GameTheme.Layout.overlayCornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        GameTheme.Colors.overlayBorderGradient[0],
                                        GameTheme.Colors.overlayBorderGradient[1],
                                        Color.black.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: GameTheme.Layout.strokeWidth
                            )
                    )
            }
        )
        .padding(.horizontal, 40) // Ensure borders are visible on iPhone
        .scaleEffect(1.0)
        .transition(.scale.combined(with: .opacity))
    }
}