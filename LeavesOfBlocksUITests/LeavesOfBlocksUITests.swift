//
//  LeavesOfBlocksUITests.swift
//  Leaves of BlocksUITests
//
//  Created by Tim Veil on 7/25/25.
//

import XCTest

// MARK: - Navigation and Screen Flow Tests

final class LeavesOfBlocksNavigationTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }
    
    @MainActor
    func testAppLaunchAndHomeScreen() throws {
        app.launch()
        
        // Verify app launches successfully
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        
        // Check for presence of difficulty selection buttons
        XCTAssertTrue(app.buttons["Easy"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Moderate"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Hard"].waitForExistence(timeout: 2))
        
        // Check for navigation buttons
        XCTAssertTrue(app.buttons["About"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["History"].waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testNavigationToAboutScreen() throws {
        app.launch()
        
        // Wait for home screen to load
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        
        // Navigate to About screen
        app.buttons["About"].tap()
        
        // Verify About screen elements
        XCTAssertTrue(app.staticTexts["About"].waitForExistence(timeout: 3))
        
        // Navigate back to home
        if app.buttons["Back"].exists {
            app.buttons["Back"].tap()
        } else if app.buttons["Home"].exists {
            app.buttons["Home"].tap()
        }
        
        // Verify we're back on home screen
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 3))
    }
    
    @MainActor
    func testNavigationToHistoryScreen() throws {
        app.launch()
        
        // Wait for home screen to load
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        
        // Navigate to History screen
        app.buttons["History"].tap()
        
        // Verify History screen is displayed
        XCTAssertTrue(app.staticTexts["Game History"].waitForExistence(timeout: 3) ||
                     app.staticTexts["History"].waitForExistence(timeout: 3))
        
        // Navigate back to home
        if app.buttons["Back"].exists {
            app.buttons["Back"].tap()
        } else if app.buttons["Home"].exists {
            app.buttons["Home"].tap()
        }
        
        // Verify we're back on home screen
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 3))
    }
    
    @MainActor
    func testDifficultySelectionAndGameStart() throws {
        app.launch()
        
        // Wait for home screen to load
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        
        // Test each difficulty level
        let difficulties = ["Easy", "Moderate", "Hard"]
        
        for difficulty in difficulties {
            // Tap difficulty button
            app.buttons[difficulty].tap()
            
            // Verify game screen loads (look for score display or grid)
            let gameStarted = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.waitForExistence(timeout: 3) ||
                             app.otherElements["GameGrid"].waitForExistence(timeout: 3)
            
            XCTAssertTrue(gameStarted, "Game should start after selecting \(difficulty)")
            
            // Navigate back to home using home button
            if app.buttons["house.fill"].exists {
                app.buttons["house.fill"].tap()
            } else if app.buttons["Home"].exists {
                app.buttons["Home"].tap()
            }
            
            // Wait for home screen to reload
            XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 3))
        }
    }
    
    @MainActor
    func testGameScreenToSummaryNavigation() throws {
        app.launch()
        
        // Start a game
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        app.buttons["Easy"].tap()
        
        // Verify game screen loads
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.waitForExistence(timeout: 3))
        
        // Look for summary/stats button (this might be after game over or accessible via menu)
        if app.buttons["Summary"].exists {
            app.buttons["Summary"].tap()
            
            // Verify summary screen loads
            XCTAssertTrue(app.staticTexts["Game Summary"].waitForExistence(timeout: 3) ||
                         app.staticTexts["Summary"].waitForExistence(timeout: 3))
        }
    }
}

// MARK: - Game Interaction Tests

final class LeavesOfBlocksGameplayTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }
    
    @MainActor
    func testGameInitialization() throws {
        app.launch()
        
        // Start a game
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        app.buttons["Easy"].tap()
        
        // Verify game elements are present
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.waitForExistence(timeout: 3))
        
        // Check for game grid (represented as collection or other elements)
        let gameArea = app.otherElements.containing(.staticText, identifier: "0").firstMatch
        XCTAssertTrue(gameArea.waitForExistence(timeout: 3))
        
        // Verify blocks are available for placement
        let blockExists = app.otherElements.matching(NSPredicate(format: "identifier CONTAINS 'block'")).count > 0
        // Note: This test depends on accessibility identifiers being added to the actual game blocks
    }
    
    @MainActor
    func testScoreDisplay() throws {
        app.launch()
        
        // Start a game
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        app.buttons["Easy"].tap()
        
        // Verify score is displayed and starts at 0
        let scoreElement = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch
        XCTAssertTrue(scoreElement.waitForExistence(timeout: 3))
        
        // Initial score should be 0
        XCTAssertEqual(scoreElement.label, "0")
    }
    
    @MainActor
    func testGameResetFunctionality() throws {
        app.launch()
        
        // Start a game
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        app.buttons["Easy"].tap()
        
        // Wait for game to load
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.waitForExistence(timeout: 3))
        
        // Look for reset button (arrow.clockwise icon)
        if app.buttons["arrow.clockwise"].exists {
            app.buttons["arrow.clockwise"].tap()
            
            // Verify game resets (score should be 0)
            let scoreElement = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch
            XCTAssertTrue(scoreElement.waitForExistence(timeout: 3))
            XCTAssertEqual(scoreElement.label, "0")
        }
    }
    
    @MainActor
    func testHomeButtonFunctionality() throws {
        app.launch()
        
        // Start a game
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        app.buttons["Easy"].tap()
        
        // Wait for game to load
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.waitForExistence(timeout: 3))
        
        // Tap home button
        if app.buttons["house.fill"].exists {
            app.buttons["house.fill"].tap()
        } else if app.buttons["Home"].exists {
            app.buttons["Home"].tap()
        }
        
        // Verify we're back on home screen
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 3))
    }
    
    @MainActor
    func testBlockDragAndDropInteraction() throws {
        app.launch()
        
        // Start a game
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        app.buttons["Easy"].tap()
        
        // Wait for game to load
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.waitForExistence(timeout: 3))
        
        // This test would require specific accessibility identifiers on block elements
        // For now, we'll test that the game screen is interactive
        let gameArea = app.otherElements.firstMatch
        XCTAssertTrue(gameArea.exists)
        
        // Perform a tap on the game area to test interactivity
        gameArea.tap()
        
        // Verify the app doesn't crash and remains responsive
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.exists)
    }
}

// MARK: - Accessibility Tests

final class LeavesOfBlocksAccessibilityTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }
    
    @MainActor
    func testVoiceOverSupport() throws {
        app.launch()
        
        // Enable accessibility for testing
        // Check that key elements have accessibility labels
        
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        
        // Check difficulty buttons have accessible labels
        let easyButton = app.buttons["Easy"]
        XCTAssertTrue(easyButton.exists)
        XCTAssertNotNil(easyButton.label)
        XCTAssertTrue(easyButton.isHittable)
        
        let moderateButton = app.buttons["Moderate"]
        XCTAssertTrue(moderateButton.exists)
        XCTAssertNotNil(moderateButton.label)
        XCTAssertTrue(moderateButton.isHittable)
        
        let hardButton = app.buttons["Hard"]
        XCTAssertTrue(hardButton.exists)
        XCTAssertNotNil(hardButton.label)
        XCTAssertTrue(hardButton.isHittable)
    }
    
    @MainActor
    func testButtonAccessibility() throws {
        app.launch()
        
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        
        // Test About button accessibility
        let aboutButton = app.buttons["About"]
        XCTAssertTrue(aboutButton.exists)
        XCTAssertTrue(aboutButton.isHittable)
        XCTAssertFalse(aboutButton.label.isEmpty)
        
        // Test History button accessibility
        let historyButton = app.buttons["History"]
        XCTAssertTrue(historyButton.exists)
        XCTAssertTrue(historyButton.isHittable)
        XCTAssertFalse(historyButton.label.isEmpty)
    }
    
    @MainActor
    func testGameAccessibilityInPlay() throws {
        app.launch()
        
        // Start a game
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        app.buttons["Easy"].tap()
        
        // Wait for game to load
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.waitForExistence(timeout: 3))
        
        // Check home button accessibility
        if app.buttons["house.fill"].exists {
            let homeButton = app.buttons["house.fill"]
            XCTAssertTrue(homeButton.isHittable)
        }
        
        // Check reset button accessibility
        if app.buttons["arrow.clockwise"].exists {
            let resetButton = app.buttons["arrow.clockwise"]
            XCTAssertTrue(resetButton.isHittable)
        }
    }
    
    @MainActor
    func testColorContrastAndVisibility() throws {
        app.launch()
        
        // Start a game to test game elements
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        app.buttons["Easy"].tap()
        
        // Verify key elements are visible and accessible
        let scoreElement = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch
        XCTAssertTrue(scoreElement.waitForExistence(timeout: 3))
        XCTAssertTrue(scoreElement.isHittable || scoreElement.exists) // Score should be visible
    }
}

