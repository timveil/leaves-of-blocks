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
                    .game3DCardStyle(
                        cornerRadius: GameTheme.Layout.buttonCornerRadius,
                        elevation: 6
                    )
                }
                
                Text("Game Over")
                    .font(GameTheme.Typography.title)
                    .foregroundColor(GameTheme.Colors.primaryText)
                    .tracking(1)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
            
            // Score section with enhanced 3D effect
            ScoreDisplayView(
                title: "Final Score",
                score: gameState.score
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
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    GameTheme.Colors.accent,
                                    GameTheme.Colors.accent.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 6)
                        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 3)
                        .shadow(color: GameTheme.Colors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
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
        .game3DCardStyle(
            cornerRadius: GameTheme.Layout.overlayCornerRadius,
            elevation: 12
        )
        .padding(.horizontal, 40) // Ensure borders are visible on iPhone
        .scaleEffect(1.0)
        .transition(.scale.combined(with: .opacity))
    }
}