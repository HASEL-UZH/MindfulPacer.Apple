import XCTest

/// Actual app screenshots backed by isolated, simulator-only fixtures.
/// Run this class explicitly; each launch starts with a fresh in-memory store.
final class RedesignScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        #if !targetEnvironment(simulator)
        throw XCTSkip("Screenshot fixtures are only available in the simulator.")
        #endif
        continueAfterFailure = false
    }

    @MainActor
    private func launch(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-redesign-capture", "-userHasSeenOnboarding", "YES", "-theme", "Light",
                               "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
                               "-deviceMode", "iPhoneOnly", "-modeOfUse", "expanded"] + extra
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 20))
        return app
    }

    @MainActor
    private func shot(_ app: XCUIApplication, _ name: String) {
        // Allow chart/layout and sheet animations to settle before the native screenshot.
        Thread.sleep(forTimeInterval: 0.7)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "catalog__" + name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func closeTopSheet(_ app: XCUIApplication) {
        let buttons = app.buttons.matching(identifier: "Close")
        buttons.element(boundBy: buttons.count - 1).tap()
    }

    @MainActor
    private func button(_ app: XCUIApplication, _ prefix: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }

    @MainActor
    private func reveal(_ element: XCUIElement, app: XCUIApplication, scroll: XCUIElement? = nil) {
        for _ in 0..<8 {
            if element.isHittable && element.frame.maxY < app.frame.maxY - 105 { return }
            (scroll ?? app).swipeUp()
        }
        XCTAssertTrue(element.isHittable)
    }

    @MainActor
    private func centerInList(_ element: XCUIElement, app: XCUIApplication) {
        for _ in 0..<14 {
            let exists = element.exists
            let middle = exists ? element.frame.midY : app.frame.maxY
            if exists && element.isHittable && middle > 180 && middle < app.frame.maxY - 120 { return }
            let list = app.collectionViews.firstMatch
            let start = list.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.6))
            let delta: CGFloat = exists && middle < 180 ? 240 : -240
            start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: delta)),
                        withVelocity: .slow, thenHoldForDuration: 0.2)
        }
        XCTAssertTrue(element.isHittable)
    }

    @MainActor
    private func homeList(_ app: XCUIApplication, _ context: String) {
        app.buttons["home.context." + context].tap()
        let all = app.buttons["home." + context + ".showAll"]
        reveal(all, app: app, scroll: app.scrollViews["home.content." + context])
        all.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.7)).tap()
    }

    @MainActor
    func test01HomeAndLists() {
        let app = launch()
        shot(app, "01-home-today")
        app.scrollViews["home.content.today"].swipeUp()
        shot(app, "02-home-today-recent-items")
        app.buttons["home.context.reflections"].tap()
        shot(app, "03-home-reflections")
        app.scrollViews["home.content.reflections"].swipeUp()
        shot(app, "04-home-reflections-missed")
        let missed = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Missed Reflections")).firstMatch
        reveal(missed, app: app, scroll: app.scrollViews["home.content.reflections"])
        missed.tap()
        XCTAssertTrue(app.buttons["missedReflections.filter"].waitForExistence(timeout: 5))
        shot(app, "05-missed-all")
        app.buttons["missedReflections.filter"].tap()
        shot(app, "06-missed-filter-menu")
        app.buttons["Heart Rate"].tap()
        shot(app, "07-missed-heart-rate")
        let chart = app.descendants(matching: .any).matching(identifier: "missedReflection.chart").firstMatch
        chart.coordinate(withNormalizedOffset: CGVector(dx: 0.65, dy: 0.5)).press(forDuration: 0.6)
        shot(app, "08-missed-chart-value")
        app.buttons["missedReflections.filter"].tap()
        app.buttons["Steps"].tap()
        shot(app, "09-missed-steps")
        app.buttons["Accept"].firstMatch.tap()
        shot(app, "10-missed-accept-reflection")
        app.buttons["Cancel"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        homeList(app, "reflections")
        shot(app, "11-reflections-list")
        let row = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "reflections.row.")).firstMatch
        row.tap()
        shot(app, "12-reflections-expanded-row")
        app.navigationBars.buttons.firstMatch.tap()
        homeList(app, "reflections")
        row.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5)).press(forDuration: 0.05, thenDragTo: row.coordinate(withNormalizedOffset: CGVector(dx: 0.45, dy: 0.5)))
        shot(app, "13-reflections-swipe-delete")
        if !app.alerts.firstMatch.exists { button(app, "Delete").tap() }
        shot(app, "14-reflections-delete-confirmation")
        app.alerts.buttons["Cancel"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["home.context.reminders"].tap()
        shot(app, "15-home-reminders")
        homeList(app, "reminders")
        shot(app, "16-reminders-list")
        let reminder = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "reminders.row.")).firstMatch
        reminder.tap()
        shot(app, "17-reminders-expanded-row")
        app.navigationBars.buttons.firstMatch.tap()
        homeList(app, "reminders")
        reminder.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5)).press(forDuration: 0.05, thenDragTo: reminder.coordinate(withNormalizedOffset: CGVector(dx: 0.45, dy: 0.5)))
        shot(app, "18-reminders-swipe-delete")
        if !app.alerts.firstMatch.exists { button(app, "Delete").tap() }
        shot(app, "19-reminders-delete-confirmation")
    }

    @MainActor
    func test02Analytics() {
        let app = launch()
        app.tabBars.buttons["Analytics"].tap()
        XCTAssertTrue(app.segmentedControls.buttons["Heart Rate"].waitForExistence(timeout: 8))
        for (metricIndex, metric) in ["Heart Rate", "Steps"].enumerated() {
            app.segmentedControls.buttons[metric].tap()
            for (periodIndex, period) in ["1H", "2H", "D", "W"].enumerated() {
                app.segmentedControls.buttons[period].tap()
                shot(app, String(format: "%02d-analytics-%@-%@", 20 + metricIndex * 4 + periodIndex, metric == "Heart Rate" ? "hr" : "steps", period.lowercased()))
            }
        }
        app.segmentedControls.buttons["Heart Rate"].tap()
        app.segmentedControls.buttons["1H"].tap()
        let row = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "analytics.reflectionRow.")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        shot(app, "28-analytics-selected-reflection")
        app.buttons["Edit Reflection"].firstMatch.tap()
        shot(app, "29-analytics-edit-reflection")
        app.buttons["Cancel"].tap()
        app.buttons["Selected Date"].tap()
        shot(app, "30-analytics-date-sheet")
    }

    @MainActor
    func test03ReflectionEditor() {
        let app = launch()
        app.buttons["Create Reflection"].tap()
        shot(app, "31-reflection-create-expanded")
        app.buttons["reflection.activity"].tap()
        shot(app, "32-reflection-activity-choices")
        for (index, activity) in ["Movement", "Household", "Selfcare", "Cognitive"].enumerated() {
            if index > 0 { app.buttons["reflection.activity"].tap() }
            app.buttons[activity].tap()
            app.buttons["reflection.subactivity"].tap()
            shot(app, "33\(index)-reflection-subactivities-\(activity.lowercased())")
            closeTopSheet(app)
        }
        app.buttons["reflection.subactivity"].tap()
        button(app, "Reading").tap()
        app.buttons["reflection.mood"].tap()
        shot(app, "34-reflection-mood-choices")
        app.buttons["Happy"].tap()
        app.buttons["reflection.wellbeing"].tap()
        shot(app, "35-reflection-wellbeing-choices")
        button(app, "3,").tap()
        shot(app, "36-reflection-selected-fields")
        app.swipeUp()
        shot(app, "37-reflection-symptoms-notes")
        app.buttons["Cancel"].tap()
        homeList(app, "reflections")
        let row = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "reflections.row.")).firstMatch
        row.tap()
        app.buttons["Edit Reflection"].firstMatch.tap()
        shot(app, "38-reflection-edit-populated")
        app.swipeUp()
        shot(app, "39-reflection-edit-symptoms")
        reveal(app.buttons["Delete Reflection"], app: app)
        app.buttons["Delete Reflection"].tap()
        shot(app, "40-reflection-editor-delete-confirmation")
    }

    @MainActor
    func test04EmptyAndHealthError() {
        var app = launch(["-capture-empty"])
        shot(app, "90-empty-home")
        homeList(app, "reflections")
        shot(app, "91-empty-reflections")
        app.navigationBars.buttons.firstMatch.tap()
        homeList(app, "reminders")
        shot(app, "92-empty-reminders")
        app.tabBars.buttons["Analytics"].tap()
        shot(app, "93-empty-analytics-heart-rate")
        app.segmentedControls.buttons["Steps"].tap()
        shot(app, "94-empty-analytics-steps")
        app.terminate()
        app = launch(["-capture-health-error"])
        shot(app, "95-home-health-permission-needed")
        app.tabBars.buttons["Analytics"].tap()
        shot(app, "96-analytics-health-fetch-error")
        app.terminate()
        app = launch(["-deviceMode", "iPhoneAndWatch"])
        shot(app, "97-home-watch-disconnected")
    }
}

