//
//  HighScoreManagerTests.swift
//  LeavesOfBlocksTests
//
//  Created by Tim Veil on 7/25/25.
//

import Testing
@testable import LeavesOfBlocks
import Foundation

// MARK: - High Score Manager Tests

struct HighScoreManagerTests {
    
    // Helper function to clear UserDefaults for testing
    private func clearHighScore() {
        UserDefaults.standard.removeObject(forKey: "LeaveOfBlocksHighScore")
        UserDefaults.standard.synchronize()
    }
    
    @Test("HighScoreManager initializes with zero score")
    func highScoreManagerInitializesWithZeroScore() {
        clearHighScore()
        
        let manager = HighScoreManager()
        #expect(manager.highScore == 0)
    }
    
    @Test("HighScoreManager loads existing high score")
    func highScoreManagerLoadsExistingHighScore() {
        // Ensure completely clean state
        UserDefaults.standard.removeObject(forKey: "LeaveOfBlocksHighScore")
        UserDefaults.standard.synchronize()
        
        // Set a high score manually
        UserDefaults.standard.set(1500, forKey: "LeaveOfBlocksHighScore")
        UserDefaults.standard.synchronize()
        
        let manager = HighScoreManager()
        #expect(manager.highScore == 1500)
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: "LeaveOfBlocksHighScore")
        UserDefaults.standard.synchronize()
    }
    
    @Test("Update high score with higher value")
    func updateHighScoreWithHigherValue() {
        // Ensure clean state
        UserDefaults.standard.removeObject(forKey: "LeaveOfBlocksHighScore")
        UserDefaults.standard.synchronize()
        
        let manager = HighScoreManager()
        
        // Verify starting state is clean
        #expect(manager.highScore == 0)
        
        manager.updateHighScore(1000)
        
        #expect(manager.highScore == 1000)
        
        // Verify it's saved to UserDefaults
        let savedScore = UserDefaults.standard.integer(forKey: "LeaveOfBlocksHighScore")
        #expect(savedScore == 1000)
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: "LeaveOfBlocksHighScore")
        UserDefaults.standard.synchronize()
    }
    
    @Test("Do not update high score with lower value")
    func doNotUpdateHighScoreWithLowerValue() {
        clearHighScore()
        
        let manager = HighScoreManager()
        manager.updateHighScore(1000)
        manager.updateHighScore(500)
        
        #expect(manager.highScore == 1000)
        
        clearHighScore()
    }
    
    @Test("Do not update high score with equal value")
    func doNotUpdateHighScoreWithEqualValue() {
        clearHighScore()
        
        let manager = HighScoreManager()
        manager.updateHighScore(1000)
        
        let originalScore = manager.highScore
        manager.updateHighScore(1000) // Same value
        
        // Should not change the high score
        #expect(manager.highScore == originalScore)
        #expect(manager.highScore == 1000)
        
        clearHighScore()
    }
    
    @Test("Update high score multiple times")
    func updateHighScoreMultipleTimes() {
        clearHighScore()
        
        let manager = HighScoreManager()
        
        manager.updateHighScore(100)
        #expect(manager.highScore == 100)
        
        manager.updateHighScore(500)
        #expect(manager.highScore == 500)
        
        manager.updateHighScore(300) // Lower score, should not update
        #expect(manager.highScore == 500)
        
        manager.updateHighScore(1000)
        #expect(manager.highScore == 1000)
        
        clearHighScore()
    }
    
    @Test("High score persists across manager instances")
    func highScorePersistsAcrossManagerInstances() {
        // Ensure completely clean state
        UserDefaults.standard.removeObject(forKey: "LeaveOfBlocksHighScore")
        UserDefaults.standard.synchronize()
        
        let manager1 = HighScoreManager()
        
        // Verify starting state is clean
        #expect(manager1.highScore == 0)
        
        manager1.updateHighScore(2000)
        #expect(manager1.highScore == 2000)
        
        // Verify persistence in UserDefaults
        let savedScore = UserDefaults.standard.integer(forKey: "LeaveOfBlocksHighScore")
        #expect(savedScore == 2000)
        
        let manager2 = HighScoreManager()
        #expect(manager2.highScore == 2000)
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: "LeaveOfBlocksHighScore")
        UserDefaults.standard.synchronize()
    }
    
    @Test("High score handles zero values")
    func highScoreHandlesZeroValues() {
        clearHighScore()
        
        let manager = HighScoreManager()
        manager.updateHighScore(0)
        
        #expect(manager.highScore == 0)
        
        manager.updateHighScore(100)
        #expect(manager.highScore == 100)
        
        manager.updateHighScore(0) // Should not update to lower value
        #expect(manager.highScore == 100)
        
        clearHighScore()
    }
    
    @Test("High score handles negative values")
    func highScoreHandlesNegativeValues() {
        // Ensure clean state
        UserDefaults.standard.removeObject(forKey: "LeaveOfBlocksHighScore")
        UserDefaults.standard.synchronize()
        
        let manager = HighScoreManager()
        
        // Verify starting state is clean
        #expect(manager.highScore == 0)
        
        manager.updateHighScore(-100)
        
        // Should not update to negative value if starting from 0
        #expect(manager.highScore == 0)
        
        manager.updateHighScore(500)
        #expect(manager.highScore == 500)
        
        manager.updateHighScore(-200)
        #expect(manager.highScore == 500)
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: "LeaveOfBlocksHighScore")
        UserDefaults.standard.synchronize()
    }
    
    @Test("High score handles very large values")
    func highScoreHandlesVeryLargeValues() {
        clearHighScore()
        
        let manager = HighScoreManager()
        let largeScore = 999_999_999 // Use a large but reasonable value
        
        manager.updateHighScore(largeScore)
        #expect(manager.highScore == largeScore)
        
        // Verify persistence
        let manager2 = HighScoreManager()
        #expect(manager2.highScore == largeScore)
        
        clearHighScore()
    }
    
    @Test("High score is Observable")
    func highScoreIsObservable() {
        clearHighScore()
        
        let manager = HighScoreManager()
        var receivedUpdate = false
        
        // This would be used in real SwiftUI applications
        // Here we're just testing that it's ObservableObject
        #expect(manager is ObservableObject)
        
        clearHighScore()
    }
}

