//
//  RootViewModel.swift
//  WatchOS
//
//  Created by Grigor Dochev on 09.08.2025.
//

import Foundation
import Combine
import WatchKit
import SwiftUI

struct StorageKeys {
    static let strongAlertCount = "strongAlertCount"
    static let mediumAlertCount = "mediumAlertCount"
    static let lightAlertCount = "lightAlertCount"
    static let lastAlertDate = "lastAlertDate"
}

@MainActor
@Observable
class RootViewModel {
    var statusMessage: StatusMessage = .initializing
    var heartRate: Double = 0
    var isMonitoring: Bool = false
    var activeRules: [HeartRateAlertRule] = []
    var isShowingActiveRules = false
    var isAlerting: Bool = false
    var alertColor: Color = .clear

    var strongAlertCount: Int = 0
    var mediumAlertCount: Int = 0
    var lightAlertCount: Int = 0
    
    private let monitorService = HeartRateMonitorService.shared
    private var cancellables = Set<AnyCancellable>()
    private let fetchRemindersUseCase: FetchRemindersUseCase
    
    init(fetchRemindersUseCase: FetchRemindersUseCase) {
        self.fetchRemindersUseCase = fetchRemindersUseCase
        monitorService.configure(fetchRemindersUseCase: fetchRemindersUseCase)
        
        loadPersistentCounts()
        checkForDailyReset()
        
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
        
        monitorService.alertTriggeredSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rule in
                self?.triggerInAppAlert(for: rule)
            }
            .store(in: &cancellables)
    }
    
    func onAppear() {
        monitorService.requestAuthorization { [weak self] isAuthorized in
            guard isAuthorized else {
                self?.statusMessage = .authDenied
                return
            }
            self?.monitorService.refreshState()
        }
    }
    
    func requestCreateReflectionOnPhone() {
        print("DEBUGY WATCH: Button tapped. Calling SystemDelegate...")
        SystemDelegate.shared.requestCreateReflectionOnPhone()
    }
    
    private func triggerInAppAlert(for rule: HeartRateAlertRule) {
        guard !isAlerting else { return }
        self.isAlerting = true
        self.alertColor = rule.type.color
        
        switch rule.type {
        case .light:
            lightAlertCount += 1
            WKInterfaceDevice.current().play(.success)
        case .medium:
            mediumAlertCount += 1
            WKInterfaceDevice.current().play(.stop)
        case .strong:
            strongAlertCount += 1
            WKInterfaceDevice.current().play(.failure)
        }
        
        savePersistentCounts()
        UserDefaults.standard.set(Date(), forKey: StorageKeys.lastAlertDate)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.isAlerting = false
        }
    }
    
    private func checkForDailyReset() {
        let userDefaults = UserDefaults.standard
        guard let lastDate = userDefaults.object(forKey: StorageKeys.lastAlertDate) as? Date else { return }
        
        if !Calendar.current.isDateInToday(lastDate) {
            print("DEBUGY: New day detected. Resetting alert counters.")
            strongAlertCount = 0
            mediumAlertCount = 0
            lightAlertCount = 0
            savePersistentCounts()
        }
    }
    
    private func loadPersistentCounts() {
        let userDefaults = UserDefaults.standard
        strongAlertCount = userDefaults.integer(forKey: StorageKeys.strongAlertCount)
        mediumAlertCount = userDefaults.integer(forKey: StorageKeys.mediumAlertCount)
        lightAlertCount = userDefaults.integer(forKey: StorageKeys.lightAlertCount)
    }
    
    private func savePersistentCounts() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(strongAlertCount, forKey: StorageKeys.strongAlertCount)
        userDefaults.set(mediumAlertCount, forKey: StorageKeys.mediumAlertCount)
        userDefaults.set(lightAlertCount, forKey: StorageKeys.lightAlertCount)
    }
}
