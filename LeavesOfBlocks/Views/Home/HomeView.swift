import SwiftUI

// MARK: - Game Home View

struct HomeView: View {
    var gameState: GameState
    let hasInProgressGame: Bool
    let onResumeGame: () -> Void
    let onStartGame: (DifficultyMode) -> Void

    private var playButtonTitle: String {
        hasInProgressGame ? "new_game".localized : "play_game".localized
    }

    var body: some View {
        BaseScreenView(showsStatusBar: false) {
            VStack(spacing: GameTheme.Layout.largePadding) {
                Spacer(minLength: 0)

                WhitmanSticker()

                if hasInProgressGame {
                    ContinueGameCard(
                        score: gameState.score,
                        action: onResumeGame
                    )
                }

                DifficultySelectionView(
                    onStartGame: onStartGame,
                    playButtonTitle: playButtonTitle
                )
                .padding(GameTheme.Layout.largePadding)
                .frame(maxWidth: .infinity)
                .contentCard()

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, GameTheme.Layout.largePadding)
            .padding(.vertical, GameTheme.Layout.mediumPadding)
        }
    }
}

// MARK: - Continue Game Card

private struct ContinueGameCard: View {
    let score: Int
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.tap()
            action()
        }) {
            HStack(spacing: GameTheme.Layout.mediumPadding) {
                Image(systemName: "arrow.uturn.forward.circle.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(GameTheme.Colors.success)

                VStack(alignment: .leading, spacing: 2) {
                    Text("continue_game".localized)
                        .font(GameTheme.Typography.headline)
                        .foregroundColor(GameTheme.Colors.primaryText)
                    Text("continue_game_format".localized(with: score))
                        .font(GameTheme.Typography.body)
                        .foregroundColor(GameTheme.Colors.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(GameTheme.Colors.secondaryText)
            }
            .padding(.horizontal, GameTheme.Layout.largePadding)
            .padding(.vertical, GameTheme.Layout.mediumPadding)
            .contentCard()
        }
        .buttonStyle(.pressDarken)
        .accessibilityIdentifier("continue_game_button")
    }
}

#Preview("No In-Progress Game") {
    HomeView(
        gameState: GameState(),
        hasInProgressGame: false,
        onResumeGame: { },
        onStartGame: { _ in }
    )
}

#if DEBUG
// Preview wraps the body in #if DEBUG because the `_setTestState(...)` seam
// on GameState is itself DEBUG-only. Without the guard, release-config
// archive builds (Xcode Cloud) fail to compile this preview.
#Preview("With In-Progress Game") {
    HomeView(
        gameState: {
            let state = GameState()
            state._setTestState(score: 4_280)
            return state
        }(),
        hasInProgressGame: true,
        onResumeGame: { },
        onStartGame: { _ in }
    )
}
#endif
