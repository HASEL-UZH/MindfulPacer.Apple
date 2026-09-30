import Testing
import Foundation
@testable import WatchOS

@MainActor
@Suite("Watch chart presentation")
struct WatchChartPresentationTests {
    @Test func heartRateHistoryRemainsVisibleWhenPaused() {
        let model = HomeViewModel.mock
        model.togglePauseResume()
        #expect(model.isManuallyPaused)
        #expect(model.hasHeartRateData)
        #expect(model.statusMessage == .paused)
    }

    @Test func heartRateScaleStartsTenBelowLowestSample() {
        let model = HomeViewModel.mock
        model.heartRateSamples = [(82, .now.addingTimeInterval(-60)), (88, .now)]
        #expect(model.heartRateChartYDomain.lowerBound == 72)
        #expect(model.heartRateChartYDomain.upperBound >= 110)
    }

    @Test func stepsUseZeroBaselineWithoutUnrelatedRollingThresholds() {
        let model = HomeViewModel.mock
        model.hourlyStepData = [(.now, 100)]
        #expect(model.stepsChartYDomain.lowerBound == 0)
        #expect(model.stepsChartYDomain.upperBound < 120)
    }

    @Test func singleReadingStillHasFullHourDomain() {
        let model = HomeViewModel.mock
        model.heartRateSamples = [(85, .now)]
        #expect(model.hasHeartRateData)
        #expect(model.heartRateChartDateRange.upperBound.timeIntervalSince(model.heartRateChartDateRange.lowerBound) == 3600)
    }

    @Test func emptyAndPausedStatesAreDistinct() {
        let model = HomeViewModel.mock
        model.hourlyStepData = []
        #expect(!model.hasStepsData)
        #expect(model.emptyState(for: .steps).symbol == "figure.walk")
        model.togglePauseResume()
        #expect(model.emptyState(for: .steps).symbol == "pause.circle.fill")
    }
}
