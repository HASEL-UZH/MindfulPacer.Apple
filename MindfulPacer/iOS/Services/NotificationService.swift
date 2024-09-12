//
//  iOSNotificationService.swift
//  iOS
//
//  Created by Grigor Dochev on 19.08.2024.
//

import Foundation
import UserNotifications

// MARK: - NotificationServiceProtocol

protocol NotificationServiceProtocol: Sendable {
    func requestNotificationAuthorization(completion: @escaping (Result<Void, NotificationError>) -> Void)
    func triggerLocalNotification(title: String, body: String, completion: @escaping (Result<Void, NotificationError>) -> Void)
}

// MARK: - NotificationService

final class NotificationService: NSObject, NotificationServiceProtocol {
    static let shared = NotificationService()

    private override init() {
        super.init()
    }

    // MARK: - Notification Authorization

    func requestNotificationAuthorization(completion: @escaping (Result<Void, NotificationError>) -> Void) {
        let notificationCenter = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]

        notificationCenter.requestAuthorization(options: options) { granted, error in
            if let error = error {
                // Wrap any underlying errors in your custom error type
                let customError = NotificationError(type: .unknownError, underlyingError: error)
                completion(.failure(customError))
            } else if granted {
                completion(.success(()))
            } else {
                // Use the custom error for permission denial
                let deniedError = NotificationError(type: .permissionDenied)
                completion(.failure(deniedError))
            }
        }
    }

    // MARK: - Trigger Local Notification

    func triggerLocalNotification(title: String, body: String, completion: @escaping (Result<Void, NotificationError>) -> Void) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        // No trigger for immediate notification
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                // Example usage of custom error for failed notification sending
                let sendError = NotificationError(type: .failedToSendNotification, underlyingError: error)
                completion(.failure(sendError))
            } else {
                completion(.success(()))
            }
        }
    }
}
