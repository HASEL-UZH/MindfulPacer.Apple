//
//  InitializeConnectivityUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 17.08.2024.
//

import Foundation

protocol InitializeConnectivityUseCase {
    func execute()
}

// MARK: - Use Case Implementation

final class DefaultInitializeConnectivityUseCase: InitializeConnectivityUseCase {
    private let connectivityService: ConnectivityService
    
    init(connectivityService: ConnectivityService) {
        self.connectivityService = connectivityService
    }
    
    func execute() {
        connectivityService.initializeSession { result in
            switch result {
            case .success(let success):
                print("Session initialized")
            case .failure(let failure):
                print("Failed to initialize session")
            }
        }
    }
}
