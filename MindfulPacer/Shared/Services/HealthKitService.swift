//
//  HealthKitService.swift
//  iOS
//
//  Created by Grigor Dochev on 06.07.2024.
//

import Foundation
import HealthKit

protocol HealthKitServiceProtocol: Sendable {
    var currentHeartRate: Double { get }
    var heartRateData: [(timestamp: Date, heartRate: Double)] { get }
    func startHeartRateMonitoring()
    func stopHeartRateMonitoring()
    func fetchLatestHeartRateSample(completion: @escaping (Double, Date) -> Void)
    func handleHeartRateSample(_ heartRate: Double, at timestamp: Date)
}

final class HealthKitService: NSObject, HealthKitServiceProtocol, @unchecked Sendable {
    static let shared = HealthKitService()
    private var healthStore: HKHealthStore?
    private var workoutSession: HKWorkoutSession?
    private var query: HKObserverQuery?
    
    @Published var currentHeartRate: Double = 0.0
    @Published var heartRateData: [(timestamp: Date, heartRate: Double)] = []
    private var previousTimestamp: Date?
    
    override init() {
        super.init()
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
            let typesToShare: Set = [HKObjectType.workoutType()]
            let typesToRead: Set = [HKObjectType.quantityType(forIdentifier: .heartRate)!]
            
            healthStore?.requestAuthorization(toShare: typesToShare, read: typesToRead, completion: { [weak self] (success, error) in
                if success {
                    self?.enableBackgroundDelivery()
                }
            })
        }
    }
    
    func enableBackgroundDelivery() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        healthStore?.enableBackgroundDelivery(for: heartRateType, frequency: .immediate, withCompletion: { [weak self] (success, error) in
            if success {
                self?.startHeartRateObserverQuery()
            }
        })
    }
    
    func startHeartRateObserverQuery() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] query, completionHandler, error in
            if let error = error {
                print("DEBUG:", error)
                return
            }
            
            self?.fetchLatestHeartRateSample { [weak self] heartRate, timestamp in
                self?.handleHeartRateSample(heartRate, at: timestamp)
                completionHandler()
            }
        }
        
        healthStore?.execute(query!)
    }
    
    func fetchLatestHeartRateSample(completion: @escaping (Double, Date) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { query, results, error in
            guard let results = results, let sample = results.first as? HKQuantitySample else {
                completion(0.0, Date())
                return
            }
            
            let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            let heartRate = sample.quantity.doubleValue(for: heartRateUnit)
            let timestamp = sample.startDate
            completion(heartRate, timestamp)
        }
        
        healthStore?.execute(query)
    }
    
    func handleHeartRateSample(_ heartRate: Double, at timestamp: Date) {
        // Perform UI updates on the main actor
        Task { @MainActor in
            self.updateHeartRateSample(heartRate, at: timestamp)
        }
    }
    
    @MainActor
    private func updateHeartRateSample(_ heartRate: Double, at timestamp: Date) {
        guard previousTimestamp != timestamp else { return }
        
        currentHeartRate = heartRate
        heartRateData.append((timestamp: timestamp, heartRate: heartRate))
        previousTimestamp = timestamp
    }
    
    func startHeartRateMonitoring() {
        // Implementation for starting heart rate monitoring
    }
    
    func stopHeartRateMonitoring() {
        // Implementation for stopping heart rate monitoring
    }
}
