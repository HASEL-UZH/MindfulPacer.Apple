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
    func execute(period: Period, endDate: Date) -> [ReflectionBucket]
}

// MARK: - Use Case Implementation

final class DefaultFetchReflectionsInPeriodUseCase: FetchReflectionsInPeriodUseCase {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func execute(period: Period, endDate: Date) -> [ReflectionBucket] {
        do {
            let descriptor = FetchDescriptor<Reflection>(sortBy: [SortDescriptor(\Reflection.date, order: .reverse)])
            let allReflections = try modelContext.fetch(descriptor)
            
            let start = period.startDate(relativeTo: endDate)
            let filteredReflections = allReflections.filter { reflection in
                reflection.date >= start && reflection.date <= endDate
            }
            
            let groupingInterval: TimeInterval
            switch period {
            case .oneHour, .twoHours:
                groupingInterval = 5 * 60
            case .day:
                groupingInterval = 15 * 60
            case .week:
                groupingInterval = 4 * 3600
            }
            
            let sortedReflections = filteredReflections.sorted { $0.date < $1.date }.filter { !$0.isMissedReflection && !$0.isRejected }
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
