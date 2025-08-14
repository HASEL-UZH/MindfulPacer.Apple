//
//  ActiveRemindersViewModel.swift
//  WatchOS
//
//  Created by Grigor Dochev on 10.08.2025.
//

import Foundation
import Combine

@MainActor
@Observable
class ActiveRemindersViewModel {
    
    var activeRules: [HeartRateAlertRule] = []
    
    private let monitorService = HeartRateMonitorService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        monitorService.$activeRules
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newRules in
                self?.activeRules = newRules
            }
            .store(in: &cancellables)
    }
}