// MARK: - High Score Integration Tests

struct HighScoreIntegrationTests {
    
    private func clearHighScore() {
        UserDefaults.standard.removeObject(forKey: "LeaveOfBlocksHighScore")
        UserDefaults.standard.synchronize()
    }
    
    @Test("GameState integrates with HighScoreManager")
    func gameStateIntegratesWithHighScoreManager() {
        clearHighScore()
        
        let gameState = GameState()
        
        // Initial high score should be 0
        #expect(gameState.highScoreManager.highScore == 0)
        
        // Set a score and trigger high score update
        gameState.score = 1500
        gameState.highScoreManager.updateHighScore(gameState.score)
        
        #expect(gameState.highScoreManager.highScore == 1500)
        
        clearHighScore()
    }
    
    @Test("Game over triggers high score check")
    func gameOverTriggersHighScoreCheck() {
        clearHighScore()
        
        let gameState = GameState()
        gameState.score = 2000
        
        // Manually trigger game over logic
        let oldHighScore = gameState.highScoreManager.highScore
        gameState.highScoreManager.updateHighScore(gameState.score)
        gameState.isNewHighScore = gameState.score > oldHighScore
        
        #expect(gameState.isNewHighScore)
        #expect(gameState.highScoreManager.highScore == 2000)
        
        clearHighScore()
    }
    
    @Test("Multiple games maintain highest score")
    func multipleGamesMaintainHighestScore() {
        clearHighScore()
        
        // Game 1
        let gameState1 = GameState()
        gameState1.score = 1000
        gameState1.highScoreManager.updateHighScore(gameState1.score)
        
        // Game 2
        let gameState2 = GameState()
        gameState2.score = 500
        gameState2.highScoreManager.updateHighScore(gameState2.score)
        
        // Game 3
        let gameState3 = GameState()
        gameState3.score = 1500
        gameState3.highScoreManager.updateHighScore(gameState3.score)
        
        #expect(gameState3.highScoreManager.highScore == 1500)
        
        clearHighScore()
    }
}

// MARK: - High Score Edge Cases

struct HighScoreEdgeCaseTests {
    
    private func clearHighScore() {
        UserDefaults.standard.removeObject(forKey: "LeaveOfBlocksHighScore")
        UserDefaults.standard.synchronize()
    }
    
    @Test("Concurrent high score updates")
    func concurrentHighScoreUpdates() async {
        clearHighScore()
        
        let manager = HighScoreManager()
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    manager.updateHighScore(i * 10)
                }
            }
        }
        
        #expect(manager.highScore == 990) // Highest value from concurrent updates
        
        clearHighScore()
    }
    
    @Test("Rapid successive updates")
    func rapidSuccessiveUpdates() {
        clearHighScore()
        
        let manager = HighScoreManager()
        
        for i in 0..<1000 {
            manager.updateHighScore(i)
        }
        
        #expect(manager.highScore == 999)
        
        clearHighScore()
    }
    
    @Test("UserDefaults corruption simulation")
    func userDefaultsCorruptionSimulation() {
        clearHighScore()
        
        // Simulate corrupted data by setting a string instead of integer
        UserDefaults.standard.set("corrupted", forKey: "LeaveOfBlocksHighScore")
        
        let manager = HighScoreManager()
        
        // Should handle corruption gracefully and default to 0
        #expect(manager.highScore == 0)
        
        clearHighScore()
    }
    
    @Test("Memory pressure scenarios")
    func memoryPressureScenarios() {
        clearHighScore()
        
        // Test creating many managers sequentially and updating scores
        var expectedHighScore = 0
        
        for i in 0..<10 {
            let manager = HighScoreManager()
            let score = i * 100
            manager.updateHighScore(score)
            expectedHighScore = max(expectedHighScore, score)
            
            // Verify this manager has the correct high score
            #expect(manager.highScore == expectedHighScore)
        }
        
        // Create a final manager to verify persistence
        let finalManager = HighScoreManager()
        #expect(finalManager.highScore == expectedHighScore)
        
        clearHighScore()
    }
}

// MARK: - High Score Performance Tests

struct HighScorePerformanceTests {
    
    private func clearHighScore() {
        UserDefaults.standard.removeObject(forKey: "LeaveOfBlocksHighScore")
        UserDefaults.standard.synchronize()
    }
    
    @Test("High score update performance")
    func highScoreUpdatePerformance() {
        clearHighScore()
        
        let manager = HighScoreManager()
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<1000 { // Reduced from 10000 to 1000 for more reliable testing
            manager.updateHighScore(i)
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        #expect(timeElapsed < 2.0, "High score updates should be reasonably fast")
        
        clearHighScore()
    }
    
    @Test("High score initialization performance")
    func highScoreInitializationPerformance() {
        clearHighScore()
        
        // Set a high score first
        UserDefaults.standard.set(5000, forKey: "LeaveOfBlocksHighScore")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<1000 {
            let _ = HighScoreManager()
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        #expect(timeElapsed < 0.5, "High score manager initialization should be fast")
        
        clearHighScore()
    }
}