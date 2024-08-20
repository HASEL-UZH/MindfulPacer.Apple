//
//  TriggerHapticFeedbackUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 17.08.2024.
//

import Foundation
import WatchConnectivity

protocol TriggerHapticFeedbackUseCase {
    func execute(vibrationStrength: ReviewReminder.VibrationStrength, completion: @escaping (Result<Void, Error>) -> Void)
}

// MARK: - Use Case Implementation

final class DefaultTriggerHapticFeedbackUseCase: TriggerHapticFeedbackUseCase {
    private let connectivityService: ConnectivityService
    
    init(connectivityService: ConnectivityService) {
        self.connectivityService = connectivityService
    }
    
    func execute(vibrationStrength: ReviewReminder.VibrationStrength, completion: @escaping (Result<Void, Error>) -> Void) {
        let data: [String: Any] = ["vibrationStrength": vibrationStrength.rawValue]
        connectivityService.sendMessage(.hapticFeedback, data: data, completion: completion)
    }
}
