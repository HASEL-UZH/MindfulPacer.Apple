//
//  NotificationDelegate.swift
//  WatchOS
//
//  Created by Grigor Dochev on 09.08.2025.
//

import Foundation
import UserNotifications

class NotificationDelegate: NSObject, @preconcurrency UNUserNotificationCenterDelegate {
    
    @MainActor
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == "VIEW_DETAILS_ACTION" {
            let userInfo = response.notification.request.content.userInfo
            
            if let idString = userInfo["alert_id"] as? String,
               let alertID = UUID(uuidString: idString) {
                
                NavigationManager.shared.selectedAlertID = alertID
            }
        }
        
        completionHandler()
    }
}
