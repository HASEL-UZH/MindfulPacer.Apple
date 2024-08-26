//
//  AlertItem.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 13.08.2024.
//

import SwiftUI

struct AlertItem: Identifiable, Equatable {
    static func == (lhs: AlertItem, rhs: AlertItem) -> Bool {
        lhs.message == rhs.message
    }
    
    let id = UUID()
    let title: Text
    let message: Text
    let dismissButton: Alert.Button
    
    var alert: Alert {
        Alert(title: title, message: message, dismissButton: dismissButton)
    }
}

@MainActor
struct AlertContext {
    
    // MARK: - Reviews
    
    static let unableToSaveReview = AlertItem(
        title: Text("Save Error"),
        message: Text("Unable to save your Review.\nPlease try again.\nIf this problem persists, please contact us."),
        dismissButton: .default(Text("Ok"))
    )
    
    static let unableToSaveReviewReminder = AlertItem(
        title: Text("Save Error"),
        message: Text("Unable to save your Review Reminder.\nPlease try again.\nIf this problem persists, please contact us."),
        dismissButton: .default(Text("Ok"))
    )
    
    static let unableToSendTestNotification = AlertItem(
        title: Text("Unable to Send Notification"),
        message: Text("Please make sure that you are wearing your Apple Watch and you have the MindfulPacer Watch app open, then try again."),
        dismissButton: .default(Text("Ok"))
    )
    
    // MARK: - Communication
    
    static let unableToTriggerVibration = AlertItem(
        title: Text("Unable to Trigger Vibration"),
        message: Text("Please make sure that you are wearing your Apple Watch and you have the MindfulPacer Watch app open, then try again."),
        dismissButton: .default(Text("Ok"))
    )
}
