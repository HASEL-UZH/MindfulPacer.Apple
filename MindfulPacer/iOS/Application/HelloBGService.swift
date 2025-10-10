//
//  HelloBGService.swift
//

import Foundation
import BackgroundTasks
import UserNotifications

/// iOS 17+ only: used with SwiftUI `.backgroundTask(.appRefresh(...))`.
actor HelloBGService {
    static let shared = HelloBGService()
    nonisolated static let identifier = "com.MindfulPacer.Apple.iOS.hello"

    /// Called by the SwiftUI `.backgroundTask` modifier when iOS launches your task.
    func handleTask() async {
        // Do lightweight work.
        await postLocalNotification(
            title: "🎉 HelloBG ran",
            body: "Executed via SwiftUI .backgroundTask handler."
        )
        // Chain another run (optional but useful while testing).
        await schedule(in: 60)
        print("🚀 HelloBG completed @ \(Date())")
    }

    /// Ask iOS to run the task no earlier than `seconds` from now.
    func schedule(in seconds: TimeInterval) {
        let req = BGAppRefreshTaskRequest(identifier: Self.identifier)
        req.earliestBeginDate = Date(timeIntervalSinceNow: seconds)
        do {
            try BGTaskScheduler.shared.submit(req)
            print("🗓 HelloBG scheduled for ~\(Int(seconds))s from now")
        } catch {
            print("❌ HelloBG schedule failed:", error.localizedDescription)
        }
    }

    private func postLocalNotification(title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default

        _ = try? await UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString,
                                  content: content,
                                  trigger: nil)
        )
    }
}