extension RedesignScreenshotTests {
    @MainActor
    func test05ReminderCreation() {
        for metric in ["Heart Rate", "Steps"] {
            let key = metric == "Heart Rate" ? "hr" : "steps"
            let app = launch()
            homeList(app, "reminders")
            app.buttons["New Reminder"].tap()
            shot(app, "110-reminder-introduction")
            app.buttons["Get Started"].tap()
            shot(app, "111-reminder-measurement-unselected")
            button(app, metric).tap()
            shot(app, "112-reminder-measurement-\(key)")
            app.buttons["Continue"].tap()
            shot(app, "113-reminder-strength-unselected")
            for strength in ["Light", "Medium", "Strong"] {
                app.buttons[strength].tap()
                shot(app, "114-reminder-\(key)-strength-\(strength.lowercased())")
            }
            app.buttons["Learn More"].tap()
            shot(app, "115-reminder-strength-info")
            closeTopSheet(app)
            app.buttons["Continue"].tap()
            shot(app, "116-reminder-\(key)-threshold-empty")
            app.buttons["Learn More"].tap()
            shot(app, "117-reminder-\(key)-threshold-info")
            closeTopSheet(app)
            app.textFields.firstMatch.tap()
            app.textFields.firstMatch.typeText(metric == "Heart Rate" ? "100" : "500")
            shot(app, "118-reminder-\(key)-threshold-keyboard")
            app.buttons["Continue"].tap()
            shot(app, "119-reminder-\(key)-interval-unselected")
            let intervals = metric == "Heart Rate" ? ["1 Minute", "2 Minutes", "5 Minutes", "15 Minutes", "1 Hour"] : ["30 Minutes", "1 Hour", "2 Hours", "4 Hours", "1 Day"]
            for (index, interval) in intervals.enumerated() {
                let option = app.buttons[interval]
                reveal(option, app: app)
                option.tap()
                shot(app, "120\(index)-reminder-\(key)-interval-\(index + 1)")
            }
            let learn = app.buttons["Learn More"]
            reveal(learn, app: app)
            learn.tap()
            shot(app, "121-reminder-\(key)-interval-info")
            closeTopSheet(app)
            app.buttons["Continue"].tap()
            shot(app, "122-reminder-\(key)-review")
            app.buttons["reminder.editor.measurement"].tap()
            shot(app, "123-reminder-review-measurement-picker")
            app.buttons["Done"].tap()
            app.buttons["reminder.editor.strength"].tap()
            shot(app, "124-reminder-review-strength-picker")
            app.buttons["Done"].tap()
            app.buttons["reminder.editor.threshold"].tap()
            shot(app, "125-reminder-\(key)-review-threshold")
            app.buttons["Done"].tap()
            app.buttons["reminder.editor.interval"].tap()
            shot(app, "126-reminder-\(key)-review-interval")
            app.buttons["Done"].tap()
            app.buttons["Cancel"].tap()
            app.terminate()
        }
    }

