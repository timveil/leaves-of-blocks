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

                DifficultyCard(
                    onStartGame: onStartGame,
                    playButtonTitle: playButtonTitle
                )

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
        Button(action: action) {
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
            .background(GameTheme.Colors.cardBackground)
            .folkArtCard()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("continue_game_button")
    }
}

// MARK: - Difficulty Card (no gold header)

private struct DifficultyCard: View {
    let onStartGame: (DifficultyMode) -> Void
    let playButtonTitle: String

    var body: some View {
        DifficultySelectionView(
            onStartGame: onStartGame,
            playButtonTitle: playButtonTitle
        )
        .padding(.horizontal, GameTheme.Layout.largePadding)
        .padding(.vertical, GameTheme.Layout.largePadding)
        .frame(maxWidth: .infinity)
        .background(GameTheme.Colors.cardBackground)
        .folkArtCard()
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

#Preview("With In-Progress Game") {
    HomeView(
        gameState: {
            let state = GameState()
            state.score = 4_280
            return state
        }(),
        hasInProgressGame: true,
        onResumeGame: { },
        onStartGame: { _ in }
    )
}
