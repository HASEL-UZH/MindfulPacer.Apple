//
//  LogPipe.swift
//  MindfulPacer (watchOS)
//

import Foundation
import WatchConnectivity

@MainActor
final class LogPipe: NSObject, WCSessionDelegate {
    static let shared = LogPipe()

    // Local batch; we flush by dropping one transferUserInfo per enqueue
    // (you can bump batchSize if you want fewer transfers)
    private let batchSize = 10
    private var buffer: [LogWireEntry] = []
    private var isWCReady = false

    override init() {
        super.init()
        activateWC()
    }

    private func activateWC() {
        guard WCSession.isSupported() else { return }
        let s = WCSession.default
        s.delegate = self
        s.activate()
    }

    // MARK: Public API from AppLog
    func enqueue(timestamp: Date, levelRaw: String, tag: String, message: String) {
        buffer.append(LogWireEntry(
            t: timestamp.timeIntervalSince1970,
            l: levelRaw,
            g: tag,
            m: message
        ))
        flushOneBatchIfPossible()
    }

    // MARK: Flushing

    /// We avoid timers/closures. Just flush as we go, one userInfo batch at a time.
    private func flushOneBatchIfPossible() {
        guard !buffer.isEmpty else { return }
        // Even if the iPhone is not reachable, transferUserInfo is safe and queued.
        let n = min(batchSize, buffer.count)
        let slice = Array(buffer.prefix(n))
        transferUserInfoBatch(slice)
        buffer.removeFirst(n)
    }

    private func transferUserInfoBatch(_ entries: [LogWireEntry]) {
        let enc = JSONEncoder()
        let dataArr = entries.compactMap { try? enc.encode($0) } // [Data]
        let payload: [String: Any] = [
            LogWire.keyType: LogWire.Kind.logBatch.rawValue,
            LogWire.keyEntries: dataArr
        ]
        WCSession.default.transferUserInfo(payload)
    }

    // MARK: WCSessionDelegate (nonisolated; do nothing special)
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {}

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {}

    nonisolated func session(_ session: WCSession,
                             didFinish userInfoTransfer: WCSessionUserInfoTransfer,
                             error: Error?) {
        // no-op; the system handles retries; we’re only using transferUserInfo
    }
}
