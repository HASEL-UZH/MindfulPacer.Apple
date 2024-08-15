//
//  iOSConnectivityService.swift
//  iOS
//
//  Created by Grigor Dochev on 06.07.2024.
//

import Foundation
import WatchConnectivity

protocol iOSConnectivityServiceProtocol: ConnectivityServiceProtocol {
    func sendHeartRateToWatch(heartRate: Double, timestamp: Date)
}

final class iOSConnectivityService: NSObject, iOSConnectivityServiceProtocol, WCSessionDelegate, @unchecked Sendable {
    static let shared = iOSConnectivityService()
    
    private override init() {
        super.init()
        setupConnectivity()
    }
    
    func setupConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func sendHeartRateToWatch(heartRate: Double, timestamp: Date) {
        if WCSession.default.isReachable {
            let message: [String: Any] = ["heartRate": heartRate, "timestamp": timestamp.timeIntervalSince1970]
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Error sending heart rate data to watch: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - WCSessionDelegate
    
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
