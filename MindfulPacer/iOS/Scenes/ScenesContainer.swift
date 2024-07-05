//
//  ScenesContainer.swift
//  iOS
//
//  Created by Grigor Dochev on 01.07.2024.
//

import Factory
import SwiftUI


final class ScenesContainer: SharedContainer, @unchecked Sendable {
    static let shared = ScenesContainer()
    var manager = ContainerManager()

    // MARK: - Root

    var rootViewModel: Factory<RootViewModel> {
        self { RootViewModel() }
    }
}
