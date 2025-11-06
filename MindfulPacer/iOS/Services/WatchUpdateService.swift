//
//  WatchUpdateService.swift
//  iOS
//
//  Created by Grigor Dochev on 09.08.2025.
//

import Foundation
import WatchConnectivity

// MARK: - Wire keys for mirroring reminders

private enum MirrorWire {
    static let keyType       = "type"
    static let keyMirrorData = "reminder_mirror_v1"

    enum Kind: String {
        case remindersMirror = "reminders_mirror"
    }
}
// MARK: - WatchUpdateServiceProtocol

protocol WatchUpdateServiceProtocol {
    func notifyWatchOfReminderChange()
    func pushMirror()
}

// MARK: - WatchUpdateService

final class WatchUpdateService: WatchUpdateServiceProtocol, @unchecked Sendable {

    static let shared = WatchUpdateService()
    private init() {}

    // MARK: - Legacy ping used by your existing watch code
    func notifyWatchOfReminderChange() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default

        if session.activationState == .activated {
            let message = [MessageKeys.command: MessageCommand.remindersUpdated.rawValue]
            session.sendMessage(message, replyHandler: nil) { error in
                 print("Error sending 'remindersUpdated': \(error.localizedDescription)")
            }
        } else {
             print("WCSession not activated; cannot send remindersUpdated.")
        }
    }

    // MARK: - New: Mirror reminder configs to the watch
    func pushMirror() {
        guard WCSession.isSupported() else { return }

        Task { @MainActor in
            let items = BackgroundRemindersStore.shared.load()

            let enc = JSONEncoder()
            guard let data = try? enc.encode(items) else {
                 print("Mirror encode failed")
                return
            }

            let payload: [String: Any] = [
                MirrorWire.keyType: MirrorWire.Kind.remindersMirror.rawValue,
                MirrorWire.keyMirrorData: data
            ]

            let session = WCSession.default
            if session.activationState == .activated {
                do {
                    try session.updateApplicationContext(payload)
                     print("Pushed reminder mirror via application context (\(items.count) items).")
                } catch {
                    session.transferUserInfo(payload)
                     print("Fell back to transferUserInfo for mirror: \(error.localizedDescription)")
                }
            } else {
                session.transferUserInfo(payload)
                print("Session not activated; queued mirror with transferUserInfo.")
            }
        }
    }
}
