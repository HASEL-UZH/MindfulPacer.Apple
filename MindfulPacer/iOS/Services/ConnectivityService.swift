//
//  ConnectivityService.swift
//  iOS
//
//  Created by Grigor Dochev on 06.07.2024.
//

import SwiftUI
import Combine
import Foundation
import WatchConnectivity

// MARK: - WatchConnectionStatus

enum WatchConnectionStatus: String {
    case initializing = "Initializing"
    case noWatchPaired = "No Watch Paired"
    case appNotInstalled = "App Not Installed"
    case disconnected = "Disconnected"
    case connected = "Active & Steady"

    var symbolName: String {
        switch self {
        case .initializing:
            return "applewatch.radiowaves.left.and.right"
        case .noWatchPaired:
            return "applewatch.slash"
        case .appNotInstalled:
            return "exclamationmark.applewatch"
        case .disconnected:
            return "applewatch.slash"
        case .connected:
            return "checkmark.applewatch"
        }
    }

    var color: Color {
        switch self {
        case .initializing:
            return .cyan
        case .noWatchPaired, .appNotInstalled, .disconnected:
            return .red
        case .connected:
            return .green
        }
    }
}

// MARK: - WatchConnectionSpeed

enum WatchConnectionSpeed: String {
    case checking = "Checking"
    case noResponse = "No Response"
    case fast = "Fast"
    case normal = "Normal"
    case slow = "Slow"

    var symbolName: String {
        switch self {
        case .checking:
            return "wifi.exclamationmark"
        case .noResponse:
            return "wifi.slash"
        case .fast:
            return "bolt.fill"
        case .normal:
            return "wifi"
        case .slow:
            return "tortoise.fill"
        }
    }

    var color: Color {
        switch self {
        case .fast: return .green
        case .normal: return .yellow
        case .slow: return .orange
        case .noResponse: return .red
        default: return .secondary
        }
    }
}

// MARK: - WatchEventCoordinator

@MainActor
class WatchEventCoordinator {
    static let shared = WatchEventCoordinator()
    let createReflectionSubject = PassthroughSubject<[(value: Double, date: Date)], Never>()
    let requestCreateReflectionSheetSubject = PassthroughSubject<Void, Never>()
    let openReflectionSubject = PassthroughSubject<(reflectionID: UUID, activityID: UUID?, subactivityID: UUID?), Never>()
    private init() {}
}

// MARK: - WatchOnboardingBridge

@MainActor
final class WatchOnboardingBridge {
    static let shared = WatchOnboardingBridge()
    private init() {}

    private var session: WCSession { .default }

    func pushStatus(completed: Bool) {
        guard WCSession.isSupported() else { return }
        let payload: [String: Any] = [
            OnboardingWire.keyType: OnboardingWire.typeOnboarding,
            OnboardingWire.keyOnboardingCompleted: completed
        ]
        if session.activationState == .activated {
            do {
                try session.updateApplicationContext(payload)
            } catch {
                session.transferUserInfo(payload)
            }
        } else {
            session.transferUserInfo(payload)
        }
    }

    func notifyCompletedNow() {
        guard WCSession.isSupported() else { return }
        if session.activationState == .activated {
            session.sendMessage(
                [MessageKeys.command: MessageCommand.onboardingCompleted.rawValue],
                replyHandler: nil, errorHandler: nil
            )
        }
        pushStatus(completed: true)
    }
}

// MARK: - ConnectivityServiceProtocol

protocol ConnectivityServiceProtocol: Sendable {
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String : Any]) -> Void)
    func session(_ session: WCSession, didReceiveMessage message: [String: Any])
}

// MARK: - ConnectivityService

@MainActor
final class ConnectivityService: NSObject, ConnectivityServiceProtocol, WCSessionDelegate, ObservableObject {

    static let shared = ConnectivityService()

    @Published private var isPaired: Bool = false
    @Published private var isWatchAppInstalled: Bool = false
    @Published private var isReachable: Bool = false
    @Published private var lastLatency: TimeInterval?

    @Published private(set) var connectionStatus: WatchConnectionStatus = .initializing
    @Published private(set) var connectionSpeed: WatchConnectionSpeed = .noResponse

    private let session = WCSession.default
    private var cancellables = Set<AnyCancellable>()

    private var pingTask: Task<Void, Never>?
    private var pingRefCount: Int = 0

    private let pingIntervalSeconds: TimeInterval = 30

    private let allowPingInRelease: Bool = true

    private override init() {
        super.init()

        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }

        subscribeToStateChanges()

