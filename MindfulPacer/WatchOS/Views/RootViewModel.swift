//
//  RootViewModel.swift
//  WatchOS
//
//  Created by Grigor Dochev on 09.08.2025.
//

import Foundation
import Combine

@Observable
class RootViewModel {
    var statusMessage: String = "Initializing..."
    var heartRate: Double = 0
    var isMonitoring: Bool = false
    var activeRules: [HeartRateAlertRule] = []
    var isShowingActiveRules = false
    
    private let monitorService = HeartRateMonitorService.shared
    private var cancellables = Set<AnyCancellable>()
    private let fetchRemindersUseCase: FetchRemindersUseCase
    
    init(fetchRemindersUseCase: FetchRemindersUseCase) {
        self.fetchRemindersUseCase = fetchRemindersUseCase
        monitorService.configure(fetchRemindersUseCase: fetchRemindersUseCase)
                
        monitorService.$statusMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newStatus in
                self?.statusMessage = newStatus
            }
            .store(in: &cancellables)
        
        monitorService.$heartRate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newHeartRate in
                self?.heartRate = newHeartRate
            }
            .store(in: &cancellables)
        
        monitorService.$isSessionActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newIsMonitoring in
                self?.isMonitoring = newIsMonitoring
            }
            .store(in: &cancellables)
        
        monitorService.$activeRules
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newRules in
                self?.activeRules = newRules
            }
            .store(in: &cancellables)
    }
    
    func onAppear() {
        monitorService.requestAuthorization { [weak self] isAuthorized in
            guard isAuthorized else {
                self?.statusMessage = "Auth Denied"
                return
            }
            self?.monitorService.refreshState()
        }
    }
}
