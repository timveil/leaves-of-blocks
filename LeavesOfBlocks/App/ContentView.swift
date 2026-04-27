import SwiftUI

// MARK: - Navigation Types

enum AppScreen: Equatable {
    case home
    case game
    case summary(GameSession?)
    case about
    case history
    case howToPlay
    case settings
}

// MARK: - Main Content View

struct ContentView: View {
    @ObservedObject var gameState: GameState
    @State private var currentScreen: AppScreen = .home
    @State private var pendingNavigation: AppScreen?

    // MARK: - View Body

    var body: some View {
        NavigationStack {
            mainContent
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button(action: { handleNavigation(to: .home) }) {
                                Label("home".localized, systemImage: "house")
                            }
                            .disabled(currentScreen == .home)

                            Button(action: { handleNewGame() }) {
                                Label("new_game_menu".localized, systemImage: "play")
                            }

                            Divider()

                            Button(action: { handleNavigation(to: .howToPlay) }) {
                                Label("how_to_play_menu".localized, systemImage: "questionmark.circle")
                            }

                            Button(action: { handleNavigation(to: .about) }) {
                                Label("about_menu".localized, systemImage: "info.circle")
                            }

                            Button(action: { handleNavigation(to: .settings) }) {
                                Label("settings_menu".localized, systemImage: "gearshape")
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(GameTheme.Colors.primaryText)
                                .frame(width: 40, height: 40)
                        }
                        .accessibilityIdentifier("menu_button")
                    }
                }
                .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        Group {
            switch currentScreen {
            case .home:
                HomeView(
                    gameState: gameState,
                    onStartGame: { difficulty in
                        gameState.startGame(difficulty: difficulty)
                        currentScreen = .game
                    },
                    onShowHistory: {
                        currentScreen = .history
                    }
                )

            case .game:
                BoardView(
                    gameState: gameState,
                    onViewSummary: {
                        currentScreen = .summary(nil)
                    },
                    onNewGame: {
                        gameState.resetGame()
                    },
                    onSaveAndExit: {
                        gameState.saveAndEndGame {
                            completePendingNavigation()
                        }
                    },
                    onExitWithoutSaving: {
                        gameState.exitWithoutSaving {
                            completePendingNavigation()
                        }
                    }
                )

            case .summary(let session):
                SummaryView(
                    gameState: gameState,
                    historicalSession: session
                )

            case .about:
                AboutView()

            case .history:
                HistoryView(
                    gameState: gameState,
                    onSelectSession: { session in
                        currentScreen = .summary(session)
                    }
                )

            case .howToPlay:
                HowToPlayView()

            case .settings:
                SettingsView(gameState: gameState)
            }
        }
    }

    // MARK: - Navigation Helpers

    private func handleNavigation(to destination: AppScreen) {
        if currentScreen == .game && !gameState.isGameOver && gameState.score > 0 {
            pendingNavigation = destination
            gameState.showSaveGameDialog()
        } else {
            currentScreen = destination
        }
    }

    private func handleNewGame() {
        if currentScreen != .game {
            gameState.startGame(difficulty: .moderate)
            currentScreen = .game
        } else if !gameState.isGameOver && gameState.score > 0 {
            pendingNavigation = .game
            gameState.showSaveGameDialog()
        } else {
            gameState.resetGame()
        }
    }

    private func completePendingNavigation() {
        guard let destination = pendingNavigation else { return }
        if destination == .game {
            gameState.resetGame()
        } else {
            currentScreen = destination
        }
        pendingNavigation = nil
    }
}

#Preview {
    ContentView(gameState: GameState())
}
