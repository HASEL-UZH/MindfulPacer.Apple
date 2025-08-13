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
        
        if command == .createReflection {
            if let dataArray = message[MessageKeys.data] as? [[String: Any]] {
                let heartRateData = dataArray.compactMap { dict -> (value: Double, date: Date)? in
                    guard let value = dict["value"] as? Double,
                          let timestamp = dict["timestamp"] as? TimeInterval else {
                        return nil
                    }
                    return (value: value, date: Date(timeIntervalSince1970: timestamp))
                }
                
                Task { @MainActor in
                    WatchEventCoordinator.shared.createReflectionSubject.send(heartRateData)
                }
            }
        } else if command == .requestCreateReflection {
            print("DEBUGY IPHONE: Correct 'requestCreateReflection' command received. Sending to coordinator.")
            Task { @MainActor in
                WatchEventCoordinator.shared.requestCreateReflectionSheetSubject.send()
            }
        }
    }
}
