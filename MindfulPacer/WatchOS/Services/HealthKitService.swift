//
//  HealthKitService.swift
//  WatchOS
//
//  Created by Grigor Dochev on 22.07.2024.
//

import Foundation
import HealthKit
import Combine
import SwiftData
import WatchKit
import UserNotifications

protocol HealthKitServiceProtocol: Sendable {
    var currentHeartRate: Double { get }
    var heartRateData: [HeartRateSample] { get }
    func startHeartRateMonitoring()
    func stopHeartRateMonitoring()
    func fetchLatestHeartRateSample(completion: @escaping (Double, Date) -> Void)
    func handleHeartRateSample(_ heartRate: Double, at timestamp: Date)
    var heartRatePublisher: AnyPublisher<HeartRateSample, Never> { get }
}

final class HealthKitService: NSObject, HealthKitServiceProtocol, @unchecked Sendable {
    static let shared = HealthKitService()
    private var healthStore: HKHealthStore?
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var query: HKObserverQuery?
    
    @Published var currentHeartRate: Double = 0.0
    @Published var heartRateData: [HeartRateSample] = []
    private var previousTimestamp: Date?
    
    private let heartRateSubject = PassthroughSubject<HeartRateSample, Never>()
    var heartRatePublisher: AnyPublisher<HeartRateSample, Never> {
        heartRateSubject.eraseToAnyPublisher()
    }
    
    override init() {
        super.init()
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
            let typesToShare: Set = [HKObjectType.workoutType()]
            let typesToRead: Set = [HKObjectType.quantityType(forIdentifier: .heartRate)!]
            
            healthStore?.requestAuthorization(toShare: typesToShare, read: typesToRead, completion: { [weak self] (success, error) in
                if success {
                    self?.startHeartRateMonitoring()
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
        let heartRateSample = HeartRateSample(timestamp: timestamp, heartRate: heartRate)
        heartRateData.append(heartRateSample)
        previousTimestamp = timestamp
        heartRateSubject.send(heartRateSample) // Publish the new heart rate
        
        // Check if heart rate exceeds 80 BPM and send notification
        if heartRate > 80 {
            sendNotification(for: heartRateSample)
        }
    }
    
    func startHeartRateMonitoring() {
        startWorkoutSession()
        enableBackgroundDelivery()
    }
    
    func stopHeartRateMonitoring() {
        if let workoutSession = workoutSession {
            healthStore?.end(workoutSession)
            self.workoutSession = nil
        }
        if let query = query {
            healthStore?.stop(query)
            self.query = nil
        }
    }
    
    private func startWorkoutSession() {
        guard let healthStore = healthStore else { return }
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .unknown
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            
            workoutSession?.delegate = self
            workoutBuilder?.delegate = self
            
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            
            let startDate = Date()
            workoutSession?.startActivity(with: startDate)
            workoutBuilder?.beginCollection(withStart: startDate) { success, error in
                if let error = error {
                    print("Error starting workout session: \(error)")
                }
            }
        } catch {
            print("Failed to start workout session: \(error)")
        }
    }
    
    private func sendNotification(for heartRateSample: HeartRateSample) {
        let content = UNMutableNotificationContent()
        content.title = "High Heart Rate Detected"
        content.body = "Your heart rate exceeded 80 BPM at \(heartRateSample.timestamp.formatted(.dateTime.hour().minute().second()))."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error adding notification: \(error)")
            }
        }
    }
}

extension HealthKitService: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        if toState == .ended {
            print("Workout session ended, restarting...")
            startWorkoutSession()
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed with error: \(error), restarting...")
        startWorkoutSession()
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle events if needed
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        if collectedTypes.contains(heartRateType) {
            let statistics = workoutBuilder.statistics(for: heartRateType)
            let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            if let heartRate = statistics?.mostRecentQuantity()?.doubleValue(for: heartRateUnit),
               let timestamp = statistics?.mostRecentQuantityDateInterval()?.start {
                handleHeartRateSample(heartRate, at: timestamp)
            }
        }
    }
}
