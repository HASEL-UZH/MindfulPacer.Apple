//
//  NetworkMonitorService.swift
//  iOS
//
//  Created by Grigor Dochev on 19.12.2024.
//

import Foundation
import Network

// MARK: - NetworkMonitorServiceProtocol

protocol NetworkMonitorServiceProtocol {
    func isConnected() async -> Bool
}

// MARK: - NetworkMonitorService

actor NetworkMonitorService: NetworkMonitorServiceProtocol {
    static let shared = NetworkMonitorService()

    private let monitor: NWPathMonitor
    private var currentStatus: Bool = true

    init() {
        self.monitor = NWPathMonitor()

        monitor.pathUpdateHandler = { [weak self] path in
            Task { [weak self] in
                await self?.updateStatus(isConnected: path.status == .satisfied)
            }
        }
        monitor.start(queue: DispatchQueue(label: "NetworkMonitorService"))
    }

    // MARK: - isConnected

    func isConnected() async -> Bool {
        return currentStatus
    }

    // MARK: - updateStatus

    private func updateStatus(isConnected: Bool) {
        currentStatus = isConnected
    }
}
