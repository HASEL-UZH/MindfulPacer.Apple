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
    
    static let shared = SystemDelegate()
    
    private var fetchRemindersUseCase: FetchRemindersUseCase?
    private var createReflectionUseCase: CreateReflectionUseCase?
    
    @MainActor
    func configure() {
        guard self.fetchRemindersUseCase == nil else { return }
        
        print("DEBUGY: Configuring SystemDelegate with use cases.")
        let modelContext = ModelContainer.prod.mainContext
        self.fetchRemindersUseCase = DefaultFetchRemindersUseCase(modelContext: modelContext)
        self.createReflectionUseCase = DefaultCreateReflectionUseCase(modelContext: modelContext)
    }
    
    @MainActor
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        guard let reminderIDString = userInfo["reminder_id"] as? String,
              let reminderID = UUID(uuidString: reminderIDString) else {
            completionHandler()
            return
        }
        
        switch response.actionIdentifier {
        case "ACCEPT_ADD_DETAILS_ACTION":
            print("DEBUGY DELEGATE: 'ACCEPT_ADD_DETAILS_ACTION' received. Setting navigation manager.")
            NavigationManager.shared.reminderIDForActivitySelection = reminderID
            
        case "ACCEPT_LATER_ACTION":
            _ = createReflectionFromNotification(reminderID: reminderID)
        default:
            break
        }
        
        completionHandler()
    }
    
    func createAndSendReflection(reminderID: UUID, activity: Activity?, subactivity: Subactivity?) {
        guard let fetchRemindersUseCase else { return }
        guard let allReminders = fetchRemindersUseCase.execute(),
              let reminder = allReminders.first(where: { $0.id == reminderID }) else {
            print("DEBUGY: Could not find reminder with ID \(reminderID).")
            return
        }
        
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
            interval: reminder.interval
        )
        
        if case .success(let newReflection) = result {
            sendEditReflectionRequestToPhone(
                reflectionID: newReflection.id,
                activityID: activity?.id,
                subactivityID: subactivity?.id
            )
        }
    }
    
    private func createReflectionFromNotification(reminderID: UUID) -> Reflection? {
        guard let fetchRemindersUseCase else { return nil}
        guard let allReminders = fetchRemindersUseCase.execute(),
              let reminder = allReminders.first(where: { $0.id == reminderID }) else {
            print("DEBUGY: Could not find reminder with ID \(reminderID) to create reflection.")
            return nil
        }
        
        guard let createReflectionUseCase else { return nil }
        
        let result = createReflectionUseCase.execute(
            date: Date(),
            activity: nil, subactivity: nil, mood: nil, didTriggerCrash: false,
            wellBeing: nil, fatigue: nil, shortnessOfBreath: nil,
            sleepDisorder: nil, cognitiveImpairment: nil, physicalPain: nil,
            depressionOrAnxiety: nil, additionalInformation: "",
            measurementType: reminder.measurementType,
            reminderType: reminder.reminderType,
            threshold: reminder.threshold,
            interval: reminder.interval
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
                print("SystemDelegate: Received 'remindersUpdated' command (doorbell).")
                Task { @MainActor in
                    print("DEBUGY: Setting status to Syncing.")
                    HealthMonitorService.shared.statusMessage = .syncing
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
