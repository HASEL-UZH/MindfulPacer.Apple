//
//  AppDelegate.swift
//

import UIKit
import UserNotifications
import BackgroundTasks

// MARK: - NotificationDelegate

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate {
    private let notificationDelegate = NotificationDelegate()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = notificationDelegate
        let completed = OnboardingStatus.isCompleted()
        WatchOnboardingBridge.shared.pushStatus(completed: completed)
        
        if DeviceMode.current() == .iPhoneOnly {
            Task { await MissedReflectionsMonitorService.shared.scheduleNextRun(in: 60) }
        } else {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: MissedReflectionsMonitorService.identifier)
        }
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        WatchOnboardingBridge.shared.pushStatus(completed: OnboardingStatus.isCompleted())
    }
}
