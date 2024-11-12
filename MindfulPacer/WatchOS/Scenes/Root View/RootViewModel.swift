//
//  RootViewModel.swift
//  WatchOS
//
//  Created by Grigor Dochev on 16.07.2024.
//

import Foundation

@Observable
class RootViewModel {
    // MARK: - Dependencies

    private let initializeNotificationsUseCase: InitializeNotificationsUseCase
    private let initializeConnectivityUseCase: InitializeConnectivityUseCase

    // MARK: - Initialization

    init(
        initializeNotificationsUseCase: InitializeNotificationsUseCase,
        initializeConnectivityUseCase: InitializeConnectivityUseCase
    ) {
        self.initializeNotificationsUseCase = initializeNotificationsUseCase
        self.initializeConnectivityUseCase = initializeConnectivityUseCase
    }

    // MARK: View Events

    func onViewFirstAppear() {
        initializeNotificationsUseCase.execute { result in
            switch result {
            case .success:
                print("Successfully initialized notifications")
            case .failure(let error):
                print("Failed to initialize notifications: \(error.localizedDescription)")
            }
        }
        initializeConnectivityUseCase.execute()
    }
}
