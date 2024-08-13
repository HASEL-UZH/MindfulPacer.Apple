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

struct AlertContext {
    
    // MARK: - Article Deck
    
    //    static let unableToGetArticles = AlertItem(
    //        title: Text("Articles Error"),
    //        message: Text("Unable to retrieve articles at this time.\nPlease try again."),
    //        dismissButton: .default(Text("Ok"))
    //    )
}
