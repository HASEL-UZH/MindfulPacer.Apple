//
//  UseCasesContainer.swift
//  WatchOS
//
//  Created by Grigor Dochev on 05.07.2024.
//

import Factory

final class UseCasesContainer: SharedContainer, @unchecked Sendable {
    static let shared = UseCasesContainer()
    var manager = ContainerManager()
}

extension UseCasesContainer {
    // MARK: - iOS Communication

    @MainActor
    var initializeConnectivityUseCase: Factory<DefaultInitializeConnectivityUseCase> {
        self { DefaultInitializeConnectivityUseCase(connectivityService: ConnectivityService.shared) }
    }

    // MARK: - System

    @MainActor
    var initializeNotificationsUseCase: Factory<DefaultInitializeNotificationsUseCase> {
        self { DefaultInitializeNotificationsUseCase(notificationService: NotificationService.shared) }
    }
}
