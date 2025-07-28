//
//  LeavesOfBlocksAppClipApp.swift
//  LeavesOfBlocksAppClip
//
//  Created by Tim Veil on 7/27/25.
//

import SwiftUI
import AppClip

@main
struct LeavesOfBlocksAppClipApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    // Handle App Clip invocation from web link
                    if let url = userActivity.webpageURL {
                        handleAppClipInvocation(from: url)
                    }
                }
        }
    }
    
    private func handleAppClipInvocation(from url: URL) {
        // Handle different App Clip invocation scenarios
        // For example, deep linking to specific game modes or challenges
        print("App Clip invoked from: \(url)")
        
        // You can parse the URL to determine specific actions
        // For now, we'll just show the default quick play experience
    }
}
