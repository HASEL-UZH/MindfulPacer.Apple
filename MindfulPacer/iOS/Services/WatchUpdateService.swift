//
//  WatchUpdateService.swift
//  iOS
//
//  Created by Grigor Dochev on 09.08.2025.
//

import Foundation
import WatchConnectivity

// MARK: - WatchUpdateServiceProtocol

protocol WatchUpdateServiceProtocol {
    func notifyWatchOfReminderChange()
}

// MARK: - WatchUpdateService

class WatchUpdateService: WatchUpdateServiceProtocol, @unchecked Sendable {
    
    static let shared = WatchUpdateService()
    
    private init() {}
    
    func notifyWatchOfReminderChange() {
        guard WCSession.isSupported() else {
            print("WCSession is not supported on this device.")
            return
        }
        
        let session = WCSession.default
        if session.activationState == .activated {
            let message = [MessageKeys.command: MessageCommand.remindersUpdated.rawValue]
            
            session.sendMessage(message, replyHandler: nil) { error in
                print("Error sending 'remindersUpdated' message to watch: \(error.localizedDescription)")
                
            }
        } else {
            print("Watch session not activated. Cannot send message.")
        }
    }
}
