//
//  SystemDelegate.swift
//  WatchOS
//
//  Created by Grigor Dochev on 10.08.2025.
//

import Foundation
import UserNotifications
import WatchConnectivity

class SystemDelegate: NSObject, @preconcurrency UNUserNotificationCenterDelegate, WCSessionDelegate, @unchecked Sendable {
    
    static let shared = SystemDelegate()
    
    @MainActor
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        guard let idString = userInfo["alert_id"] as? String,
              let alertID = UUID(uuidString: idString) else {
            completionHandler()
            return
        }
        
        switch response.actionIdentifier {
        case "VIEW_DETAILS_ACTION":
            NavigationManager.shared.selectedAlertID = alertID
            
        case "CREATE_REFLECTION_ACTION":
            if let data = HeartRateMonitorService.shared.data(for: alertID) {
                sendReflectionRequestToPhone(with: data)
            }
            
        default:
            break
        }
        
        completionHandler()
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
                print("SystemDelegate: Received 'remindersUpdated' command.")
                Task { @MainActor in
                    HeartRateMonitorService.shared.refreshState()
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
