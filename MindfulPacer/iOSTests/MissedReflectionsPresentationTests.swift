import XCTest
import SwiftUI
import SwiftData
import Factory
@testable import iOS

@MainActor
final class MissedReflectionsPresentationTests: XCTestCase {
    func testScrollingDoesNotPublishMovingChartFrames() async throws {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let samples = (0..<120).map {
            MissedReflectionTrendCard.Sample(date: start.addingTimeInterval(Double($0)), value: Double(90 + $0 % 20))
        }
        let data = MissedReflectionTrendCard.Data(
            title: "Heart Rate", systemImage: "heart.fill", headline: "Above 100 bpm",
            currentSummary: .init(label: "At trigger", value: "110", unit: "bpm", color: .pink),
            comparisonSummary: .init(label: "Threshold", value: "100", unit: "bpm", color: .yellow),
            currentSamples: samples, comparisonSamples: [], markerDate: start.addingTimeInterval(120),
            tint: .pink, layout: .compact, chartHeight: 176
        )
        let observations = ChartFrameObservations()
        let originalWindow = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows).first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: try XCTUnwrap(originalWindow?.windowScene))
        let host = UIHostingController(rootView: ScrollingCharts(data: data, observations: observations))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            originalWindow?.makeKeyAndVisible()
        }
        try await Task.sleep(for: .milliseconds(500))
        let scroll = try XCTUnwrap(findScrollView(in: host.view))
        XCTAssertGreaterThan(scroll.contentSize.height, scroll.bounds.height + 180)
        XCTAssertEqual(observations.frames.count, 3)
        let initialFrames = observations.frames
        let initialUpdates = observations.updates
        for step in 1...30 {
            scroll.setContentOffset(CGPoint(x: 0, y: step * 5), animated: false)
            try await Task.sleep(for: .milliseconds(20))
        }
        XCTAssertGreaterThan(scroll.contentOffset.y, 100)
        XCTAssertEqual(observations.updates - initialUpdates, 0,
                       "Scrolling must not invalidate the list through moving chart-frame preferences.")
        XCTAssertEqual(observations.frames, initialFrames)
    }

    func testMeasurementFilterPrecedesPaginationAndKeepsHomeTotals() throws {
        let model = try makeModel()
        let hearts = (0..<20).map { _ in reflection(type: .heartRate) }
        let steps = (0..<13).map { _ in reflection(type: .steps) }
        model.missedReflections = hearts + steps
        model.resetMissedPagination()
        XCTAssertEqual(model.displayedMissedReflections.map(\.id), Array(hearts.prefix(10)).map(\.id))

        model.missedMeasurementFilter = .steps
        XCTAssertEqual(model.displayedMissedReflections.map(\.id), Array(steps.prefix(10)).map(\.id))
        XCTAssertEqual(model.filteredMissedReflections.count, 13)
        XCTAssertEqual(model.missedReflections.count, 33, "The Home total must not be filtered.")
        XCTAssertTrue(model.canLoadMoreMissed)
        model.loadMoreMissed()
        XCTAssertEqual(model.displayedMissedReflections.map(\.id), steps.map(\.id))
        XCTAssertFalse(model.canLoadMoreMissed)

        model.missedMeasurementFilter = .heartRate
        XCTAssertEqual(model.displayedMissedReflections.count, 10, "A new filter starts on its first page.")
        model.missedReflections = steps
        model.clampMissedPaginationAfterMutation()
        XCTAssertEqual(model.missedVisibleCount, 0)
        XCTAssertTrue(model.filteredMissedReflections.isEmpty)
        XCTAssertFalse(model.canLoadMoreMissed)
        model.missedMeasurementFilter = nil
        XCTAssertEqual(model.displayedMissedReflections.count, 10)
        XCTAssertTrue(model.canLoadMoreMissed)
    }

    func testFilterInfersLegacyMeasurementTypeFromSamples() throws {
        let model = try makeModel()
        let legacy = reflection(type: nil)
        legacy.triggerSamples = [.init(type: .steps, value: 20, date: .now)]
        let unknown = reflection(type: nil)
        model.missedReflections = [legacy, unknown]
        model.missedMeasurementFilter = .steps
        XCTAssertEqual(model.displayedMissedReflections.map(\.id), [legacy.id])
        model.missedMeasurementFilter = .heartRate
        XCTAssertTrue(model.filteredMissedReflections.isEmpty)
        model.missedMeasurementFilter = nil
        XCTAssertEqual(model.displayedMissedReflections.count, 2)
    }

    func testRollingStepsRetainsBoundarySamplesAndExpiresOldSamples() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let item = reflection(type: .steps)
        item.interval = .thirtyMinutes
        item.threshold = 100
        item.triggerSamples = [
            .init(type: .steps, value: 10, date: start),
            .init(type: .steps, value: 20, date: start.addingTimeInterval(60)),
            .init(type: .steps, value: 30, date: start.addingTimeInterval(1_800)),
            .init(type: .steps, value: 40, date: start.addingTimeInterval(1_801)),
            .init(type: .steps, value: 50, date: start.addingTimeInterval(3_700))
        ].reversed()
        let chart = MissedReflectionHealthChartData(reflection: item).missedReflectionTrendCardData
        XCTAssertEqual(chart.currentSamples.map(\.value), [10, 30, 60, 90, 50])
        XCTAssertTrue(chart.yDomain.contains(100))
        item.interval = .oneDay
        XCTAssertEqual(MissedReflectionHealthChartData(reflection: item).missedReflectionTrendCardData.currentSamples.map(\.value),
                       [10, 30, 60, 100, 150])
    }

    private func reflection(type: Reminder.MeasurementType?) -> Reflection {
        Reflection(wellBeing: nil, fatigue: nil, shortnessOfBreath: nil, sleepDisorder: nil,
                   cognitiveImpairment: nil, physicalPain: nil, depressionOrAnxiety: nil,
                   measurementType: type, reminderType: .light, threshold: 100, interval: .oneMinute)
    }

    private func makeModel() throws -> HomeViewModel {
        let container = try ModelContainer(for: Reflection.self, configurations:
            ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        return HomeViewModel(
            modelContext: container.mainContext,
            checkHealthPermissionsUseCase: UseCasesContainer.shared.checkHealthPermissionsUseCase(),
            fetchCurrentHeartRateUseCase: UseCasesContainer.shared.fetchCurrentHeartRateUseCase(),
            fetchCurrentStepsUseCase: UseCasesContainer.shared.fetchCurrentStepsUseCase(),
            fetchHeartRateDataLast24HoursUseCase: UseCasesContainer.shared.fetchHeartRateDataLast24HoursUseCase(),
            fetchMissedReflectionsUseCase: UseCasesContainer.shared.fetchMissedReflectionsUseCase(),
            fetchStepDataLast24HoursUseCase: UseCasesContainer.shared.fetchStepDataLast24HoursUseCase()
        )
    }

    private func findScrollView(in view: UIView) -> UIScrollView? {
        if let scroll = view as? UIScrollView { return scroll }
        return view.subviews.lazy.compactMap { self.findScrollView(in: $0) }.first
    }
}

@MainActor
private final class ChartFrameObservations {
    var updates = 0
    var frames: [UUID: CGRect] = [:]
}

private struct ScrollingCharts: View {
    let data: MissedReflectionTrendCard.Data
    let observations: ChartFrameObservations
    @State private var frames: [UUID: CGRect] = [:]
    @State private var selection: UUID?

    var body: some View {
        ScrollView {
            VStack {
                MissedReflectionTrendCard(data: data)
                MissedReflectionTrendCard(data: data)
                MissedReflectionTrendCard(data: data)
                Color.clear.frame(height: 400)
            }
            .coordinateSpace(.named("missedReflectionCharts"))
            .gesture(MissedReflectionOutsideTapGesture(chartFrames: Array(frames.values)) { selection = nil })
        }
        .environment(\.missedReflectionSelectedChart, $selection)
        .onPreferenceChange(MissedReflectionChartFramesKey.self) {
            observations.updates += 1
            observations.frames = $0
            frames = $0
        }
    }
}
