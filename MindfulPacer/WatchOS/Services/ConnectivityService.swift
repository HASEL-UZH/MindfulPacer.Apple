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
}

// MARK: - WCSessionDelegate

extension ConnectivityService {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let command = message[MessageKeys.command] as? String, let messageCommand = MessageCommand(rawValue: command) {
            switch messageCommand {
            case .triggerLocalNotification:
                if let data = message[MessageKeys.data] as? [String: String],
                   let title = data["title"], let body = data["body"] {
                    NotificationService.shared.triggerLocalNotification(title: title, body: body) { result in
                        switch result {
                        case .success:
                            print("Local notification triggered successfully on watch.")
                        case .failure(let error):
                            print("Failed to trigger local notification on watch: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            print("WCSession is reachable.")
        } else {
            print("WCSession is not reachable.")
        }
    }
}
