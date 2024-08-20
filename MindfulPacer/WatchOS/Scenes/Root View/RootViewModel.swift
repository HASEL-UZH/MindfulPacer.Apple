//
//  RootViewModel.swift
//  WatchOS
//
//  Created by Grigor Dochev on 16.07.2024.
//

import Foundation
import UserNotifications
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
        initializeNotificationsUseCase.execute()
        initializeConnectivityUseCase.execute()
    }
}