    @MainActor
    func test06ReminderEditor() {
        let app = launch()
        homeList(app, "reminders")
        let rows = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "reminders.row."))
        let ids = rows.allElementsBoundByIndex.map(\.identifier).reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }
        for (index, id) in ids.enumerated() {
            let row = app.buttons[id].firstMatch
            reveal(row, app: app)
            let metric = row.label.contains("Heart Rate") ? "hr" : "steps"
            let strength = (row.label.contains("110") || row.label.contains("1000") || row.label.contains("1,000")) ? "strong" : ((row.label.contains("100") || row.label.contains("750")) ? "medium" : "light")
            row.tap()
            reveal(app.buttons["Edit Reminder"].firstMatch, app: app)
            app.buttons["Edit Reminder"].firstMatch.tap()
            shot(app, "130\(index)-reminder-editor-\(metric)-\(strength)")
            if index == 0 {
                app.buttons["reminder.editor.threshold"].tap()
                shot(app, "131-reminder-editor-threshold")
                app.buttons["Done"].tap()
                app.buttons["reminder.editor.interval"].tap()
                shot(app, "132-reminder-editor-interval")
                app.buttons["Done"].tap()
                app.buttons["Delete Reminder"].tap()
                shot(app, "133-reminder-editor-delete-confirmation")
                app.alerts.buttons["Cancel"].tap()
            }
            app.buttons["Cancel"].tap()

        }
    }

    @MainActor
    func test07Settings() {
        let app = launch()
        app.tabBars.buttons["Settings"].tap()
        shot(app, "200-settings-general")
        app.buttons["settings.theme"].tap()
        shot(app, "201-settings-theme-light")
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["settings.deviceMode"].tap()
        shot(app, "202-settings-device-phone")
        app.navigationBars.buttons.firstMatch.tap()
        let algorithms = button(app, "Algorithms")
        centerInList(algorithms, app: app)
        algorithms.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5)).tap()
        XCTAssertTrue(app.navigationBars["Algorithms"].waitForExistence(timeout: 5))
        shot(app, "203-settings-algorithms-hr")
        app.buttons["Steps"].tap()
        shot(app, "204-settings-algorithms-steps")
        app.navigationBars.buttons.firstMatch.tap()
        let manage = button(app, "Manage Data")
        centerInList(manage, app: app)
        manage.tap()
        shot(app, "205-settings-manage-data")
        button(app, "Data to Export").tap()
        shot(app, "206-settings-export-data-picker")
        app.navigationBars.buttons.firstMatch.tap()
        button(app, "File Format").tap()
        shot(app, "207-settings-export-format-picker")
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["Erase All Data"].tap()
        shot(app, "208-settings-erase-confirmation")
        app.alerts.buttons["Cancel"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        let notes = button(app, "Release Notes")
        centerInList(notes, app: app)
        shot(app, "209-settings-about")
        notes.tap()
        shot(app, "210-release-notes")
        app.swipeUp()
        shot(app, "211-release-notes-more")
        app.buttons["Done"].tap()
        app.swipeUp()
        shot(app, "212-settings-footer")
    }

    @MainActor
    func test08Outreach() {
        let app = launch()
        app.tabBars.buttons["Outreach"].tap()
        // Feed images are loaded from MindfulPacer's public site.
        Thread.sleep(forTimeInterval: 6)
        shot(app, "220-outreach-articles")
        app.swipeUp()
        shot(app, "221-outreach-community-resources")
        app.swipeDown()
        app.buttons["Show All"].firstMatch.tap()
        shot(app, "222-articles-list")
        app.swipeUp()
        shot(app, "223-articles-list-more")
        app.navigationBars.buttons.firstMatch.tap()
        let roadmap = button(app, "Roadmap")
        reveal(roadmap, app: app)
        roadmap.tap()
        Thread.sleep(forTimeInterval: 4)
        shot(app, "224-roadmap")
        app.swipeUp()
        shot(app, "225-roadmap-more")
    }
}

