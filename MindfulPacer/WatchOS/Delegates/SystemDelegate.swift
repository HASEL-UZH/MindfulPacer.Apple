//
//  SystemDelegate.swift
//  WatchOS
//
//  Created by Grigor Dochev on 10.08.2025.
//

import Foundation
import UserNotifications
import WatchConnectivity
import SwiftData

class SystemDelegate: NSObject, @preconcurrency UNUserNotificationCenterDelegate, WCSessionDelegate, @unchecked Sendable {
        
    private let alertCacheKey = "com.mindfulpacer.alertDataCache"

    private var fetchRemindersUseCase: FetchRemindersUseCase?
    private var createReflectionUseCase: CreateReflectionUseCase?
    private var alertDataCache: [UUID: [MeasurementSample]] = [:]

    @MainActor
    func configure() {
        guard self.fetchRemindersUseCase == nil else { return }
        
        print("DEBUGY: Configuring SystemDelegate with use cases.")
        let modelContext = ModelContainer.prod.mainContext
        self.fetchRemindersUseCase = DefaultFetchRemindersUseCase(modelContext: modelContext)
        self.createReflectionUseCase = DefaultCreateReflectionUseCase(modelContext: modelContext)
    }
    
    override init() {
        super.init()
    }
    
    @MainActor
       func cacheTriggerData(_ data: [MeasurementSample], for alertID: UUID) {
           print("DEBUGY: Encoding and caching \(data.count) samples for alertID \(alertID) in UserDefaults.")
           do {
               // Get the existing cache, or a new one.
               var cache = retrieveFullCache()
               
               // Encode the data to a Data blob.
               let encodedData = try JSONEncoder().encode(data)
               
               // Save it using the alertID as the key.
               cache[alertID.uuidString] = encodedData
               
               // Write the entire updated cache dictionary back to UserDefaults.
               let cacheData = try JSONEncoder().encode(cache)
               UserDefaults.standard.set(cacheData, forKey: alertCacheKey)
           } catch {
               print("DEBUGY: ERROR - Failed to encode and cache trigger data: \(error)")
           }
       }
       
    
    private func retrieveTriggerData(for alertID: UUID) -> [MeasurementSample]? {
           print("DEBUGY: Retrieving data for alertID \(alertID) from UserDefaults.")
           // Get the full cache dictionary.
           var cache = retrieveFullCache()
           
           // Find the data for our specific ID.
           guard let data = cache[alertID.uuidString] else {
               print("DEBUGY: ERROR - No data found in UserDefaults cache for alertID \(alertID).")
               return nil
           }
           
           // Remove the data now that we've used it to keep the cache clean.
           cache.removeValue(forKey: alertID.uuidString)
           
           // Write the cleaned cache back.
           try? UserDefaults.standard.set(JSONEncoder().encode(cache), forKey: alertCacheKey)
           
           // Decode the data and return it.
           return try? JSONDecoder().decode([MeasurementSample].self, from: data)
       }

    private func retrieveFullCache() -> [String: Data] {
        guard let data = UserDefaults.standard.data(forKey: alertCacheKey),
              let cache = try? JSONDecoder().decode([String: Data].self, from: data) else {
            return [:]
        }
        return cache
    }
    
    @MainActor
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        if response.actionIdentifier == "VIEW_DETAILS_ACTION" {
            if let idString = userInfo["alert_id"] as? String, let alertID = UUID(uuidString: idString) {
                Services.shared.navigationManager.selectedAlertID = alertID
            }
            completionHandler()
            return
        }
        
        guard let alertIDString = userInfo["alert_id"] as? String,
              let alertID = UUID(uuidString: alertIDString),
              let reminderIDString = userInfo["reminder_id"] as? String,
              let reminderID = UUID(uuidString: reminderIDString) else {
            completionHandler()
            return
        }
        
        switch response.actionIdentifier {
        case "ACCEPT_ADD_DETAILS_ACTION":
            Services.shared.navigationManager.pendingActivitySelection = ActivitySelectionInfo(
                id: alertID,
                reminderID: reminderID
            )
            
        case "ACCEPT_LATER_ACTION":
            _ = createReflectionFromNotification(reminderID: reminderID, alertID: alertID)
            
        default:
            break
        }
        
