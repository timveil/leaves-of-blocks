//
//  LeavesOfBlocksUITestsLaunchTests.swift
//  Leaves of BlocksUITests
//
//  Created by Tim Veil on 7/25/25.
//

import XCTest

// MARK: - App Launch and Screenshot Tests

final class LeavesOfBlocksUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify app launches successfully
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 10))

        // Take screenshot of launch state
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchScreenElements() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for launch to complete
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 10))
        
        // Verify essential elements are present
        XCTAssertTrue(app.buttons["Easy"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Moderate"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Hard"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["About"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["History"].waitForExistence(timeout: 2))
        
        // Take screenshot of home screen with all elements
        let homeScreenshot = XCTAttachment(screenshot: app.screenshot())
        homeScreenshot.name = "Home Screen - All Elements"
        homeScreenshot.lifetime = .keepAlways
        add(homeScreenshot)
    }
    
    @MainActor
    func testGameScreenLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to game screen
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 10))
        app.buttons["Easy"].tap()
        
        // Wait for game to load
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.waitForExistence(timeout: 5))
        
        // Take screenshot of game screen
        let gameScreenshot = XCTAttachment(screenshot: app.screenshot())
        gameScreenshot.name = "Game Screen - Initial State"
        gameScreenshot.lifetime = .keepAlways
        add(gameScreenshot)
    }
    
    @MainActor
    func testAboutScreenLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to About screen
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 10))
        app.buttons["About"].tap()
        
        // Wait for About screen to load
        XCTAssertTrue(app.staticTexts["About"].waitForExistence(timeout: 5))
        
        // Take screenshot of About screen
        let aboutScreenshot = XCTAttachment(screenshot: app.screenshot())
        aboutScreenshot.name = "About Screen"
        aboutScreenshot.lifetime = .keepAlways
        add(aboutScreenshot)
    }
    
    @MainActor
    func testHistoryScreenLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to History screen
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 10))
        app.buttons["History"].tap()
        
        // Wait for History screen to load
        XCTAssertTrue(app.staticTexts["Game History"].waitForExistence(timeout: 5) ||
                     app.staticTexts["History"].waitForExistence(timeout: 5))
        
        // Take screenshot of History screen
        let historyScreenshot = XCTAttachment(screenshot: app.screenshot())
        historyScreenshot.name = "History Screen"
        historyScreenshot.lifetime = .keepAlways
        add(historyScreenshot)
    }
    
    @MainActor
    func testLaunchPerformanceMetrics() throws {
        let app = XCUIApplication()
        
        // Measure launch performance
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
            
            // Wait for app to be fully loaded
            _ = app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 10)
            
            app.terminate()
        }
    }
    
    @MainActor
    func testLaunchInDifferentOrientations() throws {
        let app = XCUIApplication()
        
        // Test launch in portrait
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 10))
        
        let portraitScreenshot = XCTAttachment(screenshot: app.screenshot())
        portraitScreenshot.name = "Launch - Portrait Orientation"
        portraitScreenshot.lifetime = .keepAlways
        add(portraitScreenshot)
        
        // Test rotation to landscape
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        
        let landscapeScreenshot = XCTAttachment(screenshot: app.screenshot())
        landscapeScreenshot.name = "Launch - Landscape Orientation"
        landscapeScreenshot.lifetime = .keepAlways
        add(landscapeScreenshot)
        
        // Reset to portrait
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 5))
        
        app.terminate()
    }
    
    @MainActor
    func testLaunchStability() throws {
        let app = XCUIApplication()
        
        // Test multiple launch/terminate cycles
        for i in 0..<3 {
            app.launch()
            
            // Verify successful launch
            XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 10))
            
            // Interact briefly with the app
            if app.buttons["Easy"].exists {
                app.buttons["Easy"].tap()
                _ = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.waitForExistence(timeout: 3)
            }
            
            if i == 2 {
                // Take final screenshot
                let finalScreenshot = XCTAttachment(screenshot: app.screenshot())
                finalScreenshot.name = "Launch Stability - Final State"
                finalScreenshot.lifetime = .keepAlways
                add(finalScreenshot)
            }
            
            app.terminate()
        }
    }
}

// MARK: - Visual Regression Tests

final class VisualRegressionTests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    @MainActor
    func testHomeScreenVisualConsistency() throws {
        let app = XCUIApplication()
        app.launch()
        
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 10))
        
        // Take screenshot for visual regression testing
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Visual Regression - Home Screen"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        
        // Verify key visual elements are in expected positions
        let titleText = app.staticTexts["🍂 Leaves of Blocks"]
        XCTAssertTrue(titleText.exists)
        
        let easyButton = app.buttons["Easy"]
        let moderateButton = app.buttons["Moderate"]
        let hardButton = app.buttons["Hard"]
        
        XCTAssertTrue(easyButton.exists)
        XCTAssertTrue(moderateButton.exists)
        XCTAssertTrue(hardButton.exists)
        
        // Verify buttons are properly positioned (basic layout check)
        XCTAssertTrue(easyButton.isHittable)
        XCTAssertTrue(moderateButton.isHittable)
        XCTAssertTrue(hardButton.isHittable)
    }
    
    @MainActor
    func testGameScreenVisualConsistency() throws {
        let app = XCUIApplication()
        app.launch()
        
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 10))
        app.buttons["Easy"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch.waitForExistence(timeout: 5))
        
        // Take screenshot for visual regression testing
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Visual Regression - Game Screen"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        
        // Verify game elements are properly positioned
        let scoreElement = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+")).firstMatch
        XCTAssertTrue(scoreElement.exists)
        
        if app.buttons["house.fill"].exists {
            XCTAssertTrue(app.buttons["house.fill"].isHittable)
        }
        
        if app.buttons["arrow.clockwise"].exists {
            XCTAssertTrue(app.buttons["arrow.clockwise"].isHittable)
        }
    }
    
    @MainActor
    func testDarkModeCompatibility() throws {
        // Note: This would require specific dark mode testing setup
        let app = XCUIApplication()
        app.launch()
        
        XCTAssertTrue(app.staticTexts["🍂 Leaves of Blocks"].waitForExistence(timeout: 10))
        
        // Take screenshot in current appearance mode
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Appearance Mode Test"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        
        // Verify all elements are visible and accessible regardless of appearance mode
        XCTAssertTrue(app.buttons["Easy"].exists)
        XCTAssertTrue(app.buttons["Moderate"].exists)
        XCTAssertTrue(app.buttons["Hard"].exists)
        XCTAssertTrue(app.buttons["About"].exists)
        XCTAssertTrue(app.buttons["History"].exists)
    }
}
