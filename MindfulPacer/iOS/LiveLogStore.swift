//
//  LiveLogStore.swift
//  iOS
//
//  Created by Grigor Dochev on 13.10.2025.
//

import Foundation
import Combine

@MainActor
final class LiveLogsStore: ObservableObject {
    static let shared = LiveLogsStore()
    @Published private(set) var lines: [String] = []

    private let df: DateFormatter = {
        let d = DateFormatter()
        d.dateFormat = "HH:mm:ss.SSS"
        return d
    }()

    func append(_ wire: LogWireEntry) {
        let time = df.string(from: Date(timeIntervalSince1970: wire.t))
        lines.append("[\(time)][\(wire.l)][\(wire.g)] \(wire.m)")
        if lines.count > 10_000 { lines.removeFirst(lines.count - 10_000) }
    }

    func appendBatch(_ wires: [LogWireEntry]) {
        for w in wires { append(w) }
    }

    func clear() { lines.removeAll() }

    func export() throws -> URL {
        let text = lines.joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("MindfulPacer-Live.log")
        try text.data(using: .utf8)?.write(to: url, options: .atomic)
        return url
    }
}
