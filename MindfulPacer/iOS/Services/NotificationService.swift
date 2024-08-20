//
//  iOSNotificationService.swift
//  iOS
//
//  Created by Grigor Dochev on 19.08.2024.
//

import Foundation
import WatchConnectivity

// MARK: - NotificationServiceProtocol

protocol NotificationServiceProtocol: Sendable {
    func triggerLocalNotification(title: String, body: String, completion: @escaping (Result<Void, Error>) -> Void)
}

// MARK:  - NotificationService

final class NotificationService: NSObject, NotificationServiceProtocol {
    static let shared = NotificationService()
    
    private let connectivityService: ConnectivityService

    private override init() {
        self.connectivityService = ConnectivityService.shared
        super.init()
    }

    func triggerLocalNotification(title: String, body: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let data: [String: Any] = ["title": title, "body": body]
        connectivityService.sendMessage(.triggerLocalNotification, data: data, completion: completion)
    }
}
