//
//  NotificationService.swift
//  iOS
//
//  Created by Grigor Dochev on 06.07.2024.
//

import Foundation
import UserNotifications

protocol NotificationServiceProtocol: Sendable {
    func requestNotificationAuthorization()
    func sendNotification(for heartRate: Double)
}

class NotificationService: NSObject, NotificationServiceProtocol, UNUserNotificationCenterDelegate, @unchecked Sendable {
    static let shared = NotificationService()

    func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                self.setupNotificationCategories()
            }
        }
    }

    func setupNotificationCategories() {
        let highHeartRateAction = UNNotificationAction(identifier: "HIGH_HEART_RATE_ACTION",
                                                       title: "Take Action",
                                                       options: .foreground)

        let lowHeartRateAction = UNNotificationAction(identifier: "LOW_HEART_RATE_ACTION",
                                                      title: "Good Job",
                                                      options: .foreground)

        let highHeartRateCategory = UNNotificationCategory(identifier: "HIGH_HEART_RATE",
                                                           actions: [highHeartRateAction],
                                                           intentIdentifiers: [],
                                                           options: [])

        let lowHeartRateCategory = UNNotificationCategory(identifier: "LOW_HEART_RATE",
                                                          actions: [lowHeartRateAction],
                                                          intentIdentifiers: [],
                                                          options: [])

        UNUserNotificationCenter.current().setNotificationCategories([highHeartRateCategory, lowHeartRateCategory])
    }

    func sendNotification(for heartRate: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Heart Rate Alert"

        if heartRate > 75 {
            content.body = "🔴 Your heart rate is \(Int(heartRate)) BPM, which is above the threshold."
            content.categoryIdentifier = "HIGH_HEART_RATE"
        } else {
            content.body = "🟢 Your heart rate is \(Int(heartRate)) BPM, which is below the threshold."
            content.categoryIdentifier = "LOW_HEART_RATE"
        }

        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    // Implement other UNUserNotificationCenterDelegate methods if needed
}
