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
    // MARK: - Heart Rate
    
    var startHeartRateMonitoringUseCase: Factory<DefaultStartHeartRateMonitoringUseCase> {
        self {
            DefaultStartHeartRateMonitoringUseCase(
                healthKitService: HealthKitService.shared,
                notificationService: NotificationService.shared,
                connectivityService: WatchConnectivityService.shared
            )
        }
    }
}
