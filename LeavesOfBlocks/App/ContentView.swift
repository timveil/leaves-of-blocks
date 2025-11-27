//
//  ContentView.swift
//  Leaves of Blocks
//
//  Created by Tim Veil on 7/25/25.
//

import SwiftUI

// MARK: - Navigation Types

/// Represents the different screens available in the app.
///
/// This enum defines all possible navigation destinations within the app's
/// single-view navigation system. Each case corresponds to a major app section.
///
/// ## Associated Values
/// - `summary(GameSession?)`: Can display either current game summary (nil) or historical session
///
/// ## Navigation Flow
/// The app follows a hub-and-spoke pattern with Home as the central navigation point.
enum AppScreen: Equatable {
    /// Main menu screen with difficulty selection and game history access
    case home
    /// Active gameplay screen with 8x8 grid and block placement
    case game
    /// Game results screen, optionally showing a specific historical session
    case summary(GameSession?)
    /// App information and credits screen
    case about
    /// Historical game sessions and statistics
    case history
    /// Tutorial and gameplay instructions
    case howToPlay
    /// Settings screen for data management and app preferences
    case settings
}

// MARK: - Main Content View

/// The root view controller for the entire app.
///
/// `ContentView` manages the app's navigation state and coordinates between different screens.
/// It maintains a single `GameState` instance that is shared across all game-related views.
///
/// ## Architecture
/// - Uses enum-based navigation with `AppScreen` for type-safe screen management
/// - Maintains persistent toolbar across all screens
/// - Shares single `GameState` instance for data consistency
/// - Implements hub-and-spoke navigation pattern
struct ContentView: View {
    /// Shared game state instance used across all screens
    @StateObject private var gameState = GameState()
    /// Current active screen in the navigation flow
    @State private var currentScreen: AppScreen = .home
    /// Pending navigation destination when save dialog is shown
    @State private var pendingNavigation: AppScreen?

    // MARK: - View Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Persistent Top Toolbar
                ToolbarView(
                    currentScreen: currentScreen,
                    onGoHome: {
                        handleNavigation(to: .home)
                    },
                    onShowAbout: {
                        handleNavigation(to: .about)
                    },
                    onShowHowToPlay: {
                        handleNavigation(to: .howToPlay)
                    },
                    onShowSettings: {
                        handleNavigation(to: .settings)
                    },
                    onNewGame: {
                        if currentScreen != .game {
                            // If not on game screen, start a new game and navigate to game screen
                            gameState.startGame(difficulty: .moderate)
                            currentScreen = .game
                        } else {
                            // If on game screen, reset the current game (this could also trigger save dialog)
                            handleNewGameInProgress()
                        }
                    }
                )

                // Main Content Area
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
        }
    }
    
    // MARK: - Navigation Helpers
    
    /// Handles navigation requests, showing save dialog if currently in an active game
    private func handleNavigation(to destination: AppScreen) {
        // Check if we're in an active game and not game over
        if currentScreen == .game && !gameState.isGameOver && gameState.score > 0 {
            // Store the pending destination and show save dialog
            pendingNavigation = destination
            gameState.showSaveGameDialog()
        } else {
            // Navigate immediately if not in active game
            currentScreen = destination
        }
    }
    
    /// Handles new game request when already in game
    private func handleNewGameInProgress() {
        // Check if we have an active game with progress
        if !gameState.isGameOver && gameState.score > 0 {
            // Store new game as pending action and show save dialog
            pendingNavigation = .game  // Special case: staying on game screen but resetting
            gameState.showSaveGameDialog()
        } else {
            // Reset immediately if no progress to lose
            gameState.resetGame()
        }
    }
    
    /// Completes navigation after save dialog resolution
    private func completePendingNavigation() {
        guard let destination = pendingNavigation else { return }
        
        if destination == .game {
            // Special case: new game request
            gameState.resetGame()
        } else {
            // Regular navigation
            currentScreen = destination
        }
        
        pendingNavigation = nil
    }
}

#Preview {
    ContentView()
}
