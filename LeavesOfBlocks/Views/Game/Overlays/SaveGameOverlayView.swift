import SwiftUI

// MARK: - Save Game Overlay

struct SaveGameOverlayView: View {
    @ObservedObject var gameState: GameState
    let onSaveGame: () -> Void
    let onExitGame: () -> Void
    
    var body: some View {
        VStack(spacing: GameTheme.Layout.largePadding) {
            // Header section
            VStack(spacing: GameTheme.Layout.mediumSpacing) {
                
                Text("save_game_title".localized)
                    .font(GameTheme.Typography.fontXLarge)
                    .foregroundColor(GameTheme.Colors.primaryText)
                    .tracking(1)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                
                // Body text
                Text("save_game_message".localized)
                    .font(GameTheme.Typography.fontSmall)
                    .foregroundColor(GameTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, GameTheme.Layout.mediumPadding)
            }
            
            // Current score section
            ScoreDisplayView(
                title: "current_score".localized,
                score: gameState.score
            )
            
            // Action buttons
            VStack(spacing: GameTheme.Layout.mediumSpacing) {
                // Save Game button
                FullWidthActionButton(
                    title: "save_game_button".localized,
                    icon: "checkmark.circle.fill",
                    style: .success,
                    onTap: onSaveGame
                )
                
                // Exit Without Saving button
                FullWidthActionButton(
                    title: "exit_without_saving".localized,
                    icon: "xmark.circle.fill",
                    style: .danger,
                    onTap: onExitGame
                )
            }
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
        
        SaveGameOverlayView(
            gameState: {
                let state = GameState()
                state.score = 875
                return state
            }(),
            onSaveGame: {
                print("Save Game tapped")
            },
            onExitGame: {
                print("Exit Game tapped")
            }
        )
    }
}