import XCTest

/// Smoke coverage for actions that used to be nested inside Home navigation links,
/// and the controls needed to recover from an empty health-data period.
final class RedesignNavigationTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testReflectionListSwipeAndAnalyticsSelection() {
        let app = launchApp(extraArguments: ["-theme", "Light"])
        XCTAssertTrue(app.buttons["Create Reflection"].waitForExistence(timeout: 15))
        capture(app, "Home creation card")
        app.buttons["Create Reflection"].tap()
        app.buttons["reflection.activity"].tap()
        app.buttons["Movement"].tap()
        app.buttons["Save"].tap()
        XCTAssertTrue(app.buttons["home.context.today"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Analytics"].tap()
        let row = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "analytics.reflectionRow.")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(row.isSelected)
        capture(app, "Analytics reflection selection panel")
        app.buttons["Edit Reflection"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Save"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()
        app.tabBars.buttons["Home"].tap()
        app.buttons["home.context.reflections"].tap()
        let all = app.buttons["home.reflections.showAll"]
        for _ in 0..<5 where !all.isHittable { app.scrollViews["home.content.reflections"].swipeUp() }
        capture(app, "Home recent reflection rows")
        all.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.7)).tap()
        let historyRow = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "reflections.row.")).firstMatch
        XCTAssertTrue(historyRow.waitForExistence(timeout: 5))
        capture(app, "Reflections large navigation title")
        let identifier = historyRow.identifier
        historyRow.swipeLeft()
        let delete = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Delete")).firstMatch
        if delete.waitForExistence(timeout: 3) && !app.alerts.firstMatch.exists { delete.tap() }
        XCTAssertTrue(app.alerts["Delete Reflection"].waitForExistence(timeout: 5))
        capture(app, "Reflection swipe deletion confirmation")
        app.alerts.buttons["Delete"].tap()
        XCTAssertFalse(app.buttons[identifier].exists)
    }

    @MainActor
    func testReminderListSwipeDeletion() {
        let app = launchApp(extraArguments: ["-theme", "Light"])
        XCTAssertTrue(app.buttons["home.context.reminders"].waitForExistence(timeout: 15))
        openNewReminderFromHome(app)
        app.buttons["Get Started"].tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Heart Rate")).firstMatch.tap()
        app.buttons["Continue"].tap()
        app.buttons["Light"].tap()
        app.buttons["Continue"].tap()
        app.textFields.firstMatch.tap()
        app.textFields.firstMatch.typeText("101")
        app.buttons["Continue"].tap()
        app.buttons["1 Minute"].tap()
        app.buttons["Continue"].tap()
        app.buttons["Create"].tap()
        XCTAssertTrue(app.navigationBars["Reminders"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()
        let all = app.buttons["home.reminders.showAll"]
        XCTAssertTrue(all.waitForExistence(timeout: 5))
        for _ in 0..<5 where !all.isHittable || all.frame.maxY > app.tabBars.firstMatch.frame.minY {
            app.scrollViews["home.content.reminders"].swipeUp()
        }
        capture(app, "Home recent reminder rows")
        all.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.7)).tap()
        let row = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "reminders.row.")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        capture(app, "Reminders large navigation title")
        let identifier = row.identifier
        row.swipeLeft()
        let delete = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Delete")).firstMatch
        if delete.waitForExistence(timeout: 3) && !app.alerts.firstMatch.exists { delete.tap() }
        XCTAssertTrue(app.alerts["Delete Reminder"].waitForExistence(timeout: 5))
        capture(app, "Reminder swipe deletion confirmation")
        app.alerts.buttons["Delete"].tap()
        XCTAssertFalse(app.buttons[identifier].exists)
    }

    @MainActor
    func testAnalyticsOpensAndChangesPeriodsWithoutStalling() {
        let app = launchApp(extraArguments: ["-theme", "Light"])
        XCTAssertTrue(app.tabBars.buttons["Analytics"].waitForExistence(timeout: 15))
        let openedAt = ProcessInfo.processInfo.systemUptime
        app.tabBars.buttons["Analytics"].tap()
        XCTAssertTrue(app.segmentedControls.buttons["Heart Rate"].waitForExistence(timeout: 5))
        let openingDuration = ProcessInfo.processInfo.systemUptime - openedAt
        print("Analytics opening duration: \(openingDuration) seconds")
        XCTAssertLessThan(openingDuration, 8, "Opening Analytics must not block chart layout for tens of seconds.")
        for measurement in ["Steps", "Heart Rate"] {
            app.segmentedControls.buttons[measurement].tap()
            for period in ["2H", "D", "W", "1H"] {
                let startedAt = ProcessInfo.processInfo.systemUptime
                app.segmentedControls.buttons[period].tap()
                XCTAssertTrue(app.segmentedControls.buttons[period].isSelected)
                XCTAssertLessThan(ProcessInfo.processInfo.systemUptime - startedAt, 8)
            }
        }
        capture(app, "Analytics responsive hour chart")
        app.tabBars.buttons["Home"].tap()
        XCTAssertTrue(app.buttons["home.context.today"].isHittable)
    }

    @MainActor
    func testHomeContextsHaveDistinctPagesAndSwipeNavigation() {
        let app = launchApp(extraArguments: ["-theme", "Light"])
        XCTAssertTrue(app.buttons["home.context.today"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.navigationBars["Home"].exists)
        XCTAssertTrue(app.staticTexts["How are you feeling?"].isHittable)
        capture(app, "Home Today focused page")
        app.buttons["home.context.reflections"].tap()
        XCTAssertTrue(app.staticTexts["This Week"].isHittable)
        capture(app, "Home Reflections focused page")
        let page = app.scrollViews["home.content.reflections"]
        let start = page.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.4))
        start.press(forDuration: 0.05, thenDragTo: page.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.4)))
        XCTAssertTrue(app.buttons["home.context.reminders"].isSelected)
        XCTAssertTrue(app.staticTexts["Active Reminders"].isHittable)
        capture(app, "Home Reminders focused page")
        let reminderPage = app.scrollViews["home.content.reminders"]
        let reminderList = app.buttons["home.reminders.showAll"]
        for _ in 0..<5 where !reminderList.isHittable { reminderPage.swipeUp() }
        reminderList.tap()
        XCTAssertTrue(app.navigationBars["Reminders"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["home.context.reminders"].isHittable)
        XCTAssertFalse(app.navigationBars["Home"].exists)
    }

    @MainActor
    func testHomeContextSwitcherRemainsVisible() {
        for largeText in [false, true] {
            let app = launchApp(extraArguments: largeText ? [
                "-theme", "Dark",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
            ] : ["-theme", "Light"])
            let switcher = app.scrollViews["home.contextSwitcher"]
            XCTAssertTrue(switcher.waitForExistence(timeout: 15))
            let today = app.buttons["home.context.today"]
            let buttonY = today.frame.minY
            XCTAssertTrue(today.isHittable)
            XCTAssertGreaterThanOrEqual(today.frame.height, 44)
            XCTAssertGreaterThanOrEqual(switcher.frame.height, today.frame.height)
            XCTAssertFalse(app.navigationBars["Home"].exists)
            XCTAssertGreaterThanOrEqual(app.staticTexts["How are you feeling?"].frame.minY, today.frame.maxY)
            capture(app, largeText ? "Home switcher large text" : "Home switcher")

            for context in ["reflections", "reminders", "today"] {
                let button = app.buttons["home.context.\(context)"]
                for _ in 0..<4 where button.frame.intersection(switcher.frame).width < min(button.frame.width, switcher.frame.width) * 0.75 {
                    // The scroll view's accessibility frame includes the navigation-bar
                    // safe area; drag at the buttons' height rather than its frame center.
                    let y = (button.frame.midY - switcher.frame.minY) / switcher.frame.height
                    let startX = context == "today" ? 0.15 : 0.85
                    let start = switcher.coordinate(withNormalizedOffset: CGVector(dx: startX, dy: y))
                    let end = switcher.coordinate(withNormalizedOffset: CGVector(dx: 1 - startX, dy: y))
                    start.press(forDuration: 0.05, thenDragTo: end)
                }
                XCTAssertTrue(button.isHittable)
                button.tap()
                XCTAssertTrue(button.isSelected)
                XCTAssertEqual(button.frame.minY, buttonY, accuracy: 1)
                XCTAssertGreaterThanOrEqual(button.frame.minY, switcher.frame.minY)
                XCTAssertLessThanOrEqual(button.frame.maxY, switcher.frame.maxY)
            }
            let headerY = switcher.frame.minY
            app.scrollViews["home.content.today"].swipeUp()
            XCTAssertEqual(switcher.frame.minY, headerY, accuracy: 1)
            XCTAssertTrue(today.isHittable)
            app.tabBars.buttons["Settings"].tap()
            app.tabBars.buttons["Home"].tap()
            XCTAssertTrue(today.isHittable)
            capture(app, largeText ? "Home switcher after return large text" : "Home switcher after return")
            app.terminate()
        }
    }

    @MainActor
    func testHomeCreationAndAnalyticsNavigation() {
        let app = launchApp()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 15))
        capture(app, "Home")

        app.buttons["home.context.today"].tap()
        app.buttons["Create Reflection"].tap()
        XCTAssertTrue(app.buttons["Save"].waitForExistence(timeout: 5))
        capture(app, "Reflection editor")
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.scrollViews["home.contextSwitcher"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Analytics"].tap()
        XCTAssertTrue(app.segmentedControls.buttons["Heart Rate"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.segmentedControls.buttons["Heart Rate"].isSelected)
        capture(app, "Analytics heart rate")
        app.segmentedControls.buttons["Steps"].tap()
        XCTAssertTrue(app.segmentedControls.buttons["Steps"].isSelected)
        XCTAssertTrue(app.segmentedControls.buttons["D"].exists)
        app.segmentedControls.buttons["D"].tap()
        XCTAssertTrue(app.segmentedControls.buttons["D"].isSelected)

        app.navigationBars.buttons["Selected Date"].tap()
        XCTAssertTrue(app.datePickers.firstMatch.waitForExistence(timeout: 5))
        capture(app, "Date selection")
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Analytics"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Outreach"].tap()
        XCTAssertTrue(app.staticTexts["Community"].waitForExistence(timeout: 5))
        let roadmap = app.buttons["Roadmap"]
        for _ in 0..<5 where !roadmap.isHittable { app.swipeUp() }
        capture(app, "Outreach compact resource actions")
        roadmap.tap()
        XCTAssertTrue(app.navigationBars["Roadmap"].waitForExistence(timeout: 5))
        app.buttons["Close"].firstMatch.tap()
        let articles = app.buttons["Show All"]
        for _ in 0..<5 where !articles.isHittable { app.swipeDown() }
        articles.tap()
        XCTAssertTrue(app.navigationBars["Articles"].waitForExistence(timeout: 5))
        capture(app, "Articles")
    }

    @MainActor
    func testDarkAppearanceAndAccessibleTextNavigation() {
        let app = launchApp(extraArguments: [
            "-theme", "Dark",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ])
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 15))
        capture(app, "Home dark accessibility")
        app.tabBars.buttons["Analytics"].tap()
        XCTAssertTrue(app.segmentedControls.buttons["Steps"].waitForExistence(timeout: 5))
        app.segmentedControls.buttons["Steps"].tap()
        capture(app, "Analytics dark accessibility")
        app.tabBars.buttons["Outreach"].tap()
        XCTAssertTrue(app.staticTexts["Articles"].waitForExistence(timeout: 5))
        capture(app, "Outreach dark accessibility")
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        capture(app, "Settings dark accessibility")
        let onboarding = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Onboarding")).firstMatch
        for _ in 0..<5 where !onboarding.isHittable { app.swipeUp() }
        XCTAssertTrue(onboarding.isHittable)
        onboarding.tap()
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 5))
        capture(app, "Onboarding dark accessibility")
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.buttons["Skip"].waitForExistence(timeout: 5))
        capture(app, "Onboarding features dark accessibility")
    }

    @MainActor
    func testReminderAndSupportingSheets() {
        let app = launchApp()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 15))
        openNewReminderFromHome(app)
        XCTAssertTrue(app.buttons["Close"].waitForExistence(timeout: 5))
        capture(app, "Reminder introduction")
        app.buttons["Close"].tap()
        XCTAssertTrue(app.navigationBars["Reminders"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Settings"].tap()
        capture(app, "Settings")
        let releaseNotes = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Release Notes")).firstMatch
        for _ in 0..<5 where !releaseNotes.isHittable { app.swipeUp() }
        XCTAssertTrue(releaseNotes.isHittable)
        releaseNotes.tap()
        XCTAssertTrue(app.navigationBars["Release Notes"].waitForExistence(timeout: 5))
        capture(app, "Release notes")
        app.buttons["Done"].tap()

        let roadmap = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Roadmap")).firstMatch
        for _ in 0..<4 where !roadmap.isHittable { app.swipeUp() }
        XCTAssertTrue(roadmap.isHittable)
        roadmap.tap()
        XCTAssertTrue(app.navigationBars["Roadmap"].waitForExistence(timeout: 5))
        capture(app, "Roadmap")
        app.buttons["Close"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testOnboardingStepsAndDeviceChoice() {
        let app = launchApp(extraArguments: ["-userHasSeenOnboarding", "NO", "-theme", "Light"])
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 15))
        capture(app, "Onboarding welcome")
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["Main Features"].waitForExistence(timeout: 5))
        for name in ["Main Feature 1", "Main Feature 2"] {
            let screenshot = app.descendants(matching: .any).matching(identifier: "onboarding.feature.\(name)").firstMatch
            for _ in 0..<8 where !screenshot.isHittable { app.scrollViews.firstMatch.swipeUp() }
            XCTAssertTrue(screenshot.isHittable, "Both onboarding screenshots must be restored.")
            capture(app, "Onboarding \(name)")
        }
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["Device Mode"].waitForExistence(timeout: 5))
        capture(app, "Onboarding device choice")
        let watchChoice = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "iPhone + Apple Watch")).firstMatch
        if watchChoice.exists { watchChoice.tap() }
        app.buttons["Continue"].tap()
        if app.staticTexts["Connect to Your Apple Watch"].waitForExistence(timeout: 3) {
            capture(app, "Onboarding Apple Watch")
            app.buttons["Continue"].tap()
        }
        XCTAssertTrue(app.buttons["Skip"].waitForExistence(timeout: 5))
        capture(app, "Onboarding notifications")
        app.buttons["Skip"].tap()
        XCTAssertTrue(app.staticTexts["Connect to Apple Health"].waitForExistence(timeout: 5))
        capture(app, "Onboarding Apple Health")
    }

    @MainActor
    func testOnboardingDisclaimerRequiresAcceptance() {
        let app = launchApp(extraArguments: ["-userHasSeenOnboarding", "NO", "-theme", "Light"])
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 15))
        app.buttons["Continue"].tap()
        app.buttons["Skip"].tap()
        XCTAssertTrue(app.staticTexts["Disable Activity Promoting Features"].waitForExistence(timeout: 5))
        capture(app, "Onboarding optional setup")
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["Mode of Use"].waitForExistence(timeout: 5))
        capture(app, "Onboarding mode choice")
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["Disclaimer"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Finish"].isEnabled)
        capture(app, "Onboarding disclaimer")
        let acceptance = app.switches["I Understand and Accept"]
        scrollAboveAction(acceptance, action: app.buttons["Finish"], in: app)
        capture(app, "Onboarding acceptance group")
        acceptance.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
        let enabled = expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: app.buttons["Finish"])
        wait(for: [enabled], timeout: 5)
        app.buttons["Finish"].tap()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testReminderSelectionControls() {
        let app = launchApp()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 15))
        let previousReminderIDs = openNewReminderFromHome(app)
        XCTAssertTrue(app.buttons["Get Started"].waitForExistence(timeout: 5))
        capture(app, "Reminder action height")
        app.buttons["Get Started"].tap()
        let heartRate = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Heart Rate")).firstMatch
        XCTAssertTrue(heartRate.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Continue"].isEnabled)
        heartRate.tap()
        XCTAssertTrue(heartRate.isSelected)
        XCTAssertTrue(app.buttons["Continue"].isEnabled)
        capture(app, "Reminder measurement selection")
        heartRate.tap()
        XCTAssertFalse(app.buttons["Continue"].isEnabled)
        heartRate.tap()
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.buttons["Light"].waitForExistence(timeout: 5))
        app.buttons["Light"].tap()
        capture(app, "Reminder strength selection")
        app.buttons["Continue"].tap()
        app.textFields.firstMatch.tap()
        app.textFields.firstMatch.typeText("100")
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.buttons["1 Minute"].waitForExistence(timeout: 5))
        app.buttons["1 Minute"].tap()
        XCTAssertTrue(app.buttons["1 Minute"].isSelected)
        capture(app, "Reminder interval selection")
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["Review Reminder"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["reminder.editor.measurement"].exists)
        XCTAssertTrue(app.buttons["reminder.editor.strength"].exists)
        capture(app, "Reminder summary")
        let thresholdRow = app.buttons["reminder.editor.threshold"]
        thresholdRow.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        let input = app.textFields["reminder.threshold.input"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap()
        input.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 3) + "103")
        capture(app, "Reminder threshold sheet")
        app.buttons["Done"].tap()
        XCTAssertTrue(thresholdRow.waitForExistence(timeout: 5))
        XCTAssertTrue(thresholdRow.label.contains("103"))
        app.buttons["Create"].tap()
        XCTAssertTrue(app.navigationBars["Reminders"].waitForExistence(timeout: 5))
        let matchingRows = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "reminders.row.", "103"))
        let newID = matchingRows.allElementsBoundByIndex.map(\.identifier).first { !previousReminderIDs.contains($0) }
        XCTAssertNotNil(newID)
        let saved = app.buttons[newID ?? "missing-new-reminder"].firstMatch
        XCTAssertTrue(saved.waitForExistence(timeout: 5))
        if !app.buttons["Edit Reminder"].exists { saved.tap() }
        app.buttons["Edit Reminder"].tap()
        XCTAssertTrue(app.buttons["reminder.editor.threshold"].waitForExistence(timeout: 5))
        capture(app, "Existing reminder editor")
        let savedID = newID ?? "missing-new-reminder"
        XCTAssertFalse(app.buttons["reminder.editor.measurement"].exists)
        XCTAssertFalse(app.buttons["reminder.editor.strength"].exists)
        let measurement = app.descendants(matching: .any).matching(identifier: "reminder.editor.measurement").firstMatch
        let strength = app.descendants(matching: .any).matching(identifier: "reminder.editor.strength").firstMatch
        XCTAssertTrue(measurement.label.contains("Heart Rate"))
        XCTAssertTrue(strength.label.contains("Light"))
        measurement.tap()
        strength.tap()
        XCTAssertFalse(app.buttons["Done"].exists, "Existing types must not open a picker.")
        app.buttons["reminder.editor.threshold"].tap()
        input.tap()
        input.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 3) + "104")
        app.buttons["Done"].tap()
        app.buttons["reminder.editor.interval"].tap()
        app.buttons["2 Minutes"].tap()
        app.buttons["Save"].tap()
        XCTAssertTrue(app.buttons[savedID].firstMatch.waitForExistence(timeout: 5))
        if !app.buttons["Edit Reminder"].exists { app.buttons[savedID].firstMatch.tap() }
        app.buttons["Edit Reminder"].tap()
        XCTAssertTrue(app.buttons["reminder.editor.threshold"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["reminder.editor.threshold"].label.contains("104"))
        XCTAssertTrue(app.buttons["reminder.editor.interval"].label.contains("2 Minutes"))
        XCTAssertTrue(measurement.label.contains("Heart Rate"))
        XCTAssertTrue(strength.label.contains("Light"))
        capture(app, "Locked reminder types and red delete action")
        app.buttons["reminder.editor.threshold"].tap()
        input.tap()
        input.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 3) + "109")
        app.buttons["Done"].tap()
        app.buttons["Cancel"].tap()
        if !app.buttons["Edit Reminder"].exists { app.buttons[savedID].firstMatch.tap() }
        app.buttons["Edit Reminder"].tap()
        XCTAssertTrue(app.buttons["reminder.editor.threshold"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["reminder.editor.threshold"].label.contains("104"), "Cancel must discard draft edits.")
        app.buttons["Delete Reminder"].tap()
        XCTAssertTrue(app.alerts["Delete Reminder"].waitForExistence(timeout: 5))
        app.alerts.buttons["Delete"].tap()
        XCTAssertFalse(app.buttons[savedID].firstMatch.exists)

    }

    @MainActor
    func testReflectionSelectionSheets() {
        let app = launchApp(extraArguments: ["-modeOfUse", "expanded"])
        XCTAssertTrue(app.buttons["home.context.reflections"].waitForExistence(timeout: 15))
        app.buttons["home.context.today"].tap()
        app.buttons["Create Reflection"].tap()
        capture(app, "Reflection editor")
        app.buttons["reflection.activity"].tap()
        XCTAssertTrue(app.buttons["Movement"].waitForExistence(timeout: 5))
        capture(app, "Activity choices")
        app.buttons["Movement"].tap()
        XCTAssertTrue(app.buttons["reflection.subactivity"].waitForExistence(timeout: 5))
        app.buttons["reflection.subactivity"].tap()
        let walking = app.buttons["Walking"]
        for _ in 0..<5 where !walking.isHittable { app.swipeUp() }
        XCTAssertTrue(walking.exists)
        capture(app, "Subactivity choices")
        walking.tap()
        XCTAssertTrue(app.buttons["reflection.wellbeing"].waitForExistence(timeout: 5))
        app.buttons["reflection.wellbeing"].tap()
        let selectedWellbeing = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "3,")).firstMatch
        for _ in 0..<3 where !selectedWellbeing.isHittable { app.swipeUp() }
        XCTAssertTrue(selectedWellbeing.exists)
        capture(app, "Wellbeing choices")
        selectedWellbeing.tap()
        XCTAssertTrue(app.buttons["Save"].waitForExistence(timeout: 5))
        if app.buttons["reflection.mood"].exists {
            app.buttons["reflection.mood"].tap()
            XCTAssertTrue(app.buttons["Happy"].waitForExistence(timeout: 5))
            capture(app, "Mood choices")
            app.buttons["Happy"].tap()
            XCTAssertTrue(app.buttons["Save"].waitForExistence(timeout: 5))
        }
        XCTAssertTrue(app.buttons["Save"].isEnabled)
        app.buttons["reflection.wellbeing"].tap()
        XCTAssertTrue(selectedWellbeing.waitForExistence(timeout: 5))
        XCTAssertTrue(selectedWellbeing.isSelected)
        capture(app, "Wellbeing selected")
        selectedWellbeing.tap()
        XCTAssertTrue(app.buttons["Save"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Save"].isEnabled)
        app.buttons["reflection.wellbeing"].tap()
        XCTAssertTrue(selectedWellbeing.waitForExistence(timeout: 5))
        XCTAssertFalse(selectedWellbeing.isSelected)
        app.buttons["Close"].tap()
        app.buttons["reflection.activity"].tap()
        XCTAssertTrue(app.buttons["Movement"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Movement"].isSelected)
        app.buttons["Movement"].tap()
        XCTAssertTrue(app.buttons["Save"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Save"].isEnabled)
        XCTAssertFalse(app.buttons["reflection.subactivity"].exists)
        app.buttons["Cancel"].tap()
    }

    @MainActor
    func testSettingsAndAccessibleSelectionControls() {
        let app = launchApp(extraArguments: [
            "-theme", "Dark",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ])
        XCTAssertTrue(app.tabBars.buttons["Settings"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Settings"].tap()
        let theme = app.buttons["settings.theme"]
        for _ in 0..<5 where !theme.isHittable { app.swipeUp() }
        theme.tap()
        XCTAssertTrue(app.navigationBars["Theme"].waitForExistence(timeout: 5))
        capture(app, "Theme choices dark accessibility")
        app.navigationBars.buttons.firstMatch.tap()
        let device = app.buttons["settings.deviceMode"]
        for _ in 0..<5 where !device.isHittable { app.swipeDown() }
        device.tap()
        XCTAssertTrue(app.navigationBars["Device Mode"].waitForExistence(timeout: 5))
        capture(app, "Device choices dark accessibility")
        app.terminate()

        app.launchArguments += ["-userHasSeenOnboarding", "NO"]
        app.launch()
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 15))
        app.buttons["Continue"].tap()
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["Device Mode"].waitForExistence(timeout: 5))
        let phone = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "iPhone Only")).firstMatch
        for _ in 0..<5 where !phone.isHittable { app.swipeUp() }
        XCTAssertTrue(phone.isHittable)
        // At the largest text size the row is taller than the viewport; tap its visible area
        // above the fixed Continue bar, rather than XCTest's offscreen center point.
        let visibleTop = max(phone.frame.minY, app.navigationBars.firstMatch.frame.maxY)
        let visibleBottom = min(phone.frame.maxY, app.buttons["Continue"].frame.minY)
        XCTAssertGreaterThan(visibleBottom, visibleTop)
        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: phone.frame.midX, dy: (visibleTop + visibleBottom) / 2))
            .tap()
        XCTAssertTrue(phone.isSelected)
        capture(app, "Onboarding choices dark accessibility")
        XCTAssertTrue(app.buttons["Continue"].isHittable)
    }

    @MainActor
    func testOnboardingContentClearsActionBar() {
        for largeText in [false, true] {
            var arguments = ["-userHasSeenOnboarding", "NO", "-theme", "Light"]
            if largeText {
                arguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            }
            let app = launchApp(extraArguments: arguments)
            XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 15))
            app.buttons["Continue"].tap()
            app.buttons["Skip"].tap()
            XCTAssertTrue(app.staticTexts["Disable Activity Promoting Features"].waitForExistence(timeout: 5))
            capture(app, largeText ? "Setup groups large text" : "Setup groups")
            app.buttons["Continue"].tap()
            XCTAssertTrue(app.staticTexts["Mode of Use"].waitForExistence(timeout: 5))
            let finalNote = app.staticTexts["You can always change this later on in the app settings."]
            scrollAboveAction(finalNote, action: app.buttons["Continue"], in: app)
            capture(app, largeText ? "Onboarding footer clearance large text" : "Onboarding footer clearance")
            app.buttons["Continue"].tap()
            XCTAssertTrue(app.buttons["Finish"].waitForExistence(timeout: 5))
            let acceptance = app.switches["I Understand and Accept"]
            scrollAboveAction(acceptance, action: app.buttons["Finish"], in: app)
            capture(app, largeText ? "Acceptance group large text" : "Acceptance group")
            XCTAssertFalse(app.buttons["Finish"].isEnabled)
            acceptance.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
            XCTAssertTrue(app.buttons["Finish"].isEnabled)
            app.terminate()
        }
    }

    @MainActor
    private func scrollAboveAction(_ element: XCUIElement, action: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<12 {
            if element.exists && element.isHittable && element.frame.maxY <= action.frame.minY - 12 { break }
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(element.isHittable)
        XCTAssertLessThanOrEqual(element.frame.maxY, action.frame.minY - 12)
    }

    @MainActor
    func testZMissedChartSeparatesInspectionFromScrollingAndNavigation() {
        // Stored trigger samples are the Watch-mode source; phone mode derives
        // missed reflections from live HealthKit queries instead.
        let app = launchApp(extraArguments: ["-deviceMode", "iPhoneAndWatch", "-theme", "Light"])
        XCTAssertTrue(app.tabBars.buttons["Settings"].waitForExistence(timeout: 15))
        capture(app, "Home Watch connection warning")
        app.tabBars.buttons["Settings"].tap()
        let manage = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Manage Data")).firstMatch
        for _ in 0..<5 where !manage.isHittable { app.swipeUp() }
        manage.tap()
        let seed = app.buttons["Seed"]
        for _ in 0..<5 where !seed.isHittable { app.swipeUp() }
        XCTAssertTrue(seed.isHittable)
        capture(app, "Data management actions")
        seed.tap()
        app.tabBars.buttons["Home"].tap()
        app.buttons["home.context.reflections"].tap()
        let missed = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Missed Reflections")).firstMatch
        XCTAssertTrue(missed.waitForExistence(timeout: 5))
        missed.tap()
        let filter = app.buttons["missedReflections.filter"]
        XCTAssertTrue(filter.waitForExistence(timeout: 5))
        for measurement in ["Steps", "Heart Rate", "All"] {
            filter.tap()
            capture(app, "Missed reflections measurement filter")
            app.buttons[measurement].tap()
            capture(app, "Missed reflections filtered to \(measurement)")
            if measurement != "All" {
                XCTAssertTrue(app.staticTexts[measurement].firstMatch.waitForExistence(timeout: 5))
                let other = measurement == "Steps" ? "Heart Rate" : "Steps"
                XCTAssertFalse(app.staticTexts[other].exists)
            }
        }
        let chart = app.descendants(matching: .any).matching(identifier: "missedReflection.chart").firstMatch
        XCTAssertTrue(chart.waitForExistence(timeout: 5))
        XCTAssertLessThan(chart.frame.height, 240, "The gesture target must be the chart, not its containing card.")
        let left = chart.coordinate(withNormalizedOffset: CGVector(dx: 0.12, dy: 0.5))
        let right = chart.coordinate(withNormalizedOffset: CGVector(dx: 0.45, dy: 0.5))
        let chartY = chart.frame.minY
        left.press(forDuration: 0.6, thenDragTo: right)
        let rightValue = chart.value as? String
        XCTAssertFalse((rightValue ?? "").isEmpty, "Holding and dragging must reveal a chart value.")
        XCTAssertEqual(chart.frame.minY, chartY, accuracy: 2, "Horizontal inspection must not scroll the list.")
        right.press(forDuration: 0.05, thenDragTo: left)
        XCTAssertNotEqual(chart.value as? String, rightValue, "Dragging back must update the selected sample.")
        capture(app, "Missed reflection chart drag inspection")
        chart.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
            .withOffset(CGVector(dx: 0, dy: -50)).tap()
        XCTAssertEqual(chart.value as? String, "", "Tapping the card outside its chart must clear selection.")
        right.tap()
        XCTAssertFalse((chart.value as? String ?? "").isEmpty, "Tapping a chart must still select a sample.")
        right.tap()
        XCTAssertEqual(chart.value as? String, "", "Tapping the selected point must deselect it.")
        for drift in [0.0, 40.0, -40.0] {
            let originalY = chart.frame.minY
            let start = chart.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
            start.press(forDuration: 0.6, thenDragTo: start.withOffset(CGVector(dx: drift, dy: -160)))
            XCTAssertTrue(chart.exists, "Held inspection must not pop the view.")
            XCTAssertEqual(chart.frame.minY, originalY, accuracy: 2, "A held touch must remain in inspection, including vertical movement.")
            XCTAssertFalse((chart.value as? String ?? "").isEmpty)
        }
        let scrubStart = chart.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.5))
        scrubStart.press(forDuration: 0.6, thenDragTo: chart.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.7)))
        XCTAssertTrue(chart.exists, "Scrubbing right must not trigger interactive back navigation.")
        for drift in [0.0, 40.0, -40.0] {
            app.scrollViews.firstMatch.swipeDown()
            let originalY = chart.frame.minY
            let start = chart.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
            start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: drift, dy: -160)))
            XCTAssertLessThan(chart.frame.minY, originalY - 40, "A quick vertical or diagonal drag starting on the chart must scroll.")
        }
        chart.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertFalse((chart.value as? String ?? "").isEmpty)
        chart.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 1))
            .withOffset(CGVector(dx: 0, dy: 8)).tap()
        XCTAssertEqual(chart.value as? String, "", "Tap-away must use the chart's current position after scrolling.")
        capture(app, "Missed reflection chart scrolling")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["home.context.reflections"].waitForExistence(timeout: 5), "Back navigation must remain available after inspection.")
    }

    @MainActor
    func testHomeRecentItemsAndCardHaveIndependentActions() {
        let app = launchApp(extraArguments: ["-theme", "Light"])
        XCTAssertTrue(app.buttons["Create Reflection"].waitForExistence(timeout: 15))
        // Create actual completed reflections; the debug seed only creates missed ones.
        for _ in 0..<3 {
            app.buttons["Create Reflection"].tap()
            app.buttons["reflection.activity"].tap()
            app.buttons["Movement"].tap()
            app.buttons["Save"].tap()
            XCTAssertTrue(app.buttons["home.context.today"].waitForExistence(timeout: 5))
        }
        for (strength, threshold) in [("Light", "210"), ("Medium", "220"), ("Strong", "230")] {
            openNewReminderFromHome(app)
            app.buttons["Get Started"].tap()
            app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Heart Rate")).firstMatch.tap()
            app.buttons["Continue"].tap()
            app.buttons[strength].tap()
            app.buttons["Continue"].tap()
            app.textFields.firstMatch.tap()
            app.textFields.firstMatch.typeText(threshold)
            app.buttons["Continue"].tap()
            app.buttons["1 Minute"].tap()
            app.buttons["Continue"].tap()
            app.buttons["Create"].tap()
            XCTAssertTrue(app.navigationBars["Reminders"].waitForExistence(timeout: 5))
            app.navigationBars.buttons.firstMatch.tap()
        }

        for (context, itemPrefix, listTitle, editorTitle) in [
            ("reflections", "home.reflection.", "Reflections", "Edit Reflection"),
            ("reminders", "home.reminder.", "Reminders", "Edit Reminder")
        ] {
            app.buttons["home.context.\(context)"].tap()
            let scroll = app.scrollViews["home.content.\(context)"]
            let header = app.buttons["home.\(context).showAll"]
            for _ in 0..<5 where !header.isHittable { scroll.swipeUp() }
            let items = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", itemPrefix))
            XCTAssertEqual(items.count, 3)
            let identifiers = items.allElementsBoundByIndex.map(\.identifier)
            capture(app, "Home \(context) independent rows")
            for identifier in identifiers {
                let item = app.buttons[identifier]
                for _ in 0..<5 where !item.isHittable || item.frame.maxY > app.tabBars.firstMatch.frame.minY {
                    scroll.swipeUp()
                }
                let itemLabel = item.label
                item.tap()
                XCTAssertTrue(app.navigationBars[editorTitle].waitForExistence(timeout: 5))
                if context == "reminders" {
                    let measurement = app.descendants(matching: .any).matching(identifier: "reminder.editor.measurement").firstMatch
                    XCTAssertEqual(measurement.label.contains("Heart Rate"), itemLabel.contains("Heart Rate"))
                    XCTAssertFalse(app.buttons["reminder.editor.strength"].exists)
                }
                app.buttons["Cancel"].tap()
                XCTAssertTrue(header.waitForExistence(timeout: 5), "Closing an item must return to Home, without also pushing its list.")
                XCTAssertFalse(app.navigationBars[listTitle].exists)
            }
            for _ in 0..<5 where !header.isHittable { scroll.swipeDown() }
            // Tap unused top padding, outside both the header and the item buttons.
            header.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
                .withOffset(CGVector(dx: 0, dy: -8)).tap()
            XCTAssertTrue(app.navigationBars[listTitle].waitForExistence(timeout: 5), "The card surface must open the list.")
            app.navigationBars.buttons.firstMatch.tap()
            XCTAssertTrue(header.waitForExistence(timeout: 5))
            header.tap()
            XCTAssertTrue(app.navigationBars[listTitle].waitForExistence(timeout: 5), "The header must also open the list.")
            app.navigationBars.buttons.firstMatch.tap()
        }
    }

    @MainActor
    @discardableResult
    private func openNewReminderFromHome(_ app: XCUIApplication) -> Set<String> {
        app.buttons["home.context.reminders"].tap()
        let all = app.buttons["home.reminders.showAll"]
        for _ in 0..<5 where !all.isHittable || all.frame.maxY > app.tabBars.firstMatch.frame.minY {
            app.scrollViews["home.content.reminders"].swipeUp()
        }
        XCTAssertFalse(app.buttons["Create Reminder"].exists)
        all.tap()
        let previousIDs = Set(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "reminders.row.")).allElementsBoundByIndex.map(\.identifier))
        app.buttons["New Reminder"].tap()
        return previousIDs
    }

    @MainActor
    private func launchApp(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        // Keep each flow independent of the device mode saved by previous onboarding tests.
        app.launchArguments = [
            "-userHasSeenOnboarding", "YES", "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
            "-deviceMode", "iPhoneOnly"
        ] + extraArguments
        app.launch()
        return app
    }

    @MainActor
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