extension RedesignScreenshotTests {
    @MainActor
    private func startOnboarding(_ app: XCUIApplication) {
        app.tabBars.buttons["Settings"].tap()
        button(app, "Onboarding").tap()
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 5))
    }

    @MainActor
    func test09OnboardingPhone() {
        let app = launch()
        startOnboarding(app)
        shot(app, "300-onboarding-welcome")
        app.buttons["Continue"].tap()
        shot(app, "301-onboarding-main-features-top")
        app.swipeUp()
        shot(app, "302-onboarding-main-features-chart")
        app.swipeUp()
        shot(app, "303-onboarding-main-features-reflections")
        app.buttons["Continue"].tap()
        shot(app, "304-onboarding-device-phone")
        button(app, "iPhone + Apple Watch").tap()
        shot(app, "305-onboarding-device-watch")
        button(app, "iPhone Only").tap()
        app.buttons["Continue"].tap()
        shot(app, "306-onboarding-notifications")
        app.buttons["Allow Notifications"].tap()
        shot(app, "307-onboarding-health-phone")
        button(app, "Correct Permissions").tap()
        app.swipeUp()
        shot(app, "308-onboarding-health-phone-permissions")
        app.buttons["Continue"].tap()
        shot(app, "309-onboarding-activity-promoting-features")
        for (index, label) in ["Disabling Stand Reminders", "Disabling Activity Reminders", "Adjust Move Goals", "Disabling Breathe Reminders"].enumerated() {
            let row = button(app, label)
            reveal(row, app: app)
            row.tap()
            reveal(row, app: app)
            shot(app, "310\(index)-onboarding-disable-activity-\(index + 1)")
        }
        app.buttons["Continue"].tap()
        shot(app, "311-onboarding-mode-expanded")
        button(app, "Essentials").tap()
        shot(app, "312-onboarding-mode-essentials")
        app.buttons["Continue"].tap()
        shot(app, "313-onboarding-disclaimer")
        let acceptance = app.switches["I Understand and Accept"]
        reveal(acceptance, app: app)
        shot(app, "314-onboarding-disclaimer-not-accepted")
        acceptance.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
        shot(app, "315-onboarding-disclaimer-accepted")
        app.buttons["Finish"].tap()
        app.terminate()
        let essentials = launch(["-modeOfUse", "essentials"])
        essentials.buttons["Create Reflection"].tap()
        shot(essentials, "316-reflection-create-essentials")
    }

    @MainActor
    func test10OnboardingWatch() {
        let app = launch(["-deviceMode", "iPhoneAndWatch"])
        startOnboarding(app)
        app.buttons["Continue"].tap()
        app.buttons["Continue"].tap()
        app.buttons["Continue"].tap()
        shot(app, "320-onboarding-watch-connection")
        let install = button(app, "Installing on Apple Watch")
        reveal(install, app: app)
        install.tap()
        app.swipeUp()
        shot(app, "321-onboarding-watch-install")
        let complication = button(app, "Add to Your Watch Face")
        reveal(complication, app: app)
        complication.tap()
        let segmented = app.segmentedControls.firstMatch
        reveal(segmented, app: app)
        for type in ["Rectangular", "Circular", "Corner", "Inline"] {
            app.segmentedControls.buttons[type].tap()
            shot(app, "322-onboarding-complication-\(type.lowercased())")
        }
        let stay = button(app, "Stay in the App")
        reveal(stay, app: app)
        stay.tap()
        app.swipeUp()
        shot(app, "323-onboarding-stay-in-app")
        let more = app.buttons["More Info"]
        reveal(more, app: app)
        more.tap()
        shot(app, "324-onboarding-return-to-app-info")
        closeTopSheet(app)
        app.buttons["Continue"].tap()
        app.buttons["Allow Notifications"].tap()
        shot(app, "325-onboarding-health-watch")
        button(app, "Correct Permissions").tap()
        app.swipeUp()
        shot(app, "326-onboarding-health-watch-permissions")
    }

    @MainActor
    func test11ReflectionFilters() {
        let app = launch()
        homeList(app, "reflections")
        app.buttons["Filter Reflections"].tap()
        shot(app, "350-reflections-filter-dates-activities")
        button(app, "Movement").tap()
        shot(app, "351-reflections-filter-activity-selected")
        app.swipeUp()
        shot(app, "352-reflections-filter-subactivities")
        app.swipeUp()
        shot(app, "353-reflections-filter-moods")
        app.swipeUp()
        shot(app, "354-reflections-filter-crash-sorting")
    }

    @MainActor
    func test12SettingsWatch() {
        let app = launch(["-deviceMode", "iPhoneAndWatch"])
        app.tabBars.buttons["Settings"].tap()
        shot(app, "360-settings-watch-mode")
        app.buttons["settings.deviceMode"].tap()
        button(app, "Open Apple Watch Setup").tap()
        shot(app, "361-settings-watch-not-installed")
        app.navigationBars.buttons.firstMatch.tap()
        shot(app, "362-settings-device-watch-unavailable")
    }
}

