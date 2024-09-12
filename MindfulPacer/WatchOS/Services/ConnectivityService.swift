//
//  ConnectivityService.swift
//  WatchOS
//
//  Created by Grigor Dochev on 06.07.2024.
//

import Foundation
import WatchConnectivity
import WatchKit
import CocoaLumberjackSwift

// MARK: - ConnectivityServiceProtocol

protocol ConnectivityServiceProtocol: Sendable {
    func initializeSession(completion: @escaping (Result<Void, Error>) -> Void)
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
                DDLogError("WCSession activation failed: Session is not activated.")
                completion(.failure(ConnectivityError.sessionActivationFailed(SessionError.notActivated)))
            } else {
                DDLogInfo("WCSession activated successfully.")
                completion(.success(()))
            }
        } else {
            DDLogError("WCSession not supported on this device.")
            completion(.failure(SessionError.notSupported))
        }
    }
}

// MARK: - WCSessionDelegate

extension ConnectivityService {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            DDLogError("WCSession activation failed: \(error.localizedDescription)")
        } else {
            DDLogInfo("WCSession activated with state: \(activationState.rawValue)")
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let command = message[MessageKeys.command] as? String, let messageCommand = MessageCommand(rawValue: command) {
            switch messageCommand {
            case .triggerLocalNotification:
                if let data = message[MessageKeys.data] as? [String: String],
                   let title = data["title"], let body = data["body"] {
                    DDLogInfo("Received message to trigger local notification on watch with title: \(title) and body: \(body)")
                    NotificationService.shared.triggerLocalNotification(title: title, body: body) { result in
                        switch result {
                        case .success:
                            DDLogInfo("Local notification triggered successfully on watch.")
                        case .failure(let error):
                            DDLogError("Failed to trigger local notification on watch: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            DDLogInfo("WCSession is reachable.")
        } else {
            DDLogWarn("WCSession is not reachable.")
        }
    }
}
