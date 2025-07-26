//
//  ContentView.swift
//  Leaves of Blocks
//
//  Created by Tim Veil on 7/25/25.
//

import SwiftUI

enum AppScreen {
    case home
    case game
    case summary
}

struct ContentView: View {
    @StateObject private var gameState = GameState()
    @State private var currentScreen: AppScreen = .home
    
    var body: some View {
        NavigationView {
            switch currentScreen {
            case .home:
                GameHomeView(
                    gameState: gameState,
                    onStartGame: { difficulty in
                        withAnimation(.easeInOut) {
                            gameState.startGame(difficulty: difficulty)
                            currentScreen = .game
                        }
                    }
                )
                .navigationBarHidden(true)
                .ignoresSafeArea(.container, edges: [])
                
            case .game:
                GameBoardView(
                    gameState: gameState,
                    onGoHome: {
                        withAnimation(.easeInOut) {
                            currentScreen = .home
                        }
                    },
                    onViewSummary: {
                        withAnimation(.easeInOut) {
                            currentScreen = .summary
                        }
                    }
                )
                .navigationBarHidden(true)
                .ignoresSafeArea(.container, edges: [])
                
            case .summary:
                GameSummaryView(
                    gameState: gameState,
                    onGoHome: {
                        withAnimation(.easeInOut) {
                            currentScreen = .home
                        }
                    },
                    onNewGame: {
                        withAnimation(.easeInOut) {
                            gameState.resetGame() // Keep current difficulty
                            currentScreen = .game
                        }
                    }
                )
                .navigationBarHidden(true)
                .ignoresSafeArea(.container, edges: [])
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Prevents split view on iPad
    }
}

#Preview {
    ContentView()
}
