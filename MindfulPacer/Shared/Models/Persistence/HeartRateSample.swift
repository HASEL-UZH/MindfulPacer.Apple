//
//  HeartRateSample.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 19.07.2024.
//

import Foundation
import SwiftData

typealias HeartRateSample = SchemaV1.HeartRateSample

extension SchemaV1 {
    @Model
    final class HeartRateSample {
        var id: UUID = UUID()
        var timestamp: Date = Date.now
        var heartRate: Double = 0.0
        
        init(timestamp: Date, heartRate: Double) {
            self.id = UUID()
            self.timestamp = timestamp
            self.heartRate = heartRate
        }
    }
}
