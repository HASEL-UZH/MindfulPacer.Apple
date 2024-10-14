//
//  InitializeNotificationsUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 11.09.2024.
//

import Foundation

protocol InitializeNotificationsUseCase {
    func execute(completion: @escaping @Sendable (Result<Void, NotificationError>) -> Void)
}

// MARK: - Use Case Implementation

final class DefaultInitializeNotificationsUseCase: InitializeNotificationsUseCase {
    private let notificationService: NotificationService

    init(notificationService: NotificationService) {
        self.notificationService = notificationService
    }

    func execute(completion: @escaping @Sendable (Result<Void, NotificationError>) -> Void) {
        notificationService.requestNotificationAuthorization { result in
            // Ensure the completion handler is called on the main thread if necessary.
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}
