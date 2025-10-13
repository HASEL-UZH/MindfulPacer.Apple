//
//  LogWire.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 13.10.2025.
//

import Foundation

enum LogWire {
    static let keyType    = "type"
    static let keyPayload = "payload"
    static let keyEntries = "entries"

    enum Kind: String {
        case log       = "log"
        case logBatch  = "log_batch"
        case ping      = "ping"
    }
}

/// Tiny, string-based payload safe across targets
struct LogWireEntry: Codable {
    let t: TimeInterval
    let l: String
    let g: String
    let m: String
}
