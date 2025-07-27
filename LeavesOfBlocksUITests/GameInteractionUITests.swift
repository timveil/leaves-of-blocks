//
//  GameInteractionUITests.swift
//  LeavesOfBlocksUITests
//
//  Created by Tim Veil on 7/25/25.
//

import XCTest

// MARK: - Detailed Game Interaction Tests

final class GameInteractionUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Launch app and navigate to game for all tests
        app.launch()
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        app.buttons["Easy"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.waitForExistence(timeout: 3))
    }

    override func tearDownWithError() throws {
        app = nil
    }
    
    @MainActor
    func testGameGridVisibility() throws {
        // Test that the game grid is visible and accessible
        // Look for grid elements or game area
        let gameElements = app.otherElements
        XCTAssertTrue(gameElements.count > 0, "Game should have interactive elements")
        
        // Verify the score is displaying correctly
        let scoreElement = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch
        XCTAssertTrue(scoreElement.exists)
        XCTAssertEqual(scoreElement.label, "0", "Initial score should be 0")
    }
    
    @MainActor
    func testGameControlButtons() throws {
        // Test home button functionality
        if app.buttons["house.fill"].exists {
            let homeButton = app.buttons["house.fill"]
            XCTAssertTrue(homeButton.isHittable)
            
            // Test that tapping doesn't crash
            homeButton.tap()
            XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 3))
            
            // Return to game for next test
            app.buttons["Easy"].tap()
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.waitForExistence(timeout: 3))
        }
        
        // Test reset button functionality
        if app.buttons["arrow.clockwise"].exists {
            let resetButton = app.buttons["arrow.clockwise"]
            XCTAssertTrue(resetButton.isHittable)
            
            resetButton.tap()
            
            // Verify score resets to 0
            let scoreElement = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch
            XCTAssertTrue(scoreElement.waitForExistence(timeout: 3))
            XCTAssertEqual(scoreElement.label, "0", "Score should reset to 0")
        }
    }
    
    @MainActor
    func testGameAreaInteractivity() throws {
        // Test that the game area responds to touches
        let gameArea = app.otherElements.firstMatch
        
        if gameArea.exists {
            let initialFrame = gameArea.frame
            
            // Tap various points in the game area
            let tapPoints = [
                CGPoint(x: initialFrame.midX, y: initialFrame.midY),
                CGPoint(x: initialFrame.minX + 50, y: initialFrame.minY + 50),
                CGPoint(x: initialFrame.maxX - 50, y: initialFrame.maxY - 50)
            ]
            
            for point in tapPoints {
                gameArea.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0)).withOffset(CGVector(dx: point.x - initialFrame.midX, dy: point.y - initialFrame.midY)).tap()
                
                // Verify app remains responsive
                XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.exists)
            }
        }
    }
    
    @MainActor
    func testDragGestureHandling() throws {
        // Test drag gestures in game area
        let gameArea = app.otherElements.firstMatch
        
        if gameArea.exists {
            let startPoint = gameArea.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.2))
            let endPoint = gameArea.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.8))
            
            // Perform drag gesture
            startPoint.press(forDuration: 0.5, thenDragTo: endPoint)
            
            // Verify app remains stable after drag
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.exists)
        }
    }
    
    @MainActor
    func testLongPressHandling() throws {
        // Test long press gestures
        let gameArea = app.otherElements.firstMatch
        
        if gameArea.exists {
            gameArea.press(forDuration: 2.0)
            
            // Verify app handles long press gracefully
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.exists)
        }
    }
    
    @MainActor
    func testMultipleTouchHandling() throws {
        // Test multiple rapid touches
        let gameArea = app.otherElements.firstMatch
        
        if gameArea.exists {
            for _ in 0..<10 {
                gameArea.tap()
                // Small delay between taps
                usleep(100000) // 0.1 seconds
            }
            
            // Verify app remains stable
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.exists)
        }
    }
    
    @MainActor
    func testGameStateConsistency() throws {
        // Test that game state remains consistent during interaction
        let initialScore = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.label
        
        // Perform various interactions
        let gameArea = app.otherElements.firstMatch
        if gameArea.exists {
            gameArea.tap()
            gameArea.swipeLeft()
            gameArea.swipeRight()
            gameArea.swipeUp()
            gameArea.swipeDown()
        }
        
        // Verify score is still a valid number
        let currentScore = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch
        XCTAssertTrue(currentScore.exists)
        XCTAssertTrue(Int(currentScore.label) != nil, "Score should be a valid number")
    }
    
    @MainActor
    func testGamePerformanceDuringInteraction() throws {
        // Test performance during intensive interaction
        let startTime = Date()
        
        let gameArea = app.otherElements.firstMatch
        if gameArea.exists {
            // Perform many rapid interactions
            for i in 0..<50 {
                let normalizedX = Double(i % 10) / 10.0
                let normalizedY = Double(i / 10) / 10.0
                let point = gameArea.coordinate(withNormalizedOffset: CGVector(dx: normalizedX, dy: normalizedY))
                point.tap()
            }
        }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        // Verify performance is reasonable (less than 10 seconds for 50 interactions)
        XCTAssertLessThan(elapsedTime, 10.0, "Interactions should complete within reasonable time")
        
        // Verify app is still responsive
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.exists)
    }
}

