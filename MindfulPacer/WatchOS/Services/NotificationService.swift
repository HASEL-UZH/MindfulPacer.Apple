//
//  NotificationService.swift
//  WatchOS
//
//  Created by Grigor Dochev on 19.08.2024.
//

import Foundation
import UserNotifications

// MARK: - NotificationServiceProtocol

protocol NotificationServiceProtocol: Sendable {
    func requestNotificationAuthorization(completion: @escaping (Result<Void, Error>) -> Void)
    func triggerLocalNotification(title: String, body: String, completion: @escaping (Result<Void, Error>) -> Void)
    func setDelegate()
}

// MARK: - NotificationService

final class NotificationService: NSObject, NotificationServiceProtocol, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    private override init() {
        super.init()
    }

    // MARK: - Setup

    func setDelegate() {
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Notification Authorization

    func requestNotificationAuthorization(completion: @escaping (Result<Void, Error>) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("DEBUG: Notification authorization failed with error: \(error.localizedDescription)")
                // Using custom error for authorization failure
                completion(.failure(NotificationError(type: .unknownError, underlyingError: error)))
            } else if granted {
                print("DEBUG: Notification authorization granted: \(granted)")
                completion(.success(()))
            } else {
                print("DEBUG: Notification authorization not granted.")
                // Using custom error for permission denied
                completion(.failure(NotificationError(type: .permissionDenied)))
            }
        }
    }

    // MARK: - Trigger Local Notification

    func triggerLocalNotification(title: String, body: String, completion: @escaping (Result<Void, Error>) -> Void) {
        print("DEBUG: triggerLocalNotification called")
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                // Using custom error for failure to send notification
                completion(.failure(NotificationError(type: .failedToSendNotification, underlyingError: error)))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge, .list])
    }
}