extension RedesignScreenshotTests {
    @MainActor
    func test13ReflectionPickerVariations() {
        let app = launch()
        app.buttons["Create Reflection"].tap()
        for activity in ["Transportation", "Interactions & Social", "Work", "Others"] {
            app.buttons["reflection.activity"].tap()
            let choice = app.buttons[activity]
            reveal(choice, app: app)
            choice.tap()
            app.buttons["reflection.subactivity"].tap()
            shot(app, "370-reflection-subactivities-\(activity.lowercased().replacingOccurrences(of: " & ", with: "-").replacingOccurrences(of: " ", with: "-"))")
            closeTopSheet(app)
        }
        app.buttons["reflection.mood"].tap()
        app.swipeUp()
        shot(app, "371-reflection-moods-more")
        closeTopSheet(app)
        app.buttons["reflection.wellbeing"].tap()
        app.buttons["About This Scale"].tap()
        shot(app, "372-reflection-wellbeing-info")
        closeTopSheet(app)
        button(app, "4,").tap()
        app.buttons["reflection.wellbeing"].tap()
        shot(app, "373-reflection-wellbeing-selected")
        closeTopSheet(app)
        for (index, title) in ["Fatigue", "Shortness of Breath", "Sleep Disorder", "Cognitive Impairment", "Physical Pain", "Depression/Anxiety"].enumerated() {
            let row = button(app, title)
            reveal(row, app: app)
            row.tap()
            shot(app, "374\(index)-reflection-symptom-\(index + 1)")
            app.buttons["About This Scale"].tap()
            shot(app, "375\(index)-reflection-symptom-info-\(index + 1)")
            closeTopSheet(app)
            button(app, "3,").tap()
        }
        shot(app, "376-reflection-symptoms-selected")
    }

