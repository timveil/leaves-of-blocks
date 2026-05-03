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

        // Wait for home screen to be ready
        let startButton = app.buttons["start_game_button"]
        _ = startButton.waitForExistence(timeout: 3)
    }

    @MainActor
    override func tearDownWithError() throws {
        if let app, app.state != .notRunning {
            app.terminate()
        }
        app = nil
    }

    // MARK: - Game Grid Helper

    @MainActor
    private func waitForGameGrid(timeout: TimeInterval = 5) -> Bool {
        let spriteKitGrid = app.otherElements["spritekit_game_grid"]
        let swiftUIGrid = app.otherElements["game_grid"]
        return spriteKitGrid.waitForExistence(timeout: timeout) ||
               swiftUIGrid.waitForExistence(timeout: timeout)
    }

    // MARK: - Menu Navigation Helpers

    @MainActor
    private func openMenu() {
        let menuButton = app.buttons["menu_button"]
        XCTAssertTrue(menuButton.waitForExistence(timeout: 2), "Menu button should exist")
        // SwiftUI toolbar `Menu` returns an invalid AX hit point on iOS 26,
        // so tap the element's center coordinate rather than via .tap().
        menuButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    @MainActor
    private func navigateViaMenu(to accessibilityId: String) {
        openMenu()
        let button = app.buttons[accessibilityId]
        XCTAssertTrue(button.waitForExistence(timeout: 2), "\(accessibilityId) should exist in menu")
        button.tap()
        // Wait for the menu to dismiss before the next interaction.
        _ = button.waitForNonExistence(timeout: 2)
    }

    @MainActor
    private func navigateHome() {
        navigateViaMenu(to: "home_button")
        let startButton = app.buttons["start_game_button"]
        _ = startButton.waitForExistence(timeout: 3)
    }

    // MARK: - Screenshot Tests

    @MainActor
    func testCaptureScreenshots() throws {
        captureHomeScreen()
        captureGameplayScreens()
        captureGameHistoryScreen()
    }

    @MainActor
    private func captureHomeScreen() {
        let startButton = app.buttons["start_game_button"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5), "Home screen should be visible")

        sleep(2)

        takeScreenshot(named: "01_HomeScreen")
    }

    @MainActor
    private func captureHowToPlayScreen() {
        navigateViaMenu(to: "how_to_play_button")

        sleep(2)

        takeScreenshot(named: "02_HowToPlay")

        navigateHome()
    }

    @MainActor
    private func captureGameplayScreens() {
        captureGameplay(screenshotName: "02_Gameplay")
    }

    @MainActor
    private func captureGameplay(screenshotName: String) {
        let startButton = app.buttons["start_game_button"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 3), "Start game button should exist")
        startButton.tap()

        XCTAssertTrue(waitForGameGrid(), "Game grid should appear")

        takeScreenshot(named: screenshotName)

        navigateHome()
    }

    @MainActor
    private func captureGameHistoryScreen() {
        navigateViaMenu(to: "history_button")

        sleep(3)

        takeScreenshot(named: "03_GameHistory")

        let firstGameButton = app.buttons["game_history_button_0"]
        if firstGameButton.waitForExistence(timeout: 10) {
            firstGameButton.tap()

            sleep(3)

            takeScreenshot(named: "04_GameDetail")
        }

        navigateHome()
    }

    @MainActor
    private func captureAboutScreen() {
        navigateViaMenu(to: "about_button")

        sleep(2)

        takeScreenshot(named: "06_About")

        navigateHome()
    }
    
    // MARK: - Gameplay Tests

    @MainActor
    func testStartNewGame() throws {
        let startButton = app.buttons["start_game_button"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2), "Start button should exist")
        startButton.tap()

        XCTAssertTrue(waitForGameGrid(timeout: 5), "Game grid should appear")

        let scoreDisplay = app.staticTexts["score_display"]
        XCTAssertTrue(scoreDisplay.waitForExistence(timeout: 2), "Score display should exist")

        let blockContainer = app.otherElements["block_container"]
        XCTAssertTrue(blockContainer.exists, "Block container should exist")
    }

    @MainActor
    func testDragAndDropBlock() throws {
        let startButton = app.buttons["start_game_button"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2))
        startButton.tap()

        XCTAssertTrue(waitForGameGrid(timeout: 5))

        let gridElement = app.otherElements["spritekit_game_grid"].exists
            ? app.otherElements["spritekit_game_grid"]
            : app.otherElements["game_grid"]

        // The holding area mounts after the grid; wait for the container
        // before querying its descendants.
        let blockContainer = app.otherElements["block_container"]
        XCTAssertTrue(blockContainer.waitForExistence(timeout: 5), "Block container should exist after game starts")

        let firstBlock = app.otherElements.matching(identifier: "draggable_block").element(boundBy: 0)
        XCTAssertTrue(firstBlock.waitForExistence(timeout: 5), "First draggable block should appear")

        let startCoordinate = firstBlock.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let endCoordinate = gridElement.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))

        startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)

        let scoreDisplay = app.staticTexts["score_display"]
        XCTAssertTrue(scoreDisplay.waitForExistence(timeout: 2), "Score display should exist")
        let scoreText = scoreDisplay.label
        let score = Int(scoreText.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())
        XCTAssertNotNil(score, "Score display should contain a parseable integer; got '\(scoreText)'")
        XCTAssertGreaterThan(score ?? 0, 0, "Score should increase after placing a block")
    }

    @MainActor
    func testNavigationFlow() throws {
        // How to Play (via slide-down menu)
        navigateViaMenu(to: "how_to_play_button")
        navigateHome()

        // History (via score display on home screen)
        let historyButton = app.buttons["history_button"]
        if historyButton.waitForExistence(timeout: 2) {
            historyButton.tap()
            // Wait for the history button to dismiss (we navigated away from home).
            _ = historyButton.waitForNonExistence(timeout: 2)
            navigateHome()
        }

        // About (via slide-down menu)
        navigateViaMenu(to: "about_button")
        navigateHome()

        let startButton = app.buttons["start_game_button"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2), "Should be back on home screen")
    }

    @MainActor
    func testDifficultySelection() throws {
        let startButton = app.buttons["start_game_button"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2), "Start game button should exist")
        XCTAssertTrue(startButton.isEnabled, "Start game button should be enabled")

        startButton.tap()

        XCTAssertTrue(waitForGameGrid(timeout: 5), "Game grid should appear after starting game")
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