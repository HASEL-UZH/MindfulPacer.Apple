import XCTest
import SwiftUI
import SwiftData
@testable import iOS

/// Exercises the chart/reflection relationship with isolated data, without HealthKit or iCloud.
@MainActor
final class AnalyticsPresentationTests: XCTestCase {
    func testPopulatedChartAndReflectionSelection() async throws {
        let container = try ModelContainer(for: Reflection.self, configurations:
            ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        let context = container.mainContext
        let now = Date.now
        let reflection = Reflection(date: now.addingTimeInterval(-1_200),
                                    activity: Activity(name: "Reading", icon: "book"),
                                    mood: .init(emoji: "😊", text: "Happy"),
                                    wellBeing: 3, fatigue: nil, shortnessOfBreath: nil,
                                    sleepDisorder: nil, cognitiveImpairment: nil,
                                    physicalPain: nil, depressionOrAnxiety: nil)
        context.insert(reflection)
        try context.save()
        let viewModel = AnalyticsViewModel(modelContext: context,
                                          fetchHeartRateUseCase: SampleHeartRate(),
                                          fetchStepsUseCase: SampleSteps())
        viewModel.selectedDateForPeriod = now
        viewModel.onViewFirstAppear()
        await Task.yield()
        XCTAssertEqual(viewModel.selectedMeasurementType, .heartRate)
        XCTAssertEqual(viewModel.statChartSummaryMode, .average)
        XCTAssertFalse(viewModel.statChartData.isEmpty)
        XCTAssertEqual(viewModel.reflectionChips.count, 1)

        let originalWindow = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows).first(where: \.isKeyWindow)
        let scene = try XCTUnwrap(originalWindow?.windowScene)
        let window = UIWindow(windowScene: scene)
        let host = UIHostingController(rootView: AnalyticsView(viewModel: viewModel).modelContainer(container).tint(.brandPrimary))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            originalWindow?.makeKeyAndVisible()
        }
        try await Task.sleep(for: .milliseconds(500))
        capture(window, named: "Analytics populated heart rate")

        let chip = try XCTUnwrap(viewModel.reflectionChips.first)
        viewModel.activeReflectionChipID = chip.id
        viewModel.updateReflectionsInPeriod()
        XCTAssertEqual(viewModel.activeReflectionChipID, chip.id, "A data refresh must preserve the selected reflection.")
        XCTAssertEqual(viewModel.reflectionsInPeriod.first?.reflections.first?.id, reflection.id)
        try await Task.sleep(for: .milliseconds(300))
        capture(window, named: "Analytics selected reflection")

        viewModel.selectedMeasurementType = .steps
        await Task.yield()
        XCTAssertNil(viewModel.activeReflectionChipID)
        XCTAssertFalse(viewModel.statChartData.isEmpty)
        try await Task.sleep(for: .milliseconds(300))
        capture(window, named: "Analytics populated steps 1H")
        for period in [Period.twoHours, .day, .week] {
            viewModel.selectedPeriod = period
            await Task.yield()
            try await Task.sleep(for: .milliseconds(300))
            capture(window, named: "Analytics populated steps \(period)")
        }

        viewModel.activeReflectionChipID = chip.id
        context.delete(reflection)
        try context.save()
        viewModel.updateReflectionsInPeriod()
        XCTAssertNil(viewModel.activeReflectionChipID, "Deleting the selected reflection must clear its chart marker.")
    }

    func testVisibleWindowFiltersReflectionsAndPeriodReset() async throws {
        let container = try ModelContainer(for: Reflection.self, configurations:
            ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        let context = container.mainContext
        let end = Date.now
        let recent = reflection(at: end.addingTimeInterval(-1_200))
        let earlier = reflection(at: end.addingTimeInterval(-5_400))
        context.insert(recent)
        context.insert(earlier)
        try context.save()
        let model = AnalyticsViewModel(modelContext: context, fetchHeartRateUseCase: SampleHeartRate(),
                                       fetchStepsUseCase: SampleSteps())
        model.onViewFirstAppear()
        XCTAssertEqual(model.reflectionsInPeriod.flatMap(\.reflections).map(\.id), [recent.id])
        model.activeReflectionChipID = model.reflectionChips.first?.id
        model.visibleWindow = .init(startDate: end.addingTimeInterval(-7_200),
                                    endDate: end.addingTimeInterval(-3_600), period: .oneHour)
        XCTAssertEqual(model.reflectionsInPeriod.flatMap(\.reflections).map(\.id), [earlier.id])
        XCTAssertNil(model.activeReflectionChipID)
        let revision = model.chartRevision
        model.selectedPeriod = .day
        XCTAssertNotEqual(revision, model.chartRevision)
        XCTAssertEqual(model.visibleWindow?.startDate, Calendar.current.startOfDay(for: end))
        XCTAssertEqual(model.visibleWindow?.endDate, Calendar.current.date(byAdding: .day, value: 1,
                                                                          to: Calendar.current.startOfDay(for: end)))
        XCTAssertLessThan(model.chartDateDomain.lowerBound, end.addingTimeInterval(-6 * 86_400))
        await Task.yield()
    }

    func testStaleHealthResponseCannotReplaceNewPeriod() async throws {
        let container = try ModelContainer(for: Reflection.self, configurations:
            ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        let source = DeferredHeartRate()
        let model = AnalyticsViewModel(modelContext: container.mainContext, fetchHeartRateUseCase: source,
                                       fetchStepsUseCase: SampleSteps())
        model.onViewFirstAppear()
        model.selectedPeriod = .day
        XCTAssertEqual(source.requests.count, 2)
        XCTAssertGreaterThan(source.requests[0].end.timeIntervalSince(source.requests[0].start), 6 * 86_400)
        source.requests[1].completion(.success([.init(startDate: .now, endDate: .now, value: 82)]))
        await Task.yield()
        source.requests[0].completion(.success([.init(startDate: .now, endDate: .now, value: 140)]))
        await Task.yield()
        XCTAssertEqual(model.statChartData.map(\.value), [82])
        XCTAssertFalse(model.isLoading)
        model.visibleWindow = .init(startDate: Date.now.addingTimeInterval(-2 * 86_400),
                                    endDate: Date.now.addingTimeInterval(-86_400), period: .day)
        let window = model.visibleWindow
        model.onSheetDismissed()
        XCTAssertEqual(model.visibleWindow, window, "Closing an editor must not jump the chart back to today.")
    }

    func testStepsUseCumulativeLinesAndWeeklyTotals() async throws {
        let container = try ModelContainer(for: Reflection.self, configurations:
            ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        let model = AnalyticsViewModel(modelContext: container.mainContext,
                                      fetchHeartRateUseCase: SampleHeartRate(), fetchStepsUseCase: SampleSteps())
        model.selectedMeasurementType = .steps
        for period in [Period.oneHour, .twoHours, .day] {
            model.selectedPeriod = period
            model.refreshChart()
            await Task.yield()
            guard case .line = model.statChartMarkStyle else { return XCTFail("Short steps periods must use a line.") }
            XCTAssertEqual(model.getXUnitForPeriod(period), .minute, "15-minute samples must not be collapsed into hourly marks.")
            XCTAssertEqual(model.statChartSummaryMode, .latest)
            let window = try XCTUnwrap(model.visibleWindow)
            let raw = model.stepsChartData.filter { $0.date >= window.startDate && $0.date < window.endDate }
            XCTAssertFalse(raw.isEmpty)
            XCTAssertEqual(model.statChartData.last?.value, raw.reduce(0) { $0 + $1.value })
            XCTAssertTrue(zip(model.statChartData, model.statChartData.dropFirst()).allSatisfy { $0.value <= $1.value })
            let values = model.statChartData.map(\.value)
            model.visibleWindow = .init(startDate: window.startDate.addingTimeInterval(-86_400),
                                        endDate: window.endDate.addingTimeInterval(-86_400), period: window.period)
            XCTAssertFalse(model.statChartData.isEmpty, "Scrolling into loaded history must show cumulative steps.")
            model.visibleWindow = window
            XCTAssertEqual(model.statChartData.map(\.value), values, "Revisiting a window must not accumulate the totals again.")
        }
        model.selectedPeriod = .week
        await Task.yield()
        guard case .bar = model.statChartMarkStyle else { return XCTFail("Weekly steps must use daily bars.") }
        XCTAssertEqual(model.statChartSummaryMode, .total)
        XCTAssertEqual(model.statChartData, model.weeklyStepsChartData)
    }

    private func reflection(at date: Date) -> Reflection {
        Reflection(date: date, activity: Activity(name: "Reading", icon: "book"), mood: nil,
                   wellBeing: 3, fatigue: nil, shortnessOfBreath: nil, sleepDisorder: nil,
                   cognitiveImpairment: nil, physicalPain: nil, depressionOrAnxiety: nil)
    }

    private func capture(_ window: UIWindow, named name: String) {
        window.layoutIfNeeded()
        let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

private struct SampleHeartRate: FetchHeartRateUseCase {
    func executeHistory(for period: Period, startDate: Date, endDate: Date,
                        completion: @escaping @Sendable (Result<[ChartDataItem], HealthKitError>) -> Void) {
        let count = Int(endDate.timeIntervalSince(startDate) / 120)
        completion(.success((0...count).map { index in
            let date = startDate.addingTimeInterval(Double(index) * 120)
            return ChartDataItem(startDate: date, endDate: date,
                                 value: 76 + sin(Double(index) * 0.6) * 9)
        }))
    }

    func execute(for period: Period, endDate: Date,
                 completion: @escaping @Sendable (Result<[ChartDataItem], HealthKitError>) -> Void) {
        completion(.success((0..<30).map { index in
            let date = endDate.addingTimeInterval(Double(index - 29) * 120)
            return ChartDataItem(startDate: date, endDate: date,
                                 value: 76 + sin(Double(index) * 0.6) * 9 + (index > 10 && index < 18 ? 20 : 0))
        }))
    }
}

private struct SampleSteps: FetchStepsUseCase {
    func executeHistory(for period: Period, startDate: Date, endDate: Date,
                        completion: @escaping @Sendable (Result<[ChartDataItem], HealthKitError>) -> Void) {
        let interval: TimeInterval = period == .week ? 86_400 : 900
        let count = Int(endDate.timeIntervalSince(startDate) / interval)
        completion(.success((0..<count).map { index in
            let date = startDate.addingTimeInterval(Double(index) * interval)
            return ChartDataItem(startDate: date, endDate: date.addingTimeInterval(interval),
                                 value: Double((index % 7 + 1) * 62))
        }))
    }

    func execute(for period: Period, endDate: Date,
                 completion: @escaping @Sendable (Result<[ChartDataItem], HealthKitError>) -> Void) {
        completion(.success((0..<30).map { index in
            let date = endDate.addingTimeInterval(Double(index - 29) * 120)
            return ChartDataItem(startDate: date, endDate: date, value: Double(index * 62))
        }))
    }

    func executeBucketed(for period: Period, endDate: Date,
                         completion: @escaping @Sendable (Result<[ChartDataItem], HealthKitError>) -> Void) {
        execute(for: period, endDate: endDate, completion: completion)
    }
}

// Calls and delivery are controlled on the test's main actor.
private final class DeferredHeartRate: FetchHeartRateUseCase {
    struct Request {
        let start: Date
        let end: Date
        let completion: @Sendable (Result<[ChartDataItem], HealthKitError>) -> Void
    }
    var requests: [Request] = []
    func execute(for period: Period, endDate: Date,
                 completion: @escaping @Sendable (Result<[ChartDataItem], HealthKitError>) -> Void) {
        executeHistory(for: period, startDate: period.startDate(relativeTo: endDate),
                       endDate: endDate, completion: completion)
    }
    func executeHistory(for period: Period, startDate: Date, endDate: Date,
                        completion: @escaping @Sendable (Result<[ChartDataItem], HealthKitError>) -> Void) {
        requests.append(.init(start: startDate, end: endDate, completion: completion))
    }
}