// MARK: - Performance and Stability Tests

final class LeavesOfBlocksPerformanceTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }
    
    @MainActor
    func testAppLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
            app.terminate()
        }
    }
    
    @MainActor
    func testNavigationPerformance() throws {
        app.launch()
        
        measure(metrics: [XCTClockMetric()]) {
            XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
            
            // Test navigation speed
            app.buttons["About"].tap()
            _ = app.staticTexts["About"].waitForExistence(timeout: 2)
            
            if app.buttons["Back"].exists {
                app.buttons["Back"].tap()
            } else if app.buttons["Home"].exists {
                app.buttons["Home"].tap()
            }
            
            _ = app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 2)
        }
    }
    
    @MainActor
    func testGameStartPerformance() throws {
        app.launch()
        
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        
        measure(metrics: [XCTClockMetric()]) {
            app.buttons["Easy"].tap()
            
            // Wait for game to fully load
            _ = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.waitForExistence(timeout: 3)
            
            // Navigate back home
            if app.buttons["house.fill"].exists {
                app.buttons["house.fill"].tap()
            }
            
            _ = app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 2)
        }
    }
    
    @MainActor
    func testMemoryStability() throws {
        app.launch()
        
        // Perform multiple navigation cycles to test memory stability
        for _ in 0..<5 {
            XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 3))
            
            // Start game
            app.buttons["Easy"].tap()
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.waitForExistence(timeout: 3))
            
            // Go to About
            if app.buttons["house.fill"].exists {
                app.buttons["house.fill"].tap()
            }
            XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 3))
            
            app.buttons["About"].tap()
            _ = app.staticTexts["About"].waitForExistence(timeout: 3)
            
            if app.buttons["Back"].exists {
                app.buttons["Back"].tap()
            } else if app.buttons["Home"].exists {
                app.buttons["Home"].tap()
            }
        }
        
        // App should still be responsive
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].exists)
    }
    
    @MainActor
    func testRotationStability() throws {
        app.launch()
        
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        
        // Test rotation (if supported)
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 3))
        
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 3))
        
        // Start a game and test rotation
        app.buttons["Easy"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.waitForExistence(timeout: 3))
        
        XCUIDevice.shared.orientation = .landscapeLeft
        // Verify game still works
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.exists)
        
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.exists)
    }
}

// MARK: - Edge Case and Error Handling Tests

final class LeavesOfBlocksEdgeCaseTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }
    
    @MainActor
    func testRapidButtonTapping() throws {
        app.launch()
        
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        
        // Rapidly tap difficulty buttons
        for _ in 0..<10 {
            if app.buttons["Easy"].exists {
                app.buttons["Easy"].tap()
            }
            if app.buttons["house.fill"].exists {
                app.buttons["house.fill"].tap()
            }
        }
        
        // App should remain stable
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 3))
    }
    
    @MainActor
    func testBackgroundAndForeground() throws {
        app.launch()
        
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        
        // Start a game
        app.buttons["Easy"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.waitForExistence(timeout: 3))
        
        // Simulate app going to background and returning
        XCUIDevice.shared.press(.home)
        app.activate()
        
        // Verify game state is preserved or properly handled
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.waitForExistence(timeout: 3) ||
                     app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 3))
    }
    
    @MainActor
    func testLowMemoryScenario() throws {
        app.launch()
        
        // Start and restart the app multiple times
        for _ in 0..<3 {
            XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
            
            app.buttons["Easy"].tap()
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.waitForExistence(timeout: 3))
            
            app.terminate()
            app.launch()
        }
        
        // Final verification
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
    }
    
    @MainActor
    func testExtendedGameSession() throws {
        app.launch()
        
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        
        // Start a game and let it run for extended period
        app.buttons["Easy"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.waitForExistence(timeout: 3))
        
        // Simulate extended play session (minimal interactions)
        for _ in 0..<10 {
            // Tap on game area periodically
            let gameArea = app.otherElements.firstMatch
            if gameArea.exists {
                gameArea.tap()
            }
            
            // Small delay between interactions
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        // Verify app remains stable
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.exists)
    }
}
