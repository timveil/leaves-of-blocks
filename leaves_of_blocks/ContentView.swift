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
    case about
    case history
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
                    },
                    onShowAbout: {
                        withAnimation(.easeInOut) {
                            currentScreen = .about
                        }
                    },
                    onShowHistory: {
                        withAnimation(.easeInOut) {
                            currentScreen = .history
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
                    }
                )
                .navigationBarHidden(true)
                .ignoresSafeArea(.container, edges: [])
                
            case .about:
                AboutView(
                    onDismiss: {
                        withAnimation(.easeInOut) {
                            currentScreen = .home
                        }
                    }
                )
                .navigationBarHidden(true)
                .ignoresSafeArea(.container, edges: [])
                
            case .history:
                GameHistoryView(
                    gameState: gameState,
                    onDismiss: {
                        withAnimation(.easeInOut) {
                            currentScreen = .home
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