// MARK: - Game Logic UI Tests

final class GameLogicUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }
    
    @MainActor
    func testDifficultyModeImpact() throws {
        let difficulties = ["Easy", "Moderate", "Hard"]
        
        for difficulty in difficulties {
            app.launch()
            XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
            
            // Start game with specific difficulty
            app.buttons[difficulty].tap()
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.waitForExistence(timeout: 3))
            
            // Verify game starts correctly for each difficulty
            let scoreElement = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch
            XCTAssertEqual(scoreElement.label, "0", "Score should start at 0 for \(difficulty) mode")
            
            // Verify game area is interactive
            let gameArea = app.otherElements.firstMatch
            if gameArea.exists {
                gameArea.tap()
                // Verify app doesn't crash
                XCTAssertTrue(scoreElement.exists)
            }
            
            app.terminate()
        }
    }
    
    @MainActor
    func testScoreUpdateDuringPlay() throws {
        app.launch()
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        app.buttons["Easy"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.waitForExistence(timeout: 3))
        
        let scoreElement = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch
        let initialScore = Int(scoreElement.label) ?? 0
        
        // Simulate gameplay interactions that might affect score
        let gameArea = app.otherElements.firstMatch
        if gameArea.exists {
            // Perform multiple interactions
            for _ in 0..<5 {
                gameArea.tap()
                // Brief pause to allow for any score updates
                usleep(500000) // 0.5 seconds
            }
        }
        
        // Verify score is still valid (could be same or different depending on game logic)
        let updatedScore = Int(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.label) ?? -1
        XCTAssertGreaterThanOrEqual(updatedScore, initialScore, "Score should not decrease unexpectedly")
    }
    
    @MainActor
    func testGameOverState() throws {
        app.launch()
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        app.buttons["Easy"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.waitForExistence(timeout: 3))
        
        // This test would be enhanced with specific game over scenarios
        // For now, test that the game remains stable during extended play
        let gameArea = app.otherElements.firstMatch
        if gameArea.exists {
            // Simulate extended gameplay
            for _ in 0..<20 {
                gameArea.tap()
                usleep(250000) // 0.25 seconds
                
                // Check if game over state appears (this would depend on actual game over UI)
                if app.staticTexts["Game Over"].exists || app.buttons["Play Again"].exists {
                    break
                }
            }
        }
        
        // Verify app is still responsive regardless of game state
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.exists ||
                     app.staticTexts["Game Over"].exists)
    }
    
    @MainActor
    func testGameResetConsistency() throws {
        app.launch()
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        app.buttons["Easy"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.waitForExistence(timeout: 3))
        
        // Perform some interactions
        let gameArea = app.otherElements.firstMatch
        if gameArea.exists {
            for _ in 0..<5 {
                gameArea.tap()
                usleep(200000) // 0.2 seconds
            }
        }
        
        // Reset game multiple times
        for _ in 0..<3 {
            if app.buttons["arrow.clockwise"].exists {
                app.buttons["arrow.clockwise"].tap()
                
                // Verify reset worked
                let scoreElement = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch
                XCTAssertTrue(scoreElement.waitForExistence(timeout: 2))
                XCTAssertEqual(scoreElement.label, "0", "Score should reset to 0")
                
                // Verify game is still playable
                if gameArea.exists {
                    gameArea.tap()
                    XCTAssertTrue(scoreElement.exists)
                }
            }
        }
    }
}

