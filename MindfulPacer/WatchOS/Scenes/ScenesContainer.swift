//
//  ScenesContainer.swift
//  WatchOS
//
//  Created by Grigor Dochev on 05.07.2024.
//

import Factory


final class ScenesContainer: SharedContainer, @unchecked Sendable {
    static let shared = ScenesContainer()
    var manager = ContainerManager()
    
    // MARK: - Root
    
    var rootViewModel: Factory<RootViewModel> {
        self {
            RootViewModel()
        }
    }
}
