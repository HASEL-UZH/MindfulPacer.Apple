//
//  OnboardingGate.swift
//  WatchOS
//
//  Created by Grigor Dochev on 29.10.2025.
//

import Foundation
import Combine
import WatchConnectivity

@MainActor
final class OnboardingGate: NSObject, ObservableObject {
    static let shared = OnboardingGate()

    @Published private(set) var isOnboardingCompleted: Bool = false

    private let defaultsKey = "com.mindfulpacer.onboardingCompleted.mirror"
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        // Load last-known value
        if let stored = UserDefaults.standard.object(forKey: defaultsKey) as? Bool {
            self.isOnboardingCompleted = stored
        }
        // Ask iPhone for fresh status at startup
        requestStatusFromPhone()
    }

    func setCompleted(_ completed: Bool) {
        guard completed != isOnboardingCompleted else { return }
        isOnboardingCompleted = completed
        UserDefaults.standard.set(completed, forKey: defaultsKey)
    }

    func requestStatusFromPhone() {
        guard WCSession.isSupported(), WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(
            [MessageKeys.command: MessageCommand.requestOnboardingStatus.rawValue],
            replyHandler: { reply in
                if let ok = reply[OnboardingWire.keyOnboardingCompleted] as? Bool {
                    Task { @MainActor in self.setCompleted(ok) }
                }
            },
            errorHandler: { _ in }
        )
    }
}
