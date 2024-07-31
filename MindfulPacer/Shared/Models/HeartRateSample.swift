//
//  HeartRateSample.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 19.07.2024.
//

import Foundation
import SwiftData

public typealias HeartRateSample = SchemaV1.HeartRateSample

extension SchemaV1 {
    @Model
    public final class HeartRateSample {
        public var id: UUID = UUID()
        public var timestamp: Date = Date.now
        public var heartRate: Double = 0.0
        
        init(timestamp: Date, heartRate: Double) {
            self.id = UUID()
            self.timestamp = timestamp
            self.heartRate = heartRate
        }
    }
}
