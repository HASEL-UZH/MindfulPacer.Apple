//
//  CheckInternetConnectivityUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 19.12.2024.
//

import Foundation
import Network

// MARK: - CheckInternetConnectivityUseCase Protocol

protocol CheckInternetConnectivityUseCase {
    func execute() async -> Bool
}

// MARK: - DefaultCheckInternetConnectivityUseCase

class DefaultCheckInternetConnectivityUseCase: CheckInternetConnectivityUseCase {
    private let networkMonitor: NetworkMonitorService

    init(networkMonitor: NetworkMonitorService) {
        self.networkMonitor = networkMonitor
    }

    func execute() async -> Bool {
        return await networkMonitor.isConnected()
    }
}
