import SwiftUI

// MARK: - Game Over Overlay

struct GameOverOverlayView: View {
    var gameState: GameState
    let onViewSummary: () -> Void
    let onNewGame: () -> Void
    let onUndo: () -> Void
    let onViewBoard: () -> Void

    var body: some View {
        GoldHeaderCard(title: "game_over".localized) {
            VStack(spacing: GameTheme.Layout.largePadding) {
                Text("game_over_quote".localized)
                    .font(GameTheme.Typography.body)
                    .foregroundColor(GameTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)

                Text(gameState.score.abbreviatedScore)
                    .font(GameTheme.Typography.display)
                    .foregroundColor(GameTheme.Colors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                VStack(spacing: GameTheme.Layout.mediumPadding) {
                    // Offered only when the once-per-game undo is still available
                    // (it survives game-over so the player can take the fatal
                    // move back). Undoing flips `isGameOver` false, which
                    // dismisses this overlay.
                    if gameState.canUndo {
                        FullWidthActionButton(
                            title: "undo".localized,
                            icon: "arrow.uturn.backward",
                            style: .secondary,
                            accessibilityId: "game_over_undo_button",
                            onTap: onUndo
                        )
                    }

                    FullWidthActionButton(
                        title: "new_game".localized,
                        icon: "play.fill",
                        style: .primary,
                        accessibilityId: "game_over_new_game_button",
                        onTap: onNewGame
                    )

                    FullWidthActionButton(
                        title: "view_summary".localized,
                        icon: "list.bullet",
                        style: .secondary,
                        accessibilityId: "game_over_view_summary_button",
                        onTap: onViewSummary
                    )

                    // Hides this overlay to reveal the final board (grid +
                    // the unplaceable blocks) so the player can see how the
                    // game ended (issue #36). A floating button restores it.
                    FullWidthActionButton(
                        title: "view_board".localized,
                        icon: "square.grid.3x3",
                        style: .secondary,
                        accessibilityId: "game_over_view_board_button",
                        onTap: onViewBoard
                    )
                    .accessibilityHint("view_board_hint".localized)
                }
            }
        }
        .padding(.horizontal, GameTheme.Layout.extraLargePadding)
        .transition(.scale.combined(with: .opacity))
    }
}

#if DEBUG
// Preview wraps the body in #if DEBUG because the `_setTestState(...)` seam
// on GameState is itself DEBUG-only (it's a test/preview hook that the
// release surface deliberately doesn't expose). Without the guard the
// release-config archive used by Xcode Cloud fails to compile.
#Preview {
    ZStack {
        GameTheme.Gradients.background
            .ignoresSafeArea()

        GameOverOverlayView(
            gameState: {
                let state = GameState()
                state._setTestState(score: 100250, isNewHighScore: true)
                return state
            }(),
            onViewSummary: {},
            onNewGame: {},
            onUndo: {},
            onViewBoard: {}
        )
    }
}
#endif
