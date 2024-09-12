//
//  iOSNotificationService.swift
//  iOS
//
//  Created by Grigor Dochev on 19.08.2024.
//

import Foundation
import UserNotifications
import CocoaLumberjackSwift

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
                let customError = NotificationError(type: .unknownError, underlyingError: error)
                DDLogError("Failed to request notification authorization: \(error.localizedDescription)")
                completion(.failure(customError))
            } else if granted {
                DDLogInfo("Notification authorization granted")
                completion(.success(()))
            } else {
                let deniedError = NotificationError(type: .permissionDenied)
                DDLogWarn("Notification authorization denied by the user")
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

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                let sendError = NotificationError(type: .failedToSendNotification, underlyingError: error)
                DDLogError("Failed to send local notification: \(error.localizedDescription)")
                completion(.failure(sendError))
            } else {
                DDLogInfo("Local notification triggered successfully with title: \(title)")
                completion(.success(()))
            }
        }
    }
}
