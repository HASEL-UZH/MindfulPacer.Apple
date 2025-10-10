//
//  AppDelegate.swift
//

import UIKit
import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    // Show banners in foreground
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification,
                                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    private let notificationDelegate = NotificationDelegate()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // You request auth in onboarding; here we only set delegate so banners show in foreground.
        UNUserNotificationCenter.current().delegate = notificationDelegate

        // Optionally kick off an initial schedule so the handler can run later.
        Task { await HelloBGService.shared.schedule(in: 60) }
        return true
    }
}
