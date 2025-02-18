//
//  FetchReflectionsInPeriodUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 24.09.2024.
//

import Foundation
import SwiftData

// MARK: - ReflectionBucket

struct ReflectionBucket: Identifiable {
    let id: UUID = UUID()
    let startDate: Date
    let endDate: Date
    let reflections: [Reflection]
}

// MARK: - FetchReflectionsInPeriodUseCase

protocol FetchReflectionsInPeriodUseCase {
    func execute(period: Period) -> [ReflectionBucket]
}

// MARK: - Use Case Implementation

final class DefaultFetchReflectionsInPeriodUseCase: FetchReflectionsInPeriodUseCase {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func execute(period: Period) -> [ReflectionBucket] {
        do {
            let descriptor = FetchDescriptor<Reflection>(sortBy: [SortDescriptor(\Reflection.date, order: .reverse)])
            let allReflections = try modelContext.fetch(descriptor)
            
            let filteredReflections = allReflections.filter { reflection in
                reflection.date >= period.startDate && reflection.date <= Date()
            }
            
            let groupingInterval: TimeInterval
            switch period {
            case .oneHour, .twoHours:
                groupingInterval = 5 * 60    // 5 minutes
            case .day:
                groupingInterval = 15 * 60   // 15 minutes
            case .week:
                groupingInterval = 4 * 3600  // 4 hours
            }
            
            let sortedReflections = filteredReflections.sorted { $0.date < $1.date }
            var buckets: [ReflectionBucket] = []
            
            if let firstReflection = sortedReflections.first {
                var currentBucket: [Reflection] = [firstReflection]
                var bucketStartDate = firstReflection.date
                
                for reflection in sortedReflections.dropFirst() {
                    if reflection.date.timeIntervalSince(bucketStartDate) <= groupingInterval {
                        currentBucket.append(reflection)
                    } else {
                        let bucketEndDate = currentBucket.last!.date
                        buckets.append(ReflectionBucket(startDate: bucketStartDate, endDate: bucketEndDate, reflections: currentBucket))
                        
                        bucketStartDate = reflection.date
                        currentBucket = [reflection]
                    }
                }
                
                if !currentBucket.isEmpty {
                    let bucketEndDate = currentBucket.last!.date
                    buckets.append(ReflectionBucket(startDate: bucketStartDate, endDate: bucketEndDate, reflections: currentBucket))
                }
            }
            
            return buckets
        } catch {
            print("DEBUG: Could not fetch reflections: \(error)")
            return []
        }
    }
}
