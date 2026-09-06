import XCTest

final class ShellUITests: XCTestCase {
    @MainActor
    func testOnboardingAndExistingNavigationPlacement() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-keihatsu.hasSeenOnboarding", "NO", "-keihatsu.hasEnteredAsGuest", "NO"]
        app.launch()
        XCTAssertTrue(app.buttons["onboarding.next"].waitForExistence(timeout: 10))
        app.buttons["onboarding.next"].tap()
        app.buttons["onboarding.next"].tap()
        XCTAssertTrue(app.buttons["Get Started"].exists)
        app.buttons["onboarding.next"].tap()
        XCTAssertTrue(app.buttons["account.continueAsGuest"].waitForExistence(timeout: 5))
        app.buttons["account.continueAsGuest"].tap()
        XCTAssertTrue(app.navigationBars["Explore"].waitForExistence(timeout: 5))
        for label in ["Home", "Library", "History", "Plugins", "Search"] {
            XCTAssertTrue(app.tabBars.buttons[label].exists, "Missing existing tab: \(label)")
        }
        XCTAssertFalse(app.tabBars.buttons["Profile"].exists)
        XCTAssertFalse(app.tabBars.buttons["Notifications"].exists)
        app.buttons["Notifications"].tap()
        XCTAssertTrue(app.navigationBars["Notifications"].waitForExistence(timeout: 5))
        app.swipeDown()
        if app.navigationBars["Notifications"].exists { app.swipeDown() }
        app.buttons["Account"].tap()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 5))
        app.staticTexts["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        app.terminate()
        app.launchArguments = []
        app.launch()
        XCTAssertTrue(app.navigationBars["Explore"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Library"].tap()
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 5))
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Plugins"].tap()
        app.tabBars.buttons["Search"].tap()
        XCTAssertTrue(app.searchFields["Search across sources"].waitForExistence(timeout: 5))
        // The native search tab collapses the other tabs into the previous tab button.
        app.tabBars.buttons["Plugins"].tap()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Home"].tap()
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Preserved Home navigation"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    @MainActor
    func testOnboardingCanBeSkipped() {
        let app = XCUIApplication()
        app.launchArguments = ["-keihatsu.hasSeenOnboarding", "NO", "-keihatsu.hasEnteredAsGuest", "NO"]
        app.launch()
        XCTAssertTrue(app.buttons["onboarding.skip"].waitForExistence(timeout: 10))
        app.buttons["onboarding.skip"].tap()
        XCTAssertTrue(app.buttons["account.continueAsGuest"].waitForExistence(timeout: 5))
        app.buttons["account.continueAsGuest"].tap()
        XCTAssertTrue(app.navigationBars["Explore"].waitForExistence(timeout: 5))
    }
}
