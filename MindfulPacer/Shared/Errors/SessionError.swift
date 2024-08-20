//
//  SessionError.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 17.08.2024.
//

import Foundation

enum SessionError: Error {
    case notReachable
    case notSupported
    case notActivated
}
