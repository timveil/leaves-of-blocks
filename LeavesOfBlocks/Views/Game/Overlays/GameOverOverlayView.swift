import SwiftUI

// MARK: - Game Over Overlay

struct GameOverOverlayView: View {
    @ObservedObject var gameState: GameState
    let onViewSummary: () -> Void
    @State private var trophyScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: GameTheme.Layout.largePadding) {
            // Header section with new high score celebration
            VStack(spacing: GameTheme.Layout.mediumSpacing) {
                
                Text("game_over".localized)
                    .font(GameTheme.Typography.fontXLarge)
                    .foregroundColor(GameTheme.Colors.primaryText)
                    .tracking(1)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                
                // Body text placeholder
                Text("game_over_quote".localized)
                    .font(GameTheme.Typography.fontSmall)
                    .foregroundColor(GameTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, GameTheme.Layout.mediumPadding)
            }
            
            // Score section with enhanced 3D effect
            ScoreDisplayView(
                title: "final_score".localized,
                score: gameState.score
            )
            
            // Enhanced button using FullWidthActionButton component
            FullWidthActionButton(
                title: "view_summary".localized,
                icon: "chart.bar.fill",
                style: .primary,
                onTap: onViewSummary
            )
        }
        .padding(.horizontal, GameTheme.Layout.largePadding)
        .padding(.vertical, GameTheme.Layout.extraLargePadding)
        .frame(maxWidth: 2300) // Narrower width for iPhone visibility
        .game3DCardStyle(
            cornerRadius: GameTheme.Layout.overlayCornerRadius,
            elevation: 12
        )
        .padding(.horizontal, 40) // Ensure borders are visible on iPhone
        .scaleEffect(1.0)
        .transition(.scale.combined(with: .opacity))
    }
}

#Preview {
    ZStack {
        GameTheme.Gradients.background
            .ignoresSafeArea()
        
        GameOverOverlayView(
            gameState: {
                let state = GameState()
                state.score = 1250
                state.isNewHighScore = true
                return state
            }(),
            onViewSummary: {
                print("View Summary tapped")
            }
        )
    }
}
