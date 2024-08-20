//
//  ConnectivityService.swift
//  WatchOS
//
//  Created by Grigor Dochev on 06.07.2024.
//

import Foundation
import WatchConnectivity
import WatchKit

// MARK: - ConnectivityServiceProtocol

protocol ConnectivityServiceProtocol: Sendable {
    func initializeSession(completion: @escaping (Result<Void, Error>) -> Void)
    func triggerHapticFeedback(with vibrationStrength: ReviewReminder.VibrationStrength)
}

// MARK: - ConnectivityService

final class ConnectivityService: NSObject, ConnectivityServiceProtocol, WCSessionDelegate, @unchecked Sendable {
    static let shared = ConnectivityService()
    
    private override init() {
        super.init()
    }
    
    func initializeSession(completion: @escaping (Result<Void, Error>) -> Void) {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            
            if session.activationState != .activated {
                completion(.failure(ConnectivityError.sessionActivationFailed(SessionError.notActivated)))
            } else {
                completion(.success(()))
            }
        } else {
            completion(.failure(SessionError.notSupported))
        }
    }
    
    func triggerHapticFeedback(with vibrationStrength: ReviewReminder.VibrationStrength) {
        if let hapticType = vibrationStrength.hapticType() {
            WKInterfaceDevice.current().play(hapticType)
        }
    }
}

// MARK: - WCSessionDelegate

extension ConnectivityService {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let command = message[MessageKeys.command] as? String, let messageCommand = MessageCommand(rawValue: command) {
            switch messageCommand {
            case .hapticFeedback:
                if let data = message[MessageKeys.data] as? [String: Any],
                   let vibrationStrengthString = data["vibrationStrength"] as? String,
                   let vibrationStrength = ReviewReminder.VibrationStrength(rawValue: vibrationStrengthString) {
                    print("DEBUGY: Triggering haptic feedback with strength: \(vibrationStrength)")
                    triggerHapticFeedback(with: vibrationStrength)
                }
            case .triggerLocalNotification:
                if let data = message[MessageKeys.data] as? [String: String],
                   let title = data["title"], let body = data["body"] {
                    print("DEBUGY: Calling triggerLocalNotification")
                    NotificationService.shared.triggerLocalNotification(title: title, body: body) { result in
                        switch result {
                        case .success:
                            print("DEBUGY: Notification triggered successfully on watch.")
                        case .failure(let error):
                            print("DEBUGY: Failed to trigger notification on watch: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            print("DEBUGY: WCSession is reachable.")
        } else {
            print("DEBUGY: WCSession is not reachable.")
        }
    }
}
