//
//  StopHeartRateMonitoringUseCase.swift
//  WatchOS
//
//  Created by Grigor Dochev on 06.07.2024.
//

import Foundation

protocol StopHeartRateMonitoringUseCase {
    func execute()
}

class DefaultStopHeartRateMonitoringUseCase: StopHeartRateMonitoringUseCase {
    private let healthKitService: HealthKitServiceProtocol

    init(healthKitService: HealthKitServiceProtocol) {
        self.healthKitService = healthKitService
    }

    func execute() {
        healthKitService.stopHeartRateMonitoring()
    }
}
