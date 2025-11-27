//
//  LeavesOfBlocksUITests.swift
//  LeavesOfBlocksUITests
//
//  Created by Tim Veil on 8/1/25.
//

import XCTest

final class LeavesOfBlocksUITests: XCTestCase {

    var app: XCUIApplication!

    /// Check if running in CI environment
    private var isCI: Bool {
        ProcessInfo.processInfo.environment["CI"] != nil
    }

    @MainActor
    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()

        // Launch arguments for testing
        var launchArgs = ["-ui-testing"]
        if !isCI {
            launchArgs.append("-screenshot-mode")
        }
        app.launchArguments = launchArgs

        // Setup for Fastlane snapshot (only when not in CI)
        if !isCI {
            setupSnapshot(app)
        }

        app.launch()

        // Wait for home screen to be ready (replaces arbitrary sleep)
        let easyButton = app.buttons["easy_button"]
        _ = easyButton.waitForExistence(timeout: 3)
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Screenshot Tests
    
    @MainActor
    func testCaptureScreenshots() throws {
        // Take screenshots for App Store
        captureHomeScreen()
        captureGameplayScreens()
        captureGameHistoryScreen()
    }
    
    @MainActor
    private func captureHomeScreen() {
        // Wait for home screen to load by looking for difficulty buttons or score display
        let easyButton = app.buttons["easy_button"]
        let homeScreenIdentifier = app.staticTexts["home_screen_identifier"]
        
        // Try multiple ways to verify we're on home screen
        let isHomeLoaded = easyButton.waitForExistence(timeout: 5) || 
                          homeScreenIdentifier.waitForExistence(timeout: 5) ||
                          app.buttons["start_game_button"].waitForExistence(timeout: 5)
        
        XCTAssertTrue(isHomeLoaded, "Home screen should be visible")
        
        // Wait a bit longer for sample data to be created and UI to update
        sleep(2)
        
        takeScreenshot(named: "01_HomeScreen")
    }
    
    @MainActor
    private func captureHowToPlayScreen() {
        // Navigate to How to Play
        let howToPlayButton = app.buttons["how_to_play_button"]
        XCTAssertTrue(howToPlayButton.waitForExistence(timeout: 3), "How to Play button should exist")
        howToPlayButton.tap()
        
        // Wait for screen to load
        sleep(2)
        
        takeScreenshot(named: "02_HowToPlay")
        
        // Go back
        let homeButton = app.buttons["home_button"]
        if homeButton.exists {
            homeButton.tap()
        } else {
            // Fallback: try back navigation
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }
    
    @MainActor
    private func captureGameplayScreens() {
        // Capture Easy difficulty only (all difficulties show the same screen)
        captureGameplay(difficulty: "easy_button", screenshotName: "02_Gameplay")
    }
    
    @MainActor
    private func captureGameplay(difficulty: String, screenshotName: String) {
        // Select difficulty
        let difficultyButton = app.buttons[difficulty]
        XCTAssertTrue(difficultyButton.waitForExistence(timeout: 3), "Difficulty button \(difficulty) should exist")
        difficultyButton.tap()
        
        // Start game
        let startButton = app.buttons["start_game_button"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 3), "Start game button should exist")
        startButton.tap()
        
        // Wait for game board to appear
        let gameGrid = app.otherElements["game_grid"]
        XCTAssertTrue(gameGrid.waitForExistence(timeout: 5), "Game grid should appear")
        
        // Take screenshot
        takeScreenshot(named: screenshotName)
        
        // Go back home
        let homeButton = app.buttons["home_button"]
        if homeButton.exists {
            homeButton.tap()
        } else {
            // Alternative navigation back
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
        
        // Wait to return to home
        let easyButton = app.buttons["easy_button"]
        _ = easyButton.waitForExistence(timeout: 5)
    }
    
    @MainActor
    private func captureGameHistoryScreen() {
        // Navigate to History
        let historyButton = app.buttons["history_button"]
        XCTAssertTrue(historyButton.waitForExistence(timeout: 3), "History button should exist")
        historyButton.tap()
        
        // Wait longer for history screen and data to load
        sleep(3)
        
        // Capture the history list first
        takeScreenshot(named: "03_GameHistory")
        
        // Check if there are any game records to tap on
        let firstGameButton = app.buttons["game_history_button_0"]
        if firstGameButton.waitForExistence(timeout: 10) {
            // Tap on the first game record to see detail
            firstGameButton.tap()
            
            // Wait for detail screen to appear
            sleep(3)
            
            // Capture the game detail screen
            takeScreenshot(named: "04_GameDetail")
            
            // Go back from detail - try multiple methods
            if app.buttons["home_button"].exists {
                app.buttons["home_button"].tap()
            } else if app.navigationBars.buttons.firstMatch.exists {
                app.navigationBars.buttons.firstMatch.tap()
            } else {
                // Try swipe back gesture
                app.swipeRight()
            }
            sleep(1)
        } else {
            // Debug: print all available buttons
            print("DEBUG: Could not find game_history_button_0")
            let allButtons = app.buttons.allElementsBoundByIndex
            for i in 0..<min(5, allButtons.count) {
                print("DEBUG: Button \(i): \(allButtons[i].identifier)")
            }
        }
        
        // Go back to home
        let homeButton = app.buttons["home_button"]
        if homeButton.exists {
            homeButton.tap()
        }
    }
    
    @MainActor
    private func captureAboutScreen() {
        // Navigate to About
        let aboutButton = app.buttons["about_button"]
        XCTAssertTrue(aboutButton.waitForExistence(timeout: 3), "About button should exist")
        aboutButton.tap()
        
        // Wait for about screen
        sleep(2)
        
        takeScreenshot(named: "06_About")
        
        // Go back
        let homeButton = app.buttons["home_button"]
        if homeButton.exists {
            homeButton.tap()
        }
    }
    
    // MARK: - Gameplay Tests
    
    @MainActor
    func testStartNewGame() throws {
        // Select Easy difficulty
        let easyButton = app.buttons["easy_button"]
        XCTAssertTrue(easyButton.waitForExistence(timeout: 2), "Easy button should exist")
        easyButton.tap()

        // Start game
        let startButton = app.buttons["start_game_button"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2), "Start button should exist")
        startButton.tap()

        // Verify game board appears
        let gameGrid = app.otherElements["game_grid"]
        XCTAssertTrue(gameGrid.waitForExistence(timeout: 3), "Game grid should appear")

        // Verify score display
        let scoreDisplay = app.staticTexts["score_display"]
        XCTAssertTrue(scoreDisplay.waitForExistence(timeout: 2), "Score display should exist")

        // Verify block container
        let blockContainer = app.otherElements["block_container"]
        XCTAssertTrue(blockContainer.exists, "Block container should exist")
    }
    
