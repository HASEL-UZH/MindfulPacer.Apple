//
//  ConnectivityError.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 17.08.2024.
//

import Foundation

enum ConnectivityError: Error {
    case messageSendingFailed(Error)
    case sessionActivationFailed(Error)
    case sessionNotReachable
    case unknown
}
