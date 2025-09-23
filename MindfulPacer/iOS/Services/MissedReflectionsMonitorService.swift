//
//  MissedReflectionsMonitorService.swift
//  iOS
//
//  Created by Grigor Dochev on 07.09.2025.
//

import Foundation
import BackgroundTasks
import UserNotifications
import SwiftUI

@MainActor
final class MissedReflectionsMonitorService {
    
    static let shared = MissedReflectionsMonitorService()
    
    private let taskIdentifier = "com.MindfulPacer.Apple.iOS.checkMissedReflections"
    
    private init() {}
    
    // MARK: - Public
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
            print("DEBUGY BG: Scheduled Missed Reflections check.")
        } catch {
            print("DEBUGY BG: Could not schedule task: \(error)")
        }
    }
    
    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            guard let refresh = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            // Hop to the main queue explicitly to avoid strict-concurrency 'Sendable' warnings.
            DispatchQueue.main.async {
                self.handleAppRefreshOnMain(task: refresh)
            }
        }
    }
    
    // MARK: - Private (MainActor)
    
    private func handleAppRefreshOnMain(task: BGAppRefreshTask) {
        // Always re-schedule first so the task stays alive.
        scheduleAppRefresh()
        
        var didComplete = false
        func complete(_ success: Bool) {
            guard !didComplete else { return }
            didComplete = true
            task.setTaskCompleted(success: success)
        }
        
        // If the system expires us, complete once.
        task.expirationHandler = {
            DispatchQueue.main.async {
                print("DEBUGY BG: Task expired.")
                complete(false)
            }
        }
        
        // Resolve use cases on main (avoids sending non-Sendable SwiftData models across actors/threads)
        let fetchRemindersUseCase = UseCasesContainer.shared.fetchRemindersUseCase()
        let fetchReflectionsUseCase = UseCasesContainer.shared.fetchReflectionsUseCase()
        let fetchMissedReflectionsUseCase = UseCasesContainer.shared.fetchMissedReflectionsUseCase()
        
        let reminders = fetchRemindersUseCase.execute() ?? []
        let existingReflections = fetchReflectionsUseCase.execute() ?? []
        
        // Bridge the callback without Swift concurrency primitives to dodge strict 'Sendable' checks.
        fetchMissedReflectionsUseCase.execute(
            reminders: reminders,
            existingReflections: existingReflections
        ) { result in
            switch result {
            case .success(let refs):
                let count = refs.count
                if count > 0 {
                    self.postMissedReflectionsNotification(count: count)
                } else {
                    print("DEBUGY BG: No new missed reflections found.")
                }
                complete(true)
            case .failure(let error):
                print("DEBUGY BG: Check missed reflections failed with error: \(error)")
                complete(false)
            }
        }
    }
    
    private func postMissedReflectionsNotification(count: Int) {
        let content = UNMutableNotificationContent()
        content.title = "You Have Missed Reflections"
        content.body  = "You have \(count) new missed reflection(s) waiting for you."
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