        completionHandler()
    }
    
    @MainActor
    func createAndSendReflection(reminderID: UUID, alertID: UUID, activity: Activity?, subactivity: Subactivity?) {
        guard let fetchRemindersUseCase else { return }
        guard let allReminders = fetchRemindersUseCase.execute(),
              let reminder = allReminders.first(where: { $0.id == reminderID }) else {
            print("DEBUGY: Could not find reminder with ID \(reminderID).")
            return
        }
        
        let triggerSamples = self.retrieveTriggerData(for: alertID) ?? []

        print("DEBUGY: triggerSamples", triggerSamples)
        
        guard let createReflectionUseCase else { return }
        let result = createReflectionUseCase.execute(
            date: Date(),
            activity: activity,
            subactivity: subactivity,
            mood: nil, didTriggerCrash: false,
            wellBeing: nil, fatigue: nil, shortnessOfBreath: nil,
            sleepDisorder: nil, cognitiveImpairment: nil, physicalPain: nil,
            depressionOrAnxiety: nil, additionalInformation: "",
            measurementType: reminder.measurementType,
            reminderType: reminder.reminderType,
            threshold: reminder.threshold,
            interval: reminder.interval,
            triggerSamples: triggerSamples
        )
        
        if case .success(let newReflection) = result {
            sendEditReflectionRequestToPhone(
                reflectionID: newReflection.id,
                activityID: activity?.id,
                subactivityID: subactivity?.id
            )
        }
    }
    
    @MainActor
    private func createReflectionFromNotification(reminderID: UUID, alertID: UUID) -> Reflection? {
        guard let fetchRemindersUseCase = self.fetchRemindersUseCase,
              let createReflectionUseCase = self.createReflectionUseCase else {
            return nil
        }
        
        guard let allReminders = fetchRemindersUseCase.execute(),
              let reminder = allReminders.first(where: { $0.id == reminderID }) else {
            return nil
        }
        
        let triggerSamples = self.retrieveTriggerData(for: alertID) ?? []

        let result = createReflectionUseCase.execute(
            date: Date(),
            activity: nil, subactivity: nil, mood: nil, didTriggerCrash: false,
            wellBeing: nil, fatigue: nil, shortnessOfBreath: nil,
            sleepDisorder: nil, cognitiveImpairment: nil, physicalPain: nil,
            depressionOrAnxiety: nil, additionalInformation: "",
            measurementType: reminder.measurementType,
            reminderType: reminder.reminderType,
            threshold: reminder.threshold,
            interval: reminder.interval,
            triggerSamples: triggerSamples
        )
        
        if case .success(let reflection) = result {
            return reflection
        }
        return nil
    }
    
    func sendEditReflectionRequestToPhone(reflectionID: UUID, activityID: UUID?, subactivityID: UUID?) {
        guard WCSession.default.isReachable else { return }
        
        var message: [String: Any] = [
            MessageKeys.command: MessageCommand.openReflectionForEditing.rawValue,
            "reflection_id": reflectionID.uuidString
        ]
        
        if let activityID = activityID {
            message["activity_id"] = activityID.uuidString
        }
        if let subactivityID = subactivityID {
            message["subactivity_id"] = subactivityID.uuidString
        }
        
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Error sending edit reflection request: \(error.localizedDescription)")
            
        }
    }
    
    func requestCreateReflectionOnPhone() {
        print("DEBUGY WATCH: SystemDelegate's request method called.")
        
        guard WCSession.default.isReachable else {
                print("DEBUGY WATCH: ERROR - iPhone is not reachable. Message will NOT be sent.")
                return
            }
            
        print("DEBUGY WATCH: iPhone is reachable. Sending message...")
        let message: [String: Any] = [MessageKeys.command: MessageCommand.requestCreateReflection.rawValue]
        
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("DEBUGY WATCH: ERROR - sendMessage failed with error: \(error.localizedDescription)")
        }
    }
    
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error = error {
            print("SystemDelegate: WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("SystemDelegate: WCSession activated with state: \(activationState.rawValue)")
        }
    }
    
    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        if let command = message[MessageKeys.command] as? String,
           let messageCommand = MessageCommand(rawValue: command) {
            
            switch messageCommand {
            case .remindersUpdated:
                Task { @MainActor in
                    Services.shared.monitorService.statusMessage = .syncing
                }
                
            default:
                break
            }
        }
    }
    
    private func sendReflectionRequestToPhone(with data: [(value: Double, date: Date)]) {
        guard WCSession.default.isReachable else {
            print("iPhone is not reachable to create reflection.")
            return
        }
        
        let serializableData = data.map { ["value": $0.value, "timestamp": $0.date.timeIntervalSince1970] }
        
        let message: [String: Any] = [
            MessageKeys.command: MessageCommand.createReflection.rawValue,
            MessageKeys.data: serializableData
        ]
        
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Error sending reflection request to phone: \(error.localizedDescription)")
            
        }
    }
}
