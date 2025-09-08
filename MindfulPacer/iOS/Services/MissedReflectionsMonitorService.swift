//
//  MissedReflectionsMonitorService.swift
//  iOS
//
//  Created by Grigor Dochev on 07.09.2025.
//

import Foundation
import BackgroundTasks
import SwiftData
import UserNotifications
import SwiftUI

@MainActor
class MissedReflectionsMonitorService {
    
    static let shared = MissedReflectionsMonitorService()
    
    @AppStorage(DeviceMode.appStorageKey) private var deviceMode: DeviceMode = .iPhoneOnly
    
    private let taskIdentifier = "com.mindfulpacer.checkMissedReflections"
    
    private init() {}
    
    func scheduleAppRefresh() {
        guard deviceMode == .iPhoneOnly else {
            print("DEBUGY BG: Device mode is iPhone+Watch. Skipping background task scheduling.")
            return
        }
        
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("DEBUGY BG: iPhone-only mode is active. Missed reflections check task scheduled.")
        } catch {
            print("DEBUGY BG: Could not schedule task: \(error)")
        }
    }
    
    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            Task {
                await self.handleAppRefresh(task: task as! BGAppRefreshTask)
            }
        }
    }
    
    private func handleAppRefresh(task: BGAppRefreshTask) async {
        scheduleAppRefresh()
        
        guard deviceMode == .iPhoneOnly else {
            task.setTaskCompleted(success: true)
            return
        }
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        let modelContext = ModelContainer.prod.mainContext
        let fetchRemindersUseCase = DefaultFetchRemindersUseCase(modelContext: modelContext)
        let fetchReflectionsUseCase = DefaultFetchReflectionsUseCase(modelContext: modelContext)
        
        // This is your existing use case.
        let checkMissedReflectionsUseCase = DefaultFetchMissedReflectionsUseCase(
            modelContext: modelContext,
            healthKitService: HealthKitService.shared
        )
        
        let reminders = fetchRemindersUseCase.execute() ?? []
        let existingReflections = fetchReflectionsUseCase.execute() ?? []
        
        do {
            var newMissedReflections: [Reflection] = []
            
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                checkMissedReflectionsUseCase.execute(
                    reminders: reminders,
                    existingReflections: existingReflections
                ) { result in
                    switch result {
                    case .success(let refs):
                        newMissedReflections = refs
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            if !newMissedReflections.isEmpty {
                self.sendMissedReflectionsNotification(count: newMissedReflections.count)
            } else {
                print("DEBUGY BG: No new missed reflections found.")
            }
            
            task.setTaskCompleted(success: true)
        } catch {
            print("DEBUGY BG: Check missed reflections failed with error: \(error)")
            task.setTaskCompleted(success: false)
        }
    }
    
    private func sendMissedReflectionsNotification(count: Int) {
        let content = UNMutableNotificationContent()
        content.title = "You Have Missed Reflections"
        content.body = "You have \(count) new missed reflection(s) waiting for you."
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
