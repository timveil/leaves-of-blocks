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
                AppToolbarView(
                    currentScreen: currentScreen,
                    onGoHome: {
                        withAnimation(GameTheme.Animations.springAnimation) {
                            currentScreen = .home
                        }
                    },
                    onShowAbout: {
                        withAnimation(GameTheme.Animations.springAnimation) {
                            currentScreen = .about
                        }
                    },
                    onShowHowToPlay: {
                        withAnimation(GameTheme.Animations.springAnimation) {
                            currentScreen = .howToPlay
                        }
                    },
                    onNewGame: {
                        withAnimation(GameTheme.Animations.springAnimation) {
                            if currentScreen != .game {
                                // If not on game screen, start a new game and navigate to game screen
                                gameState.startGame(difficulty: .moderate)
                                currentScreen = .game
                            } else {
                                // If on game screen, reset the current game
                                gameState.resetGame()
                            }
                        }
                    }
                )
                
                // Main Content Area
                switch currentScreen {
            case .home:
                HomeView(
                    gameState: gameState,
                    onStartGame: { difficulty in
                        withAnimation(GameTheme.Animations.springAnimation) {
                            gameState.startGame(difficulty: difficulty)
                            currentScreen = .game
                        }
                    },
                    onShowHistory: {
                        withAnimation(GameTheme.Animations.springAnimation) {
                            currentScreen = .history
                        }
                    }
                )
                .navigationBarHidden(true)
                .ignoresSafeArea(.container, edges: [])
                
            case .game:
                BoardView(
                    gameState: gameState,
                    onViewSummary: {
                        withAnimation(GameTheme.Animations.springAnimation) {
                            currentScreen = .summary(nil)
                        }
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
                        withAnimation(GameTheme.Animations.springAnimation) {
                            currentScreen = .summary(session)
                        }
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
        .navigationViewStyle(StackNavigationViewStyle()) // Prevents split view on iPad
    }
}

struct AppToolbarView: View {
    let currentScreen: AppScreen
    let onGoHome: () -> Void
    let onShowAbout: () -> Void
    let onShowHowToPlay: () -> Void
    let onNewGame: () -> Void
    
    var body: some View {
        HStack {
            // Home icon (always visible, but disabled on home screen)
            Button(action: currentScreen == .home ? {} : onGoHome) {
                Image(systemName: "house.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(currentScreen == .home ? GameTheme.Colors.blockBlue.opacity(0.4) : GameTheme.Colors.blockBlue)
            }
            .disabled(currentScreen == .home)
            
            Spacer()
            
            // Right side icons with proper spacing
            HStack(spacing: GameTheme.Layout.largePadding) {
                // New Game button (always visible)
                Button(action: onNewGame) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(GameTheme.Colors.accent)
                }
                
                // Info icon (About) - using gear for better visual balance
                Button(action: onShowAbout) {
                    Image(systemName: "gear")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                }
                
                // Help icon (How to Play)
                Button(action: onShowHowToPlay) {
                    Image(systemName: "questionmark")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(GameTheme.Colors.blockGreen)
                }
            }
        }
        .padding(.horizontal, GameTheme.Layout.largePadding)
        .padding(.vertical, GameTheme.Layout.mediumPadding)
        .background(
            LinearGradient(
                colors: [GameTheme.Colors.cardBackground, GameTheme.Colors.cardBackground.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(GameTheme.Colors.gridBorder.opacity(0.3)),
            alignment: .bottom
        )
    }
}

#Preview {
    ContentView()
}
