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
            _ = try? context.execute(deleteRequest)
            
            // Create high score game (941 points) with specific date
            let highScoreGame = GameRecord(context: context)
            highScoreGame.id = UUID()
            highScoreGame.score = 941
            highScoreGame.difficulty = "Easy"
            highScoreGame.blocksPlaced = 45
            highScoreGame.linesCleared = 12
            highScoreGame.longestCombo = 3
            highScoreGame.gameTime = 385.2 // 6:25
            
            // Set date to May 31, 1819
            var dateComponents = DateComponents()
            dateComponents.year = 1819
            dateComponents.month = 5
            dateComponents.day = 31
            dateComponents.hour = 14
            dateComponents.minute = 30
            highScoreGame.date = Calendar.current.date(from: dateComponents)
            
            highScoreGame.averageGridEfficiency = 0.85
            highScoreGame.averageFragmentation = 0.23
            highScoreGame.strategicPlayRating = 0.92
            highScoreGame.challengeMaintained = 0.78
            highScoreGame.fallbackActivations = 2
            highScoreGame.efficiencyGrade = "A"
            highScoreGame.strategicGrade = "A+"
            
            // Save the context
            _ = try? context.save()
            
            #if DEBUG
            print("📱 Sample game history created for screenshots")
            #endif
        }
    }
}
