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
    @StateObject private var gameState = GameState()
    @State private var currentScreen: AppScreen = .home
    @State private var pendingNavigation: AppScreen?
    @State private var showMenu = false

    // MARK: - View Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Main Content Area (full screen)
                mainContent

                // Persistent top bar: Whitman portrait + pull handle
                topBar

                // Slide-down menu overlay
                if showMenu {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation(.easeOut(duration: 0.25)) { showMenu = false } }
                        .zIndex(10)

                    VStack {
                        ToolbarView(
                            currentScreen: currentScreen,
                            onGoHome: { handleNavigation(to: .home) },
                            onShowAbout: { handleNavigation(to: .about) },
                            onShowHowToPlay: { handleNavigation(to: .howToPlay) },
                            onShowSettings: { handleNavigation(to: .settings) },
                            onNewGame: {
                                if currentScreen != .game {
                                    gameState.startGame(difficulty: .moderate)
                                    currentScreen = .game
                                } else {
                                    handleNewGameInProgress()
                                }
                            },
                            onDismiss: { withAnimation(.easeOut(duration: 0.25)) { showMenu = false } }
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))

                        Spacer()
                    }
                    .zIndex(11)
                }
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Spacer()

            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showMenu.toggle()
                }
            }) {
                Image(systemName: showMenu ? "xmark" : "line.3.horizontal")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(GameTheme.Colors.primaryText)
                    .frame(width: 40, height: 40)
            }
            .accessibilityIdentifier("menu_button")
        }
        .padding(.horizontal, GameTheme.Layout.largePadding)
        .padding(.top, 4)
        .zIndex(12)
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
                .gameScreenNavigation()

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
                .gameScreenNavigation()

            case .summary(let session):
                SummaryView(
                    gameState: gameState,
                    historicalSession: session
                )
                .gameScreenNavigation()

            case .about:
                AboutView()
                    .gameScreenNavigation()

            case .history:
                HistoryView(
                    gameState: gameState,
                    onSelectSession: { session in
                        currentScreen = .summary(session)
                    }
                )
                .gameScreenNavigation()

            case .howToPlay:
                HowToPlayView()
                    .gameScreenNavigation()

            case .settings:
                SettingsView(gameState: gameState)
                    .gameScreenNavigation()
            }
        }
    }

    // MARK: - Navigation Helpers

    private func handleNavigation(to destination: AppScreen) {
        withAnimation(.easeOut(duration: 0.25)) { showMenu = false }
        if currentScreen == .game && !gameState.isGameOver && gameState.score > 0 {
            pendingNavigation = destination
            gameState.showSaveGameDialog()
        } else {
            currentScreen = destination
        }
    }

    private func handleNewGameInProgress() {
        withAnimation(.easeOut(duration: 0.25)) { showMenu = false }
        if !gameState.isGameOver && gameState.score > 0 {
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
    ContentView()
}