    @MainActor
    func testDragAndDropBlock() throws {
        // Start a game
        let easyButton = app.buttons["easy_button"]
        XCTAssertTrue(easyButton.waitForExistence(timeout: 2))
        easyButton.tap()

        let startButton = app.buttons["start_game_button"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2))
        startButton.tap()

        // Wait for game to load
        let gameGrid = app.otherElements["game_grid"]
        XCTAssertTrue(gameGrid.waitForExistence(timeout: 3))

        // Find first draggable block
        let blockContainer = app.otherElements["block_container"]
        let firstBlock = blockContainer.otherElements.matching(identifier: "draggable_block").element(boundBy: 0)

        if firstBlock.waitForExistence(timeout: 2) {
            // Perform drag from block to grid center
            let startCoordinate = firstBlock.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let endCoordinate = gameGrid.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))

            startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)

            // Wait for score to update (use expectation instead of sleep)
            let scoreDisplay = app.staticTexts["score_display"]
            _ = scoreDisplay.waitForExistence(timeout: 2)
            let scoreText = scoreDisplay.label

            // Extract number from score text
            if let score = Int(scoreText.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                XCTAssertGreaterThan(score, 0, "Score should increase after placing a block")
            }
        }
    }
    
    @MainActor
    func testNavigationFlow() throws {
        // Test navigation through all main screens
        let homeButton = app.buttons["home_button"]
        let easyButton = app.buttons["easy_button"]

        // How to Play
        let howToPlayButton = app.buttons["how_to_play_button"]
        XCTAssertTrue(howToPlayButton.waitForExistence(timeout: 2), "How to Play button should exist")
        howToPlayButton.tap()

        // Wait for navigation, then go back
        if homeButton.waitForExistence(timeout: 2) {
            homeButton.tap()
            _ = easyButton.waitForExistence(timeout: 2)
        }

        // History
        let historyButton = app.buttons["history_button"]
        if historyButton.waitForExistence(timeout: 2) {
            historyButton.tap()
            if homeButton.waitForExistence(timeout: 2) {
                homeButton.tap()
                _ = easyButton.waitForExistence(timeout: 2)
            }
        }

        // About
        let aboutButton = app.buttons["about_button"]
        if aboutButton.waitForExistence(timeout: 2) {
            aboutButton.tap()
            if homeButton.waitForExistence(timeout: 2) {
                homeButton.tap()
            }
        }

        // Verify we can still see home screen elements
        XCTAssertTrue(easyButton.waitForExistence(timeout: 2), "Should be back on home screen")
    }
    
    @MainActor
    func testDifficultySelection() throws {
        // Test all difficulty selections
        let difficulties = ["easy_button", "moderate_button", "hard_button"]
        let startButton = app.buttons["start_game_button"]

        for difficulty in difficulties {
            // Select difficulty
            let difficultyButton = app.buttons[difficulty]
            XCTAssertTrue(difficultyButton.waitForExistence(timeout: 2), "Difficulty button \(difficulty) should exist")
            difficultyButton.tap()

            // Verify start button appears/is enabled
            XCTAssertTrue(startButton.waitForExistence(timeout: 1), "Start button should appear")
            XCTAssertTrue(startButton.isEnabled, "Start button should be enabled")
        }
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func takeScreenshot(named name: String) {
        // Take XCTest screenshot for test results
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        
        // Take Fastlane snapshot
        snapshot(name)
    }
}

// MARK: - Test Helpers

extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }
        
        self.tap()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
        self.typeText(text)
    }
    
    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}