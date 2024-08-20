//
//  TriggerWatchNotificationUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 19.08.2024.
//

import Foundation

import Foundation

protocol TriggerWatchNotificationUseCase {
    func execute(title: String, body: String, completion: @escaping (Result<Void, Error>) -> Void)
}

// MARK: - Use Case Implementation

final class DefaultTriggerWatchNotificationUseCase: TriggerWatchNotificationUseCase {
    private let notificationService: NotificationServiceProtocol
    
    init(notificationService: NotificationServiceProtocol = NotificationService.shared) {
        self.notificationService = notificationService
    }
    
    func execute(title: String, body: String, completion: @escaping (Result<Void, Error>) -> Void) {
        notificationService.triggerLocalNotification(title: title, body: body, completion: completion)
    }
}
