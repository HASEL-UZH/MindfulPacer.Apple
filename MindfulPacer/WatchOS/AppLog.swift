//
//  AppLog.swift
//  WatchOS
//
//  Created by Grigor Dochev on 12.10.2025.
//

import Foundation
import Combine

enum LogLevel: String, Codable { case debug = "DEBUG", info = "INFO", warn = "WARN", error = "ERROR" }

struct LogEntry: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let tag: String
    let message: String

    var line: String {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss.SSS"
        return "[\(df.string(from: timestamp))][\(level.rawValue)][\(tag)] \(message)"
    }
}

@MainActor
final class AppLog: ObservableObject {
    static let shared = AppLog(maxEntries: 5000)
    @Published private(set) var entries: [LogEntry] = []

    private let maxEntries: Int
    private init(maxEntries: Int) {
        self.maxEntries = maxEntries
        // Touch the pipe so WCSession is activated early for streaming
        _ = LogPipe.shared
    }

    func write(_ level: LogLevel = .debug, tag: String, _ message: @autoclosure () -> String) {
        let entry = LogEntry(timestamp: Date(), level: level, tag: tag, message: message())
        entries.append(entry)
        if entries.count > maxEntries { entries.removeFirst(entries.count - maxEntries) }

        // Keep printing to Xcode/Console
        print(entry.line)

        // Stream to iPhone (match LogPipe enqueue signature)
        LogPipe.shared.enqueue(
            timestamp: entry.timestamp,
            levelRaw: entry.level.rawValue,
            tag: entry.tag,
            message: entry.message
        )
    }

    func clear() { entries.removeAll() }

    func exportToFile() throws -> URL {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let fileName = "MindfulPacer-\(df.string(from: Date())).log"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        let text = entries.map { $0.line }.joined(separator: "\n")
        try text.data(using: .utf8)!.write(to: url, options: .atomic)
        return url
    }
}

// Shorthands (evaluate eagerly, then hop to MainActor)
@inline(__always)
func LOGD(_ tag: String, _ msg: @autoclosure () -> String) {
    let text = msg()
    Task { @MainActor in AppLog.shared.write(.debug, tag: tag, text) }
}
@inline(__always)
func LOGI(_ tag: String, _ msg: @autoclosure () -> String) {
    let text = msg()
    Task { @MainActor in AppLog.shared.write(.info, tag: tag, text) }
}
@inline(__always)
func LOGW(_ tag: String, _ msg: @autoclosure () -> String) {
    let text = msg()
    Task { @MainActor in AppLog.shared.write(.warn, tag: tag, text) }
}
@inline(__always)
func LOGE(_ tag: String, _ msg: @autoclosure () -> String) {
    let text = msg()
    Task { @MainActor in AppLog.shared.write(.error, tag: tag, text) }
}
