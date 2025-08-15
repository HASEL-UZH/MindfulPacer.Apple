//
//  ConnectivityService.swift
//  iOS
//
//  Created by Grigor Dochev on 06.07.2024.
//

import Combine
import Foundation
import WatchConnectivity

@MainActor
class WatchEventCoordinator {
    
    static let shared = WatchEventCoordinator()
    let createReflectionSubject = PassthroughSubject<[(value: Double, date: Date)], Never>()
    let requestCreateReflectionSheetSubject = PassthroughSubject<Void, Never>()
    let openReflectionSubject = PassthroughSubject<(reflectionID: UUID, activityID: UUID?, subactivityID: UUID?), Never>()
    
    private init() {}
}

// MARK: - ConnectivityServiceProtocol

protocol ConnectivityServiceProtocol: Sendable {
    func session(_ session: WCSession, didReceiveMessage message: [String: Any])
}

// MARK: - ConnectivityService

final class ConnectivityService: NSObject, ConnectivityServiceProtocol, WCSessionDelegate, @unchecked Sendable {
    
    static let shared = ConnectivityService()
    
    private override init() {
        super.init()
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("ConnectivityService: WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("ConnectivityService: WCSession activated with state: \(activationState.rawValue)")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("DEBUGY IPHONE: didReceiveMessage called with message: \(message)")
        
        guard let commandString = message[MessageKeys.command] as? String,
              let command = MessageCommand(rawValue: commandString) else {
            return
        }
        
        switch command {
        case .triggerLocalNotification:
            break
        case .remindersUpdated:
            break
        case .createReflection:
            break
        case .requestCreateReflection:
            break
        case .openReflectionForEditing:
            guard let idString = message["reflection_id"] as? String,
                  let reflectionID = UUID(uuidString: idString) else {
                return
            }
            
            let activityID = (message["activity_id"] as? String).flatMap(UUID.init)
            let subactivityID = (message["subactivity_id"] as? String).flatMap(UUID.init)
            
            Task { @MainActor in
                WatchEventCoordinator.shared.openReflectionSubject.send(
                    (reflectionID: reflectionID, activityID: activityID, subactivityID: subactivityID)
                )
            }
        }
    }
}
