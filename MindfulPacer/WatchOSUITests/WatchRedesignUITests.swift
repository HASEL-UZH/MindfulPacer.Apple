import XCTest

final class WatchRedesignUITests: XCTestCase {
    override func setUpWithError() throws {
        #if !targetEnvironment(simulator)
        throw XCTSkip("Uses isolated simulator fixtures.")
        #endif
        continueAfterFailure = false
    }

    @MainActor
    private func launch(_ scenario: String = "home") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-watch-design-preview", "-watch-scenario", scenario,
                               "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        // A prior non-fixture test host can leave the system Health request visible.
        // Close that sheet without granting permissions in this isolated capture workflow.
        addUIInterruptionMonitor(withDescription: "Health request") { alert in
            let close = alert.buttons["Close"]
            if close.exists { close.tap(); return true }
            return false
        }
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        let system = XCUIApplication(bundleIdentifier: "com.apple.Carousel")
        if system.alerts.staticTexts["UIA.Health.WatchAuthSheet.HealthAccessLabel"].exists {
            system.alerts.buttons["Close"].tap()
        }
        return app
    }

    @MainActor
    private func shot(_ app: XCUIApplication, _ name: String) {
        Thread.sleep(forTimeInterval: 0.5)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "watch__" + name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<6 {
            if element.exists && element.isHittable { return }
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.75))
            start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: -70)), withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        XCTAssertTrue(element.isHittable)
    }

    @MainActor
    func testHomeAndControls() {
        let app = launch()
        XCTAssertTrue(app.buttons["watch.heartRate"].firstMatch.waitForExistence(timeout: 10))
        shot(app, "01-home")
        app.buttons["watch.heartRate"].firstMatch.tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "watch.heartRateChart").firstMatch.waitForExistence(timeout: 5))
        shot(app, "02-heart-rate")
        app.swipeUp()
        shot(app, "03-crown-pages")
        app.buttons["watch.controls"].firstMatch.tap()
        XCTAssertTrue(app.buttons["watch.pauseResume"].firstMatch.waitForExistence(timeout: 5))
        shot(app, "04-controls")
        app.buttons["watch.pauseResume"].firstMatch.tap()
        XCTAssertTrue(app.buttons["watch.pauseResume"].firstMatch.label.contains("Resume"))
        shot(app, "05-controls-paused")
        app.buttons["watch.pauseResume"].firstMatch.tap()
        XCTAssertTrue(app.buttons["watch.pauseResume"].firstMatch.label.contains("Pause"))
        reveal(app.buttons["watch.reminders"].firstMatch, in: app)
        shot(app, "06-controls-more")
        app.buttons["watch.reminders"].firstMatch.tap()
        shot(app, "07-reminders")
        app.swipeUp()
        shot(app, "08-reminders-more")
    }

    @MainActor
    func testPresentationStates() {
        for scenario in ["steps", "paused", "highlight-light", "highlight-medium", "highlight-strong",
                         "empty-heart-rate", "empty-steps", "single-heart-rate", "permission", "no-reminders"] {
            let app = launch(scenario)
            shot(app, scenario)
            if scenario == "no-reminders" {
                app.buttons["watch.controls"].firstMatch.tap()
                reveal(app.buttons["watch.reminders"].firstMatch, in: app)
                app.buttons["watch.reminders"].firstMatch.tap()
                shot(app, "no-reminders-list")
            }
        }
    }

    @MainActor
    func testReflectionFlow() {
        let app = launch("alert")
        XCTAssertTrue(app.buttons["watch.alert.details"].firstMatch.waitForExistence(timeout: 10))
        shot(app, "20-reflection-prompt")
        app.swipeUp()
        shot(app, "21-reflection-actions")
        app.swipeDown()
        app.buttons["watch.alert.details"].firstMatch.tap()
        XCTAssertTrue(app.buttons["watch.activity.later"].firstMatch.waitForExistence(timeout: 5))
        shot(app, "22-activity-picker")
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Cognitive")).firstMatch.tap()
        shot(app, "23-subactivity-picker")
        let reading = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Reading")).firstMatch
        reveal(reading, in: app)
        reading.tap()
        XCTAssertTrue(app.buttons["watch.heartRate"].firstMatch.waitForExistence(timeout: 5))
        shot(app, "24-after-reflection")

        let empty = launch("activities-empty")
        empty.buttons["watch.alert.details"].firstMatch.tap()
        shot(empty, "25-activities-not-synced")
        empty.buttons["watch.activity.later"].firstMatch.tap()
        XCTAssertTrue(empty.buttons["watch.heartRate"].firstMatch.waitForExistence(timeout: 5))
    }

    @MainActor
    func testChartsAndUtilityScreens() {
        for (scenario, name) in [("heart-rate", "02-heart-rate"), ("steps", "steps"), ("single-heart-rate", "single-heart-rate")] {
            let app = launch(scenario)
            let chart = scenario == "steps" ? "watch.stepsChart" : "watch.heartRateChart"
            XCTAssertTrue(app.descendants(matching: .any).matching(identifier: chart).firstMatch.waitForExistence(timeout: 5))
            shot(app, name)
        }
        let app = launch()
        app.buttons["watch.controls"].firstMatch.tap()
        let missed = app.buttons["watch.missed"].firstMatch
        reveal(missed, in: app)
        missed.tap()
        XCTAssertTrue(app.staticTexts["Continue on iPhone"].waitForExistence(timeout: 5))
        shot(app, "09-missed-reflections")
        app.navigationBars.buttons.firstMatch.tap()
        let about = app.buttons["watch.about"].firstMatch
        reveal(about, in: app)
        about.tap()
        XCTAssertTrue(app.staticTexts["Battery"].waitForExistence(timeout: 5))
        shot(app, "10-about")
        app.swipeUp()
        shot(app, "11-about-version")
    }

}
