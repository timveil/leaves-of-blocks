//
//  Leaves_of_BlocksApp.swift
//  Leaves of Blocks
//
//  Created by Tim Veil on 7/25/25.
//

import SwiftUI

@main
struct LeavesOfBlocksApp: App {
    @State private var showLaunchScreen = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showLaunchScreen {
                    LaunchScreen()
                        .transition(.opacity)
                } else {
                    ContentView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: showLaunchScreen)
            .onAppear {
                // Show launch screen for 2.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    showLaunchScreen = false
                }
            }
        }
    }
}
