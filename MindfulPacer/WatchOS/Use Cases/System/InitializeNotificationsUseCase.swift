//
//  InitializeNotificationsUseCase.swift
//  WatchOS
//
//  Created by Grigor Dochev on 19.08.2024.
//

import Foundation

protocol InitializeNotificationsUseCase {
    func execute(completion: @escaping (Result<Void, Error>) -> Void)
}

// MARK: - Use Case Implementation

final class DefaultInitializeNotificationsUseCase: InitializeNotificationsUseCase {
    private let notificationService: NotificationService
    
    init(notificationService: NotificationService) {
        self.notificationService = notificationService
    }
    
    func execute(completion: @escaping (Result<Void, Error>) -> Void) {
        notificationService.requestNotificationAuthorization { result in
            completion(result)
        }
    }
}
