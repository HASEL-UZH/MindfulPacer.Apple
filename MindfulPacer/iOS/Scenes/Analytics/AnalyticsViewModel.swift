//
//  AnalyticsViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 12.09.2024.
//

import Foundation
import SwiftData

@Observable
@MainActor
class AnalyticsViewModel {
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let fetchHeartRateUseCase: FetchHeartRateUseCase
    private let fetchStepsUseCase: FetchStepsUseCase
    
    // MARK: - Published Properties
    
    var selectedPeriod: Period = .day {
        didSet {
            switch selectedMeasurementType {
            case .heartRate:
                fetchHeartRateChartData()
            case .steps:
                fetchStepsChartData()
            }
        }
    }
    var selectedMeasurementType: MeasurementType = .heartRate
    
    var heartRateChartData: [DateValueChartData] = []
    var stepsChartData: [DateValueChartData] = []

    // MARK: - Initialization
    
    init(
        modelContext: ModelContext,
        fetchHeartRateUseCase: FetchHeartRateUseCase,
        fetchStepsUseCase: FetchStepsUseCase
    ) {
        self.modelContext = modelContext
        self.fetchHeartRateUseCase = fetchHeartRateUseCase
        self.fetchStepsUseCase = fetchStepsUseCase
    }
    
    // MARK: - View Lifecycle
    
    func onViewFirstAppear() {
        fetchHeartRateChartData()
        fetchStepsChartData()
    }
    
    // MARK: - User Actions
    
    // MARK: - Private Methods
    
    private func fetchHeartRateChartData() {
        fetchHeartRateUseCase.execute(for: selectedPeriod) { result in
            switch result {
            case .success(let success):
                Task { @MainActor in
                    self.heartRateChartData = success
                    print("DEBUGY: data", self.heartRateChartData.count)
                }
            case .failure:
                print("Could not fetch heart data")
            }
        }
    }
    
    private func fetchStepsChartData() {
        fetchStepsUseCase.execute(for: selectedPeriod) { result in
            switch result {
            case .success(let success):
                Task { @MainActor in
                    self.stepsChartData = success
                    print("DEBUGY: data", self.stepsChartData.count)
                }
            case .failure:
                print("Could not fetch heart data")
            }
        }
    }
    
    // MARK: - Error Handling
}
