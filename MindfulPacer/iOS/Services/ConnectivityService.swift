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
        case .initializing:    return "applewatch.radiowaves.left.and.right"
        case .noWatchPaired:   return "applewatch.slash"
        case .appNotInstalled: return "exclamationmark.applewatch"
        case .disconnected:    return "applewatch.slash"
        case .connected:       return "checkmark.applewatch"
        }
    }
    var color: Color {
        switch self {
        case .initializing: return .cyan
        case .noWatchPaired, .appNotInstalled, .disconnected: return .red
        case .connected: return .green
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
        case .checking:   return "wifi.exclamationmark"
        case .noResponse: return "wifi.slash"
        case .fast:       return "bolt.fill"
        case .normal:     return "wifi"
        case .slow:       return "tortoise.fill"
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

// MARK: - ConnectivityServiceProtocol

protocol ConnectivityServiceProtocol: Sendable {
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String : Any]) -> Void)
    func session(_ session: WCSession, didReceiveMessage message: [String: Any])
}

// MARK: - ConnectivityService

final class ConnectivityService: NSObject, ConnectivityServiceProtocol, WCSessionDelegate, ObservableObject, @unchecked Sendable {

    static let shared = ConnectivityService()

    @Published private var isPaired: Bool = false
    @Published private var isWatchAppInstalled: Bool = false
    @Published private var isReachable: Bool = false
    @Published private var lastLatency: TimeInterval?

    @Published private(set) var connectionStatus: WatchConnectionStatus = .initializing
    @Published private(set) var connectionSpeed: WatchConnectionSpeed = .noResponse

    private let session = WCSession.default
    private var pingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    private override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
        subscribeToStateChanges()
    }

    private func subscribeToStateChanges() {
        Publishers.CombineLatest4($isPaired, $isWatchAppInstalled, $isReachable, $lastLatency)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateConnectionStateEnums() }
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
            let ms = latency * 1000
            switch ms {
            case 0..<100:   connectionSpeed = .fast
            case 100..<500: connectionSpeed = .normal
            default:        connectionSpeed = .slow
            }
        } else {
            connectionSpeed = .checking
        }
    }

    func startPinging() {
        guard pingTimer == nil else { return }
        sendPing()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }

    func stopPinging() {
        pingTimer?.invalidate()
        pingTimer = nil
        Task { @MainActor in self.lastLatency = nil }
    }

    private func sendPing() {
        guard session.isReachable else { return }
        let startTime = Date()
        session.sendMessage([LogWire.keyType: LogWire.Kind.ping.rawValue], replyHandler: { _ in
            let latency = Date().timeIntervalSince(startTime)
            Task { @MainActor in self.lastLatency = latency }
        }, errorHandler: { _ in
            Task { @MainActor in self.lastLatency = nil }
        })
    }

    // MARK: - Log handling
    
    private func handleLogMessage(_ dict: [String: Any]) {
        guard let type = dict[LogWire.keyType] as? String else { return }
        switch type {
        case LogWire.Kind.log.rawValue:
            if let data = dict[LogWire.keyPayload] as? Data,
               let entry = try? JSONDecoder().decode(LogWireEntry.self, from: data) {
                Task { @MainActor in LiveLogsStore.shared.append(entry) }
            }
        case LogWire.Kind.logBatch.rawValue:
            guard let arr = dict[LogWire.keyEntries] as? [Data] else { return }
            let dec = JSONDecoder()
            let entries = arr.compactMap { try? dec.decode(LogWireEntry.self, from: $0) }
            Task { @MainActor in LiveLogsStore.shared.appendBatch(entries) }
        default:
            break
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let paired = session.isPaired
        let installed = session.isWatchAppInstalled
        let reachable = session.isReachable
        Task { @MainActor in
            self.isPaired = paired
            self.isWatchAppInstalled = installed
            self.isReachable = reachable
        }
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        let paired = session.isPaired
        let installed = session.isWatchAppInstalled
        Task { @MainActor in
            self.isPaired = paired
            self.isWatchAppInstalled = installed
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor in
            self.isReachable = reachable
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if let _ = message[LogWire.keyType] as? String {
            handleLogMessage(message)
            replyHandler([:])
            return
        }

        guard let commandString = message[MessageKeys.command] as? String,
              let command = MessageCommand(rawValue: commandString) else {
            replyHandler([:])
            return
        }

        if command == .ping {
            replyHandler(["ack": "pong"])
        } else {
            replyHandler([:])
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let _ = message[LogWire.keyType] as? String {
            handleLogMessage(message)
            return
        }

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

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        if let _ = userInfo[LogWire.keyType] as? String {
            handleLogMessage(userInfo)
        }
    }
}
