//
//  ListenToThemeChangesUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 17.10.2024.
//

import Foundation
import Combine

protocol ListenToThemeChangesUseCase {
    func execute() -> AnyPublisher<Theme, Never>
}

// MARK: - Use Case Implementation

class DefaultListenToThemeChangesUseCase: ListenToThemeChangesUseCase {
    private var themePublisher: AnyPublisher<Theme, Never>
    private var cancellables = Set<AnyCancellable>()

    init() {
        themePublisher = UserDefaults.standard
            .publisher(for: \.selectedTheme)
            .map { themeString in
                return Theme(rawValue: themeString ?? Theme.system.rawValue) ?? .system
            }
            .eraseToAnyPublisher()
    }
    
    func execute() -> AnyPublisher<Theme, Never> {
        return themePublisher
    }
}

// MARK: - Extension for UserDefaults Publisher

extension UserDefaults {
    @objc dynamic var selectedTheme: String? {
        return string(forKey: "selectedTheme")
    }
}
