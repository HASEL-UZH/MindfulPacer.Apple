//
//  MonitoringControlActionTests.swift
//  WatchOSTests
//
//  Tests for `MonitoringControlAction`, which decides what the monitoring
//  button in Controls does. The button must always offer an action: when the
//  system ends the workout (for example while the Watch charges), monitoring is
//  neither running nor paused, and the button used to be disabled in that state.
//

import Testing
@testable import WatchOS

@MainActor
@Suite("MonitoringControlAction")
struct MonitoringControlActionTests {

    /// A running session can be paused.
    @Test func runningSessionOffersPause() {
        #expect(MonitoringControlAction(isSessionActive: true, isManuallyPaused: false) == .pause)
    }

    /// A manual pause can be resumed.
    @Test func manualPauseOffersResume() {
        #expect(MonitoringControlAction(isSessionActive: false, isManuallyPaused: true) == .resume)
    }

    /// Neither running nor paused must still offer a way back into monitoring.
    @Test func stoppedSessionOffersRestart() {
        #expect(MonitoringControlAction(isSessionActive: false, isManuallyPaused: false) == .restart)
    }

    /// A manual pause wins over a session flag that has not been cleared yet.
    @Test func manualPauseWinsOverActiveSession() {
        #expect(MonitoringControlAction(isSessionActive: true, isManuallyPaused: true) == .resume)
    }

    /// Only pausing stops monitoring; the other two actions start it.
    @Test func onlyPauseStopsMonitoring() {
        #expect(!MonitoringControlAction.pause.startsMonitoring)
        #expect(MonitoringControlAction.resume.startsMonitoring)
        #expect(MonitoringControlAction.restart.startsMonitoring)
    }

    /// The Controls button brings monitoring back from the stuck state.
    @Test func controlsRestartMonitoringWhenNotMonitoring() {
        let model = HomeViewModel.mock
        model.isMonitoring = false
        model.isManuallyPaused = false
        model.statusMessage = .notMonitoring

        #expect(model.monitoringControlAction == .restart)
        model.togglePauseResume()

        #expect(model.isMonitoring)
        #expect(!model.isManuallyPaused)
        #expect(model.statusMessage == .monitoring)
    }

    /// Pausing and resuming from Controls still round-trips.
    @Test func controlsPauseAndResume() {
        let model = HomeViewModel.mock

        model.togglePauseResume()
        #expect(model.isManuallyPaused)
        #expect(!model.isMonitoring)
        #expect(model.monitoringControlAction == .resume)

        model.togglePauseResume()
        #expect(!model.isManuallyPaused)
        #expect(model.isMonitoring)
        #expect(model.monitoringControlAction == .pause)
    }
}
