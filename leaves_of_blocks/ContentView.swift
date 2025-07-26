//
//  ContentView.swift
//  Leaves of Blocks
//
//  Created by Tim Veil on 7/25/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var gameState = GameState()
    @State private var isShowingGame = false
    
    var body: some View {
        NavigationView {
            if isShowingGame {
                GameBoardView(
                    gameState: gameState,
                    onGoHome: {
                        withAnimation(.easeInOut) {
                            isShowingGame = false
                        }
                    }
                )
                .navigationBarHidden(true)
                .ignoresSafeArea(.container, edges: []) // Respect all safe areas
            } else {
                GameHomeView(
                    gameState: gameState,
                    onStartGame: {
                        withAnimation(.easeInOut) {
                            gameState.resetGame() // Start fresh
                            isShowingGame = true
                        }
                    }
                )
                .navigationBarHidden(true)
                .ignoresSafeArea(.container, edges: []) // Respect all safe areas
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Prevents split view on iPad
    }
}

#Preview {
    ContentView()
}