        // Stop pinging when app backgrounds, resume only if someone requested it.
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.stopPingingAll()
            }
            .store(in: &cancellables)
    }

    private func subscribeToStateChanges() {
        Publishers.CombineLatest4($isPaired, $isWatchAppInstalled, $isReachable, $lastLatency)
            .sink { [weak self] _ in
                self?.updateConnectionStateEnums()
            }
            .store(in: &cancellables)
    }

    private func updateConnectionStateEnums() {
        if !isPaired {
            connectionStatus = .noWatchPaired
        } else if !isWatchAppInstalled {
            connectionStatus = .appNotInstalled
        } else if !isReachable {
            connectionStatus = .disconnected
        } else {
            connectionStatus = .connected
        }

        if !isReachable {
            connectionSpeed = .noResponse
        } else if let latency = lastLatency {
            let latencyMs = latency * 1000
            switch latencyMs {
            case 0..<100: connectionSpeed = .fast
            case 100..<500: connectionSpeed = .normal
            default: connectionSpeed = .slow
            }
        } else {
            connectionSpeed = .checking
        }
    }

    // MARK: - Public Ping API (reference-counted)

    /// Call when a screen wants “live” speed estimates.
    func startPinging() {
        guard canPing else { return }

        pingRefCount += 1
        if pingTask == nil {
            startPingLoop()
        }
    }

    /// Call when that screen goes away.
    func stopPinging() {
        pingRefCount = max(0, pingRefCount - 1)
        if pingRefCount == 0 {
            stopPingLoop()
        }
    }

    private func stopPingingAll() {
        pingRefCount = 0
        stopPingLoop()
    }

    private var canPing: Bool {
        #if DEBUG
        return true
        #else
        return allowPingInRelease
        #endif
    }

    private func startPingLoop() {
        // Defensive: never start twice
        pingTask?.cancel()

        pingTask = Task { [weak self] in
            guard let self else { return }

            // Immediate first ping for quick UI feedback
            await self.sendPingOnce()

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(self.pingIntervalSeconds * 1_000_000_000))

                if Task.isCancelled { break }

                // Only ping when it’s meaningful
                if self.session.isReachable, self.session.isPaired, self.session.isWatchAppInstalled {
                    await self.sendPingOnce()
                } else {
                    self.lastLatency = nil
                }
            }
        }
    }

    private func stopPingLoop() {
        pingTask?.cancel()
        pingTask = nil
        lastLatency = nil
    }

    private func sendPingOnce() async {
        guard session.isReachable else {
            lastLatency = nil
            return
        }

        let startTime = Date()
        session.sendMessage(
            [MessageKeys.command: MessageCommand.ping.rawValue],
            replyHandler: { [weak self] _ in
                guard let self else { return }
                let latency = Date().timeIntervalSince(startTime)
                Task { @MainActor in
                    self.lastLatency = latency
                }
            },
            errorHandler: { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    self.lastLatency = nil
                }
            }
        )
    }

    // MARK: - WCSessionDelegate

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let paired = session.isPaired
        let installed = session.isWatchAppInstalled
        let reachable = session.isReachable
        Task { @MainActor in
            self.isPaired = paired
            self.isWatchAppInstalled = installed
            self.isReachable = reachable
        }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        let paired = session.isPaired
        let installed = session.isWatchAppInstalled
        Task { @MainActor in
            self.isPaired = paired
            self.isWatchAppInstalled = installed
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor in
            self.isReachable = reachable
            if !reachable {
                self.lastLatency = nil
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) { session.activate() }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String : Any]) -> Void) {
        guard let commandString = message[MessageKeys.command] as? String,
              let command = MessageCommand(rawValue: commandString) else {
            replyHandler([:])
            return
        }

        switch command {
        case .ping:
            replyHandler(["ack": "pong"])

        case .requestOnboardingStatus:
            let completed = OnboardingStatus.isCompleted()
            replyHandler([
                MessageKeys.command: MessageCommand.onboardingStatus.rawValue,
                OnboardingWire.keyOnboardingCompleted: completed
            ])

        default:
            replyHandler([:])
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let commandString = message[MessageKeys.command] as? String,
              let command = MessageCommand(rawValue: commandString) else {
            return
        }

        switch command {
        case .openReflectionForEditing:
            guard let idString = message["reflection_id"] as? String,
                  let reflectionID = UUID(uuidString: idString) else { return }
            let activityID = (message["activity_id"] as? String).flatMap(UUID.init)
            let subactivityID = (message["subactivity_id"] as? String).flatMap(UUID.init)
            Task { @MainActor in
                WatchEventCoordinator.shared.openReflectionSubject.send(
                    (reflectionID: reflectionID, activityID: activityID, subactivityID: subactivityID)
                )
            }

        case .requestCreateReflection:
            Task { @MainActor in
                WatchEventCoordinator.shared.requestCreateReflectionSheetSubject.send()
            }

        default:
            break
        }
    }
}
