//
//  RootViewModel.swift
//  WatchOS
//
//  Created by Grigor Dochev on 16.07.2024.
//

import Foundation
import Combine
import SwiftData

@Observable class RootViewModel {
    private let startHeartRateMonitoringUseCase: StartHeartRateMonitoringUseCase
    private let healthKitService: HealthKitServiceProtocol
    private let dataProviderService: DataProviderService
    
    private var cancellables: Set<AnyCancellable> = []
    
    private(set) var state: RootViewState = .initial
    var currentHeartRateSample: HeartRateSample?
    
    init(
        startHeartRateMonitoringUseCase: StartHeartRateMonitoringUseCase,
        healthKitService: HealthKitServiceProtocol,
        dataProviderService: DataProviderService
    ) {
        self.startHeartRateMonitoringUseCase = startHeartRateMonitoringUseCase
        self.healthKitService = healthKitService
        self.dataProviderService = dataProviderService
        
        healthKitService.heartRatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] heartRateSample in
                self?.currentHeartRateSample = heartRateSample
                self?.state.currentHeartRate = heartRateSample.heartRate
                self?.saveHeartRateSample(heartRateSample)
            }
            .store(in: &cancellables)
    }
    
    // MARK: View Events
    
    func onViewFirstAppear() {
        startHeartRateMonitoringUseCase.execute()
    }
    
    // MARK: Observing and Updating State
    
    func saveHeartRateSample(_ heartRateSample: HeartRateSample) {
        let timestamp = heartRateSample.timestamp
        let heartRate = heartRateSample.heartRate
        let dataHandlerCreator = dataProviderService.dataHandlerCreator()
        
        Task { @MainActor in
            let dataHandler = await dataHandlerCreator()
            do {
                try await dataHandler.newItem(timestamp: timestamp, heartRate: heartRate)
            } catch {
                print("Error saving heart rate sample: \(error)")
            }
        }
    }
}
