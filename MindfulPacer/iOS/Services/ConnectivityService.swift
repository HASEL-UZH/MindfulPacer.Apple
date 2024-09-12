//
//  ConnectivityService.swift
//  iOS
//
//  Created by Grigor Dochev on 06.07.2024.
//

import Foundation
import WatchConnectivity
import CocoaLumberjackSwift

// MARK: - ConnectivityServiceProtocol

protocol ConnectivityServiceProtocol: Sendable {
    func initializeSession(completion: @escaping (Result<Void, Error>) -> Void)
    func sendMessage(_ command: MessageCommand, data: [String: Any]?, completion: @escaping (Result<Void, Error>) -> Void)
}

// MARK: - ConnectivityService

final class ConnectivityService: NSObject, ConnectivityServiceProtocol, WCSessionDelegate, @unchecked Sendable {
    static let shared = ConnectivityService()

    private override init() {
        super.init()
        DDLogInfo("ConnectivityService initialized")
    }

    func initializeSession(completion: @escaping (Result<Void, Error>) -> Void) {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()

            if session.activationState != .activated {
                DDLogError("WCSession activation failed - not activated")
                completion(.failure(ConnectivityError.sessionActivationFailed(SessionError.notActivated)))
            } else {
                DDLogInfo("WCSession successfully activated")
                completion(.success(()))
            }
        } else {
            DDLogError("WCSession is not supported on this device")
            completion(.failure(SessionError.notSupported))
        }
    }

    func sendMessage(_ command: MessageCommand, data: [String: Any]? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        guard WCSession.default.isReachable else {
            DDLogWarn("WCSession is not reachable")
            completion(.failure(SessionError.notReachable))
            return
        }

        var message: [String: Any] = [MessageKeys.command: command.rawValue]
        if let data = data {
            message[MessageKeys.data] = data
        }

        DDLogInfo("Sending message: \(message)")
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            DDLogError("Failed to send message: \(error.localizedDescription)")
            completion(.failure(ConnectivityError.messageSendingFailed(error)))
        }
    }
}

// MARK: - WCSessionDelegate

extension ConnectivityService {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            DDLogError("WCSession activation failed with error: \(error.localizedDescription)")
        } else {
            DDLogInfo("WCSession activated with state: \(activationState.rawValue)")
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            DDLogInfo("WCSession is reachable")
        } else {
            DDLogWarn("WCSession is not reachable")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        DDLogInfo("WCSession did become inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        DDLogInfo("WCSession did deactivate, activating again")
        session.activate()
    }
}
