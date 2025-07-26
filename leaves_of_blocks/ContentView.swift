//
//  ContentView.swift
//  Leaves of Blocks
//
//  Created by Tim Veil on 7/25/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var gameState = GameState()
    
    var body: some View {
        NavigationView {
            GameBoardView(gameState: gameState)
                .navigationTitle("Leaves of Blocks")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
        }
    }
}

#Preview {
    ContentView()
}
