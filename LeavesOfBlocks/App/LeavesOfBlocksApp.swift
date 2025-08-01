//
//  LeavesOfBlocksApp.swift
//  Leaves of Blocks
//
//  Created by Tim Veil on 7/25/25.
//

import SwiftUI

@main
struct Main: App {
    @State private var showLaunchScreen = true
    let coreDataManager = CoreDataManager.shared
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Consistent background to prevent white flash
                GameTheme.Gradients.background
                    .ignoresSafeArea()
                
                if showLaunchScreen {
                    LaunchScreen()
                        .transition(.opacity)
                } else {
                    ContentView()
                        .transition(.opacity)
                        .environment(\.managedObjectContext, coreDataManager.viewContext)
                }
            }
            .onAppear {
                // Skip launch screen during UI testing
                if ProcessInfo.processInfo.arguments.contains("-ui-testing") {
                    showLaunchScreen = false
                } else {
                    // Show launch screen for 2.5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        showLaunchScreen = false
                    }
                }
            }
        }
    }
}
