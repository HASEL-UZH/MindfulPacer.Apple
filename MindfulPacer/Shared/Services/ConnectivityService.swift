//
//  ConnectivityService.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 06.07.2024.
//

import Foundation
import WatchConnectivity

protocol ConnectivityServiceProtocol: Sendable {
    func setupConnectivity()
}
