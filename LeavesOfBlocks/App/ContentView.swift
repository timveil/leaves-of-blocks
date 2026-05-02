import SwiftUI

// MARK: - Navigation Types

enum AppScreen: Equatable {
    case home
    case game
    case summary(GameSession?)
    case about
    case history
    case statistics
    case howToPlay
    case settings
}

// MARK: - Main Content View

struct ContentView: View {
    var gameState: GameState
    @State private var currentScreen: AppScreen = .home
    @State private var showDiscardConfirmation: Bool = false

    private var hasInProgressGame: Bool {
        gameState.hasActiveRun
    }

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
                            .accessibilityIdentifier("home_button")

                            Button(action: { resumeGame() }) {
                                Label("resume_game_menu".localized, systemImage: "arrow.uturn.forward")
                            }
                            .disabled(!hasInProgressGame || currentScreen == .game)
                            .accessibilityIdentifier("resume_game_button")

                            Button(action: { handleNewGame() }) {
                                Label("new_game_menu".localized, systemImage: "play")
                            }
                            .accessibilityIdentifier("new_game_button")

                            Divider()

                            Button(action: { handleNavigation(to: .history) }) {
                                Label("history_menu".localized, systemImage: "clock.arrow.circlepath")
                            }
                            .accessibilityIdentifier("history_button")

                            Button(action: { handleNavigation(to: .statistics) }) {
                                Label("statistics_menu".localized, systemImage: "chart.bar.fill")
                            }
                            .accessibilityIdentifier("statistics_button")

                            Divider()

                            Button(action: { handleNavigation(to: .howToPlay) }) {
                                Label("how_to_play_menu".localized, systemImage: "questionmark.circle")
                            }
                            .accessibilityIdentifier("how_to_play_button")

                            Button(action: { handleNavigation(to: .about) }) {
                                Label("about_menu".localized, systemImage: "info.circle")
                            }
                            .accessibilityIdentifier("about_button")

                            Button(action: { handleNavigation(to: .settings) }) {
                                Label("settings_menu".localized, systemImage: "gearshape")
                            }
                            .accessibilityIdentifier("settings_button")
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(GameTheme.Colors.primaryText)
                                .frame(width: 40, height: 40)
                                .contentShape(Rectangle())
                        }
                        .accessibilityIdentifier("menu_button")
                        .accessibilityLabel("menu_title".localized)
                    }
                }
                .toolbarBackground(.hidden, for: .navigationBar)
                .alert(
                    "discard_game_title".localized,
                    isPresented: $showDiscardConfirmation
                ) {
                    Button("cancel".localized, role: .cancel) {}
                    Button("discard_confirm".localized, role: .destructive) {
                        startNewGame(.moderate)
                    }
                } message: {
                    Text("discard_game_message".localized)
                }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        Group {
            switch currentScreen {
            case .home:
                HomeView(
                    gameState: gameState,
                    hasInProgressGame: hasInProgressGame,
                    onResumeGame: { resumeGame() },
                    onStartGame: { difficulty in
                        if hasInProgressGame {
                            showDiscardConfirmation = true
                        } else {
                            startNewGame(difficulty)
                        }
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

            case .statistics:
                StatisticsView()

            case .howToPlay:
                HowToPlayView()

            case .settings:
                SettingsView(gameState: gameState)
            }
        }
    }

    // MARK: - Navigation Helpers

    private func handleNavigation(to destination: AppScreen) {
        currentScreen = destination
    }

    private func handleNewGame() {
        if hasInProgressGame {
            showDiscardConfirmation = true
        } else {
            startNewGame(.moderate)
        }
    }

    private func startNewGame(_ difficulty: DifficultyMode) {
        gameState.startGame(difficulty: difficulty)
        currentScreen = .game
    }

    private func resumeGame() {
        currentScreen = .game
    }
}

#Preview {
    ContentView(gameState: GameState())
}
