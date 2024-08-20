//
//  InitializeNotificationsUseCase.swift
//  WatchOS
//
//  Created by Grigor Dochev on 19.08.2024.
//

import Foundation

protocol InitializeNotificationsUseCase {
    func execute()
}

// MARK: - Use Case Implementation

final class DefaultInitializeNotificationsUseCase: InitializeNotificationsUseCase {
    private let watchNotificationService: NotificationService
    
    init(watchNotificationService: NotificationService) {
        self.watchNotificationService = watchNotificationService
    }
    
    func execute() {
        // TODO: Add error handling
        watchNotificationService.requestNotificationAuthorization()
    }
}