    @MainActor
    func test14SettingsReportAndExport() {
        let app = launch()
        app.tabBars.buttons["Settings"].tap()
        let manage = button(app, "Manage Data")
        centerInList(manage, app: app)
        manage.tap()
        button(app, "Data to Export").tap()
        app.buttons["Reflections"].tap()
        if !app.navigationBars["Manage Data"].exists { app.navigationBars.buttons.firstMatch.tap() }
        shot(app, "380-settings-export-reflections")
        button(app, "Data to Export").tap()
        app.buttons["Reminders"].tap()
        if !app.navigationBars["Manage Data"].exists { app.navigationBars.buttons.firstMatch.tap() }
        shot(app, "381-settings-reminders-export-selected")
        app.navigationBars.buttons.firstMatch.tap()
        let report = button(app, "MindfulPacer Version")
        centerInList(report, app: app)
        report.tap()
        shot(app, "383-settings-system-report")
        app.swipeUp()
        shot(app, "384-settings-system-report-more")
    }
}

extension RedesignScreenshotTests {
    @MainActor
    func test15SparseAndHistoricalAnalytics() {
        var app = launch(["-capture-single-reading"])
        app.tabBars.buttons["Analytics"].tap()
        shot(app, "400-analytics-single-heart-rate-reading")
        app.segmentedControls.buttons["2H"].tap()
        shot(app, "401-analytics-single-heart-rate-reading-2h")
        app.segmentedControls.buttons["Steps"].tap()
        shot(app, "402-analytics-single-steps-reading")
        app.terminate()
        app = launch()
        app.tabBars.buttons["Analytics"].tap()
        app.buttons["Selected Date"].tap()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM"
        let month = formatter.string(from: yesterday)
        let day = String(Calendar.current.component(.day, from: yesterday))
        let date = app.buttons.matching(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", month, day)).firstMatch
        XCTAssertTrue(date.exists, app.datePickers.debugDescription)
        date.tap()
        shot(app, "403-analytics-historical-date-selection")
        app.buttons["Done"].tap()
        for metric in ["Heart Rate", "Steps"] {
            app.segmentedControls.buttons[metric].tap()
            for period in ["D", "W"] {
                app.segmentedControls.buttons[period].tap()
                shot(app, "404-analytics-historical-\(metric == "Heart Rate" ? "hr" : "steps")-\(period.lowercased())")
            }
        }
    }
}

extension RedesignScreenshotTests {
    @MainActor
    func test16ReflectionFilterResults() {
        let app = launch()
        homeList(app, "reflections")
        app.buttons["Filter Reflections"].tap()
        reveal(app.buttons["Work"].firstMatch, app: app)
        app.buttons["Work"].firstMatch.tap()
        let confirm = app.navigationBars.buttons
        confirm.element(boundBy: confirm.count - 1).tap()
        XCTAssertTrue(app.staticTexts["No Results"].waitForExistence(timeout: 5))
        shot(app, "410-reflections-filter-no-results")
        app.buttons["Modify Filters"].tap()
        app.buttons["Clear All"].tap()
        app.buttons["Movement"].firstMatch.tap()
        confirm.element(boundBy: confirm.count - 1).tap()
        shot(app, "411-reflections-filter-movement-results")
        app.buttons["Filter Reflections"].tap()
        app.buttons["Clear All"].tap()
        let crash = app.switches["Triggered Crash Only"]
        reveal(crash, app: app)
        crash.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
        app.buttons["Oldest First"].tap()
        shot(app, "412-reflections-filter-crash-oldest-selected")
        confirm.element(boundBy: confirm.count - 1).tap()
        shot(app, "413-reflections-filter-crash-results")
    }
}
