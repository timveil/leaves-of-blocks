//
//  ContentView.swift
//  Leaves of Blocks
//
//  Created by Tim Veil on 7/25/25.
//

import SwiftUI

enum AppScreen: Equatable {
    case home
    case game
    case summary(GameSession?)
    case about
    case history
    case howToPlay
}

struct ContentView: View {
    @StateObject private var gameState = GameState()
    @State private var currentScreen: AppScreen = .home

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Persistent Top Toolbar
                ToolbarView(
                    currentScreen: currentScreen,
                    onGoHome: {

                        currentScreen = .home

                    },
                    onShowAbout: {

                        currentScreen = .about

                    },
                    onShowHowToPlay: {

                        currentScreen = .howToPlay

                    },
                    onNewGame: {

                        if currentScreen != .game {
                            // If not on game screen, start a new game and navigate to game screen
                            gameState.startGame(difficulty: .moderate)
                            currentScreen = .game
                        } else {
                            // If on game screen, reset the current game
                            gameState.resetGame()
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
                        .navigationBarHidden(true)
                        .ignoresSafeArea(.container, edges: [])

                    case .game:
                        BoardView(
                            gameState: gameState,
                            onViewSummary: {

                                currentScreen = .summary(nil)

                            }
                        )
                        .navigationBarHidden(true)
                        .ignoresSafeArea(.container, edges: [])

                    case .summary(let session):
                        SummaryView(
                            gameState: gameState,
                            historicalSession: session
                        )
                        .navigationBarHidden(true)
                        .ignoresSafeArea(.container, edges: [])

                    case .about:
                        AboutView()
                            .navigationBarHidden(true)
                            .ignoresSafeArea(.container, edges: [])

                    case .history:
                        HistoryView(
                            gameState: gameState,
                            onSelectSession: { session in

                                currentScreen = .summary(session)

                            }
                        )
                        .navigationBarHidden(true)
                        .ignoresSafeArea(.container, edges: [])

                    case .howToPlay:
                        HowToPlayView()
                            .navigationBarHidden(true)
                            .ignoresSafeArea(.container, edges: [])
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())  // Prevents split view on iPad
    }
}

#Preview {
    ContentView()
}

struct Previews_ContentView_LibraryContent: LibraryContentProvider {
    var views: [LibraryItem] {
        LibraryItem( /*@START_MENU_TOKEN@*/
            Text("Hello, World!") /*@END_MENU_TOKEN@*/
        )
    }
}
