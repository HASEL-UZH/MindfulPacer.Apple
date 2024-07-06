//
//  StartHeartRateMonitoringUseCase.swift
//  WatchOS
//
//  Created by Grigor Dochev on 06.07.2024.
//

import Foundation

protocol StartHeartRateMonitoringUseCase {
    func execute()
}

class DefaultStartHeartRateMonitoringUseCase: StartHeartRateMonitoringUseCase {
    private let healthKitService: HealthKitServiceProtocol
    private let notificationService: NotificationServiceProtocol
    private let connectivityService: WatchConnectivityServiceProtocol

    init(healthKitService: HealthKitServiceProtocol, notificationService: NotificationServiceProtocol, connectivityService: WatchConnectivityServiceProtocol) {
        self.healthKitService = healthKitService
        self.notificationService = notificationService
        self.connectivityService = connectivityService
    }

    func execute() {
        healthKitService.startHeartRateMonitoring()
        notificationService.requestNotificationAuthorization()
        connectivityService.setupConnectivity()
    }
}