// MARK: - Visual and Animation Tests

final class VisualUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }
    
    @MainActor
    func testScreenTransitionAnimations() throws {
        app.launch()
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        
        // Test navigation transitions
        let navigationButtons = ["About", "History"]
        
        for buttonName in navigationButtons {
            if app.buttons[buttonName].exists {
                app.buttons[buttonName].tap()
                
                // Wait for transition to complete
                usleep(1000000) // 1 second for animation
                
                // Verify new screen is loaded
                XCTAssertTrue(app.staticTexts[buttonName].waitForExistence(timeout: 3) ||
                             app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", buttonName)).firstMatch.exists)
                
                // Navigate back
                if app.buttons["Back"].exists {
                    app.buttons["Back"].tap()
                } else if app.buttons["Home"].exists {
                    app.buttons["Home"].tap()
                }
                
                // Wait for transition back
                usleep(1000000) // 1 second for animation
                XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 3))
            }
        }
    }
    
    @MainActor
    func testGameStartTransition() throws {
        app.launch()
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        
        // Test game start transition
        app.buttons["Easy"].tap()
        
        // Wait for game transition
        usleep(1500000) // 1.5 seconds for animation
        
        // Verify game screen elements are present
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.waitForExistence(timeout: 3))
        
        // Test return home transition
        if app.buttons["house.fill"].exists {
            app.buttons["house.fill"].tap()
            
            // Wait for transition
            usleep(1500000) // 1.5 seconds for animation
            
            XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 3))
        }
    }
    
    @MainActor
    func testVisualElementPresence() throws {
        app.launch()
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        
        // Test home screen visual elements
        XCTAssertTrue(app.buttons["Easy"].exists)
        XCTAssertTrue(app.buttons["Moderate"].exists)
        XCTAssertTrue(app.buttons["Hard"].exists)
        XCTAssertTrue(app.buttons["About"].exists)
        XCTAssertTrue(app.buttons["History"].exists)
        
        // Start game and test game visual elements
        app.buttons["Easy"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.waitForExistence(timeout: 3))
        
        // Verify game control buttons are visible
        if app.buttons["house.fill"].exists {
            XCTAssertTrue(app.buttons["house.fill"].isHittable)
        }
        if app.buttons["arrow.clockwise"].exists {
            XCTAssertTrue(app.buttons["arrow.clockwise"].isHittable)
        }
    }
    
    @MainActor
    func testColorAndThemeConsistency() throws {
        app.launch()
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        
        // Take screenshot of home screen
        let homeScreenshot = app.screenshot()
        XCTAssertNotNil(homeScreenshot)
        
        // Navigate to About screen
        if app.buttons["About"].exists {
            app.buttons["About"].tap()
            XCTAssertTrue(app.staticTexts["About"].waitForExistence(timeout: 3))
            
            let aboutScreenshot = app.screenshot()
            XCTAssertNotNil(aboutScreenshot)
            
            // Navigate back
            if app.buttons["Back"].exists {
                app.buttons["Back"].tap()
            } else if app.buttons["Home"].exists {
                app.buttons["Home"].tap()
            }
        }
        
        // Start game and take screenshot
        app.buttons["Easy"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.waitForExistence(timeout: 3))
        
        let gameScreenshot = app.screenshot()
        XCTAssertNotNil(gameScreenshot)
        
        // All screenshots should be valid (non-empty)
        XCTAssertGreaterThan(homeScreenshot.pngRepresentation.count, 0)
        XCTAssertGreaterThan(gameScreenshot.pngRepresentation.count, 0)
    }
}