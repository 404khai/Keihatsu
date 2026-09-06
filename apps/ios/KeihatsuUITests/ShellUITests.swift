import XCTest

final class ShellUITests: XCTestCase {
    @MainActor
    func testBundledReaderLoadsPagesAndPreservesControls() {
        let app = XCUIApplication()
        app.launchEnvironment["KEIHATSU_API_BASE_URL"] = "http://127.0.0.1:1"
        app.launchArguments = ["-keihatsu.hasSeenOnboarding", "YES", "-keihatsu.hasEnteredAsGuest", "YES"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Library"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Library"].tap()
        let thriller = app.buttons["Thriller(3)"]
        XCTAssertTrue(thriller.waitForExistence(timeout: 5))
        thriller.tap()
        let title = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Ordeal")).firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
        let read = app.buttons["manga.details.read"]
        XCTAssertTrue(read.waitForExistence(timeout: 5))
        read.tap()

        XCTAssertTrue(app.descendants(matching: .any)["reader.entry"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["reader.page.chapter-139.0"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Bookmark"].exists)
        XCTAssertTrue(app.buttons["Comments"].exists)
        XCTAssertTrue(app.buttons["Next chapter"].exists)
        measure(metrics: [XCTMemoryMetric(), XCTOSSignpostMetric.scrollDecelerationMetric]) {
            app.swipeUp()
        }
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Phase 4 reader"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    @MainActor
    func testChapterRowsExposeReadAndBookmarkSwipeActions() {
        let app = XCUIApplication()
        app.launchEnvironment["KEIHATSU_API_BASE_URL"] = "http://127.0.0.1:1"
        app.launchArguments = ["-keihatsu.hasSeenOnboarding", "YES", "-keihatsu.hasEnteredAsGuest", "YES"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Library"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Library"].tap()
        let title = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Player")).firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()

        let chapter = app.buttons["manga.chapter.chapter-10"]
        for _ in 0..<4 where !chapter.exists { app.swipeUp() }
        XCTAssertTrue(chapter.waitForExistence(timeout: 5))
        chapter.swipeLeft()
        XCTAssertTrue(app.buttons["Mark Read"].waitForExistence(timeout: 3))
        app.buttons["Mark Read"].tap()
        chapter.swipeRight()
        XCTAssertTrue(app.buttons["Bookmark"].waitForExistence(timeout: 3))
        app.buttons["Bookmark"].tap()
    }

    @MainActor
    func testLibraryTitleOpensDetailsAndCarriesReaderEntry() {
        let app = XCUIApplication()
        app.launchEnvironment["KEIHATSU_API_BASE_URL"] = "http://127.0.0.1:1"
        app.launchArguments = ["-keihatsu.hasSeenOnboarding", "YES", "-keihatsu.hasEnteredAsGuest", "YES"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Library"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Library"].tap()
        let title = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Player")).firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
        let read = app.buttons["manga.details.read"]
        XCTAssertTrue(read.waitForExistence(timeout: 5))
        read.tap()
        XCTAssertTrue(app.staticTexts["Pages for Chapter 1 aren’t available in this build."].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLibraryLayoutsAndCategoryControls() throws {
        let app = XCUIApplication()
        // Shell/collection tests must not depend on provider availability.
        app.launchEnvironment["KEIHATSU_API_BASE_URL"] = "http://127.0.0.1:1"
        app.launchArguments = ["-keihatsu.hasSeenOnboarding", "YES", "-keihatsu.hasEnteredAsGuest", "YES"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Library"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Library"].tap()
        for layout in ["Comfortable grid", "Cover grid", "List", "Compact grid"] {
            app.buttons["Library display and filters"].tap()
            XCTAssertTrue(app.navigationBars["Library Display"].waitForExistence(timeout: 5))
            app.swipeUp()
            let layoutPicker = app.buttons["library.layout"]
            if layoutPicker.label != "Layout, \(layout)" {
                layoutPicker.tap()
                XCTAssertTrue(app.buttons[layout].waitForExistence(timeout: 5))
                app.buttons[layout].tap()
            }
            app.navigationBars["Library Display"].buttons["Done"].tap()
            XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 5))
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = layout
            screenshot.lifetime = .keepAlways
            add(screenshot)
        }
        app.buttons["Edit categories"].tap()
        let name = app.textFields["Category name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Favorites")
        app.buttons["Add Category"].tap()
        XCTAssertTrue(app.buttons["Favorites"].waitForExistence(timeout: 5))
        app.navigationBars["Categories"].buttons["Done"].tap()
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testOnboardingAndExistingNavigationPlacement() throws {
        let app = XCUIApplication()
        // Shell/collection tests must not depend on provider availability.
        app.launchEnvironment["KEIHATSU_API_BASE_URL"] = "http://127.0.0.1:1"
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
        // Shell/collection tests must not depend on provider availability.
        app.launchEnvironment["KEIHATSU_API_BASE_URL"] = "http://127.0.0.1:1"
        app.launchArguments = ["-keihatsu.hasSeenOnboarding", "NO", "-keihatsu.hasEnteredAsGuest", "NO"]
        app.launch()
        XCTAssertTrue(app.buttons["onboarding.skip"].waitForExistence(timeout: 10))
        app.buttons["onboarding.skip"].tap()
        XCTAssertTrue(app.buttons["account.continueAsGuest"].waitForExistence(timeout: 5))
        app.buttons["account.continueAsGuest"].tap()
        XCTAssertTrue(app.navigationBars["Explore"].waitForExistence(timeout: 5))
    }
}
