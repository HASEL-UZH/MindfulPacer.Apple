//
//  WatchConnectivityService.swift
//  WatchOS
//
//  Created by Grigor Dochev on 06.07.2024.
//

import Foundation
import WatchConnectivity

protocol WatchConnectivityServiceProtocol: ConnectivityServiceProtocol {
    func sendHeartRateToPhone(heartRate: Double, timestamp: Date)
}

final class WatchConnectivityService: NSObject, WatchConnectivityServiceProtocol, WCSessionDelegate, @unchecked Sendable {
    static let shared = WatchConnectivityService()

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

    func sendHeartRateToPhone(heartRate: Double, timestamp: Date) {
        if WCSession.default.isReachable {
            let message: [String: Any] = ["heartRate": heartRate, "timestamp": timestamp.timeIntervalSince1970]
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Error sending heart rate data to phone: \(error.localizedDescription)")
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

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let heartRate = message["heartRate"] as? Double, let timestamp = message["timestamp"] as? TimeInterval {
            let date = Date(timeIntervalSince1970: timestamp)
            DispatchQueue.main.async {
                print("DEBUG:", heartRate, date)
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
