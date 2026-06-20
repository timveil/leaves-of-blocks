//
//  LeavesOfBlocksUITests.swift
//  LeavesOfBlocksUITests
//
//  Created by Tim Veil on 8/1/25.
//

import XCTest

final class LeavesOfBlocksUITests: XCTestCase {

    var app: XCUIApplication!

    /// Default timeout for `waitForExistence` / `waitForNonExistence`.
    ///
    /// The suite previously sprinkled 2 / 3 / 5-second values across methods
    /// with no documented rationale; consolidating behind one constant kept
    /// intent uniform. 5s was too tight for the first cold-simulator grid
    /// wait on CI's macos-15-arm64 runners (`testDifficultySelection` failed
    /// in run 25997441219), so it was bumped to 10s. Then iOS 26.5 / macOS
    /// 15.7.4 stretched the cold-sim first-launch + SpriteKit-scene-mount
    /// path past 10s as well, failing the same test in run 26004869474 —
    /// hence 20s. Later tests (warmed simulator) typically resolve waits in
    /// 1–2s, so the extra headroom only costs time on actual failures.
    private let defaultTimeout: TimeInterval = 20

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
        _ = startButton.waitForExistence(timeout: defaultTimeout)
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
    private func waitForGameGrid(timeout: TimeInterval = 20) -> Bool {
        // The `spritekit_game_grid` element is a `SpriteView`, whose
        // accessibility element can lag behind the actual board on cold CI
        // simulators even after the game has started — the long-standing source
        // of `testDifficultySelection` / start-game flakiness (timeout bumped
        // 5 → 10 → 20 and it still flaked). The SwiftUI holding-area container
        // (`block_container`) appears as soon as the game starts and is a far
        // more reliable signal, so accept whichever shows first. Poll both
        // within one bounded window rather than waiting the full timeout on the
        // grid and only then checking the fallback.
        let grid = app.otherElements["spritekit_game_grid"]
        let holdingArea = app.otherElements["block_container"]
        let deadline = Date(timeIntervalSinceNow: timeout)
        while true {
            if grid.exists || holdingArea.exists { return true }
            let remaining = deadline.timeIntervalSinceNow
            if remaining <= 0 { return false }
            // Brief poll tick, clamped to the time left so we never overshoot
            // the deadline; returns straight away if the grid shows during it.
            if grid.waitForExistence(timeout: min(0.5, remaining)) { return true }
        }
    }

    // MARK: - Menu Navigation Helpers

    @MainActor
    private func openMenu() {
        let menuButton = app.buttons["menu_button"]
        XCTAssertTrue(menuButton.waitForExistence(timeout: defaultTimeout), "Menu button should exist")
        // Workaround: SwiftUI toolbar `Menu` (the `Menu { ... } label: { ... }`
        // form) returns an invalid accessibility hit point on iOS 26.0–26.x,
        // so XCUIElement.tap() lands outside the element and the menu never
        // opens. Tapping the element's center coordinate sidesteps the
        // bad hit point.
        //
        // **To remove this workaround:** When the iOS deployment target
        // moves past whatever release ships Apple's fix (no FB has been
        // filed yet — worth filing if this lingers), try swapping back to
        // `menuButton.tap()` and confirm the menu opens locally. If it
        // does, drop the coordinate dance and this comment.
        menuButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    /// Opens the slide-down menu and returns once `element` is visible, retrying
    /// the open up to `attempts` times. A single coordinate tap (see `openMenu`)
    /// is occasionally swallowed on a cold simulator, leaving the menu closed so
    /// the item never appears — the historical source of `testNavigationFlow`
    /// flakiness. We only re-tap when the item is still absent (menu closed), so
    /// a successful open is never toggled back shut. Returns `false` if the item
    /// never appears across all attempts.
    @MainActor
    private func openMenu(untilVisible element: XCUIElement, attempts: Int = 3) -> Bool {
        // Per-attempt wait is half the default: long enough for the menu to
        // render once the tap lands, short enough that a swallowed tap retries
        // promptly instead of burning the full timeout. Total worst case stays
        // bounded at attempts × (defaultTimeout / 2).
        for _ in 0..<attempts {
            openMenu()
            if element.waitForExistence(timeout: defaultTimeout / 2) {
                return true
            }
        }
        return false
    }

    @MainActor
    private func navigateViaMenu(to accessibilityId: String) {
        let button = app.buttons[accessibilityId]
        XCTAssertTrue(openMenu(untilVisible: button), "\(accessibilityId) should exist in menu")
        button.tap()
        // Wait for the menu to dismiss before the next interaction.
        _ = button.waitForNonExistence(timeout: defaultTimeout)
    }

    @MainActor
    private func navigateHome() {
        navigateViaMenu(to: "home_button")
        let startButton = app.buttons["start_game_button"]
        _ = startButton.waitForExistence(timeout: defaultTimeout)
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
        XCTAssertTrue(startButton.waitForExistence(timeout: defaultTimeout), "Home screen should be visible")
        XCTAssertTrue(startButton.isHittable, "Start button should be hittable (animations finished)")

        takeScreenshot(named: "01_HomeScreen")
    }

    @MainActor
    private func captureHowToPlayScreen() {
        navigateViaMenu(to: "how_to_play_button")

        let screen = app.staticTexts["how_to_play_screen"]
        XCTAssertTrue(screen.waitForExistence(timeout: defaultTimeout), "How To Play screen should appear")

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
        XCTAssertTrue(startButton.waitForExistence(timeout: defaultTimeout), "Start game button should exist")
        startButton.tap()

        XCTAssertTrue(waitForGameGrid(), "Game grid should appear")

        takeScreenshot(named: screenshotName)

        navigateHome()
    }

    @MainActor
    private func captureGameHistoryScreen() {
        navigateViaMenu(to: "history_button")

        // History rows or the "no history" empty state mount inside this
        // window; waiting for the first row covers the populated path.
        let firstGameButton = app.buttons["game_history_button_0"]
        _ = firstGameButton.waitForExistence(timeout: defaultTimeout)

        takeScreenshot(named: "03_GameHistory")

        if firstGameButton.exists {
            firstGameButton.tap()

            let detailScreen = app.staticTexts["summary_screen"]
            XCTAssertTrue(detailScreen.waitForExistence(timeout: defaultTimeout), "Game detail screen should appear")

            takeScreenshot(named: "04_GameDetail")
        }

        navigateHome()
    }

    @MainActor
    private func captureAboutScreen() {
        navigateViaMenu(to: "about_button")

        let screen = app.staticTexts["about_screen"]
        XCTAssertTrue(screen.waitForExistence(timeout: defaultTimeout), "About screen should appear")

        takeScreenshot(named: "06_About")

        navigateHome()
    }
    
    // MARK: - Gameplay Tests

    @MainActor
    func testStartNewGame() throws {
        let startButton = app.buttons["start_game_button"]
        XCTAssertTrue(startButton.waitForExistence(timeout: defaultTimeout), "Start button should exist")
        startButton.tap()

        XCTAssertTrue(waitForGameGrid(timeout: defaultTimeout), "Game grid should appear")

        let scoreDisplay = app.staticTexts["score_display"]
        XCTAssertTrue(scoreDisplay.waitForExistence(timeout: defaultTimeout), "Score display should exist")

        let blockContainer = app.otherElements["block_container"]
        XCTAssertTrue(blockContainer.exists, "Block container should exist")
    }

    @MainActor
    func testDragAndDropBlock() throws {
        let startButton = app.buttons["start_game_button"]
        XCTAssertTrue(startButton.waitForExistence(timeout: defaultTimeout))
        startButton.tap()

        XCTAssertTrue(waitForGameGrid(timeout: defaultTimeout))

        let gridElement = app.otherElements["spritekit_game_grid"]

        // The holding area mounts after the grid; wait for the container
        // before querying its descendants.
        let blockContainer = app.otherElements["block_container"]
        XCTAssertTrue(blockContainer.waitForExistence(timeout: defaultTimeout), "Block container should exist after game starts")

        let firstBlock = app.otherElements.matching(identifier: "draggable_block").element(boundBy: 0)
        XCTAssertTrue(firstBlock.waitForExistence(timeout: defaultTimeout), "First draggable block should appear")

        let startCoordinate = firstBlock.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let endCoordinate = gridElement.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))

        startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)

        let scoreDisplay = app.staticTexts["score_display"]
        XCTAssertTrue(scoreDisplay.waitForExistence(timeout: defaultTimeout), "Score display should exist")
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
        if historyButton.waitForExistence(timeout: defaultTimeout) {
            historyButton.tap()
            // Wait for the history button to dismiss (we navigated away from home).
            _ = historyButton.waitForNonExistence(timeout: defaultTimeout)
            navigateHome()
        }

        // About (via slide-down menu)
        navigateViaMenu(to: "about_button")
        navigateHome()

        let startButton = app.buttons["start_game_button"]
        XCTAssertTrue(startButton.waitForExistence(timeout: defaultTimeout), "Should be back on home screen")
    }

    @MainActor
    func testDifficultySelection() throws {
        let startButton = app.buttons["start_game_button"]
        XCTAssertTrue(startButton.waitForExistence(timeout: defaultTimeout), "Start game button should exist")
        XCTAssertTrue(startButton.isEnabled, "Start game button should be enabled")

        startButton.tap()

        XCTAssertTrue(waitForGameGrid(timeout: defaultTimeout), "Game grid should appear after starting game")
    }

    @MainActor
    func testViewBoardPeekAfterGameOver() throws {
        // Relaunch straight into a forced game-over (an unplaceable board) so we
        // can exercise the game-over overlay without playing a full game.
        // Append rather than replace so the flags from setUp are preserved.
        app.terminate()
        app.launchArguments.append("-force-game-over")
        app.launch()

        let startButton = app.buttons["start_game_button"]
        XCTAssertTrue(startButton.waitForExistence(timeout: defaultTimeout), "Start game button should exist")
        startButton.tap()

        // The game-over overlay appears with the View Board affordance.
        let viewBoard = app.buttons["game_over_view_board_button"]
        XCTAssertTrue(viewBoard.waitForExistence(timeout: defaultTimeout), "View Board button should appear at game-over")
        let newGame = app.buttons["game_over_new_game_button"]
        XCTAssertTrue(newGame.exists, "Results overlay should be showing initially")

        // Tap View Board → results overlay hides; board + Show Results appear.
        viewBoard.tap()
        let showResults = app.buttons["game_over_show_results_button"]
        XCTAssertTrue(showResults.waitForExistence(timeout: defaultTimeout), "Show Results button should appear while peeking")
        XCTAssertTrue(waitForGameGrid(timeout: defaultTimeout), "Final board grid should be visible while peeking")
        // Overlay removal is animated, so wait for it rather than asserting now.
        XCTAssertTrue(newGame.waitForNonExistence(timeout: defaultTimeout), "Results overlay should be hidden while peeking the board")

        // Tap Show Results → overlay returns; peek button goes away.
        showResults.tap()
        XCTAssertTrue(newGame.waitForExistence(timeout: defaultTimeout), "Results overlay should return")
        XCTAssertTrue(showResults.waitForNonExistence(timeout: defaultTimeout), "Show Results button should be gone once results return")
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