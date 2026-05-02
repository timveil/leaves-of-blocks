import SwiftUI

// MARK: - Game Home View

struct HomeView: View {
    var gameState: GameState
    let hasInProgressGame: Bool
    let onResumeGame: () -> Void
    let onStartGame: (DifficultyMode) -> Void

    private var sectionTitle: String {
        hasInProgressGame ? "new_game_section_title".localized : "ready_to_play".localized
    }

    var body: some View {
        BaseScreenView(showsStatusBar: false) {
            VStack(spacing: GameTheme.Layout.largePadding) {
                if hasInProgressGame {
                    ContinueGameCard(
                        score: gameState.score,
                        action: onResumeGame
                    )
                }

                GoldHeaderCard(title: sectionTitle) {
                    DifficultySelectionView(
                        onStartGame: onStartGame
                    )
                }

                Spacer(minLength: 0)
            }
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
