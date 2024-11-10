//
//  ListenToModeOfUseChangesUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 10.11.2024.
//

import Combine
import Foundation

protocol ListenToModeOfUseChangesUseCase {
    func execute() -> AnyPublisher<ModeOfUse, Never>
}

// MARK: - Use Case Implementation

class DefaultListenToModeOfUseChangesUseCase: ListenToModeOfUseChangesUseCase {
    private var modeOfUsePublisher: AnyPublisher<ModeOfUse, Never>
    private var cancellables = Set<AnyCancellable>()

    init() {
        modeOfUsePublisher = UserDefaults.standard
            .publisher(for: \.modeOfUse)
            .map { modeOfUseString in
                return ModeOfUse(rawValue: modeOfUseString ?? ModeOfUse.essentials.rawValue) ?? .essentials
            }
            .eraseToAnyPublisher()
    }
    
    func execute() -> AnyPublisher<ModeOfUse, Never> {
        return modeOfUsePublisher
    }
}
