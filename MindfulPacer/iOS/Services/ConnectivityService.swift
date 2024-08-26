//
//  ConnectivityService.swift
//  iOS
//
//  Created by Grigor Dochev on 06.07.2024.
//

import Foundation
import WatchConnectivity

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
    
    func sendMessage(_ command: MessageCommand, data: [String: Any]? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        guard WCSession.default.isReachable else {
            print("DEBUGY: WCSession is not reachable")
            completion(.failure(SessionError.notReachable))
            return
        }
        
        var message: [String: Any] = [MessageKeys.command: command.rawValue]
        if let data = data {
            message[MessageKeys.data] = data
        }
        
        print("DEBUGY: Sending message \(message)")
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("DEBUGY: Failed to send message: \(error.localizedDescription)")
            completion(.failure(ConnectivityError.messageSendingFailed(error)))
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
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            print("WCSession is reachable.")
        } else {
            print("WCSession is not reachable.")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) { }
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
