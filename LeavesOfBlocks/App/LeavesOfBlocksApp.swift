//
//  LeavesOfBlocksApp.swift
//  Leaves of Blocks
//
//  Created by Tim Veil on 7/25/25.
//

import SwiftUI
import CoreData

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
                    
                    // Create sample data for screenshots if in screenshot mode
                    if ProcessInfo.processInfo.arguments.contains("-screenshot-mode") {
                        createSampleGameHistory()
                    }
                } else {
                    // Show launch screen for 2.5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        showLaunchScreen = false
                    }
                }
            }
        }
    }
    
    // MARK: - Sample Data Creation
    
    private func createSampleGameHistory() {
        // Create sample game records for screenshots
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let context = coreDataManager.viewContext
            
            // Clear existing data first
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = GameRecord.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try? context.execute(deleteRequest)
            
            // Create high score game (941 points)
            let highScoreGame = GameRecord(context: context)
            highScoreGame.id = UUID()
            highScoreGame.score = 941
            highScoreGame.difficulty = "Easy"
            highScoreGame.blocksPlaced = 45
            highScoreGame.linesCleared = 12
            highScoreGame.longestCombo = 3
            highScoreGame.gameTime = 385.2 // 6:25
            highScoreGame.date = Calendar.current.date(byAdding: .day, value: -1, to: Date())
            highScoreGame.averageGridEfficiency = 0.85
            highScoreGame.averageFragmentation = 0.23
            highScoreGame.strategicPlayRating = 0.92
            highScoreGame.challengeMaintained = 0.78
            highScoreGame.fallbackActivations = 2
            highScoreGame.efficiencyGrade = "A"
            highScoreGame.strategicGrade = "A+"
            
            // Create a few more recent games
            let recentGame1 = GameRecord(context: context)
            recentGame1.id = UUID()
            recentGame1.score = 623
            recentGame1.difficulty = "Moderate"
            recentGame1.blocksPlaced = 31
            recentGame1.linesCleared = 8
            recentGame1.longestCombo = 2
            recentGame1.gameTime = 245.7 // 4:05
            recentGame1.date = Calendar.current.date(byAdding: .hour, value: -3, to: Date())
            recentGame1.averageGridEfficiency = 0.71
            recentGame1.averageFragmentation = 0.34
            recentGame1.strategicPlayRating = 0.76
            recentGame1.challengeMaintained = 0.65
            recentGame1.fallbackActivations = 5
            recentGame1.efficiencyGrade = "B+"
            recentGame1.strategicGrade = "B"
            
            let recentGame2 = GameRecord(context: context)
            recentGame2.id = UUID()
            recentGame2.score = 450
            recentGame2.difficulty = "Hard"
            recentGame2.blocksPlaced = 22
            recentGame2.linesCleared = 5
            recentGame2.longestCombo = 1
            recentGame2.gameTime = 168.3 // 2:48
            recentGame2.date = Calendar.current.date(byAdding: .hour, value: -1, to: Date())
            recentGame2.averageGridEfficiency = 0.59
            recentGame2.averageFragmentation = 0.45
            recentGame2.strategicPlayRating = 0.63
            recentGame2.challengeMaintained = 0.52
            recentGame2.fallbackActivations = 8
            recentGame2.efficiencyGrade = "C+"
            recentGame2.strategicGrade = "C"
            
            // Save the context
            try? context.save()
            
            #if DEBUG
            print("📱 Sample game history created for screenshots")
            #endif
        }
    }
}
