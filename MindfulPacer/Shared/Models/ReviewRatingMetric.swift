//
//  ReviewRatingMetric.swift
//  iOS
//
//  Created by Grigor Dochev on 14.08.2024.
//

import SwiftUI

// MARK: - ReviewMetricRatingType

enum ReviewMetricRatingType: CaseIterable {
    case headaches
    case energyLevel
    case shortnessOfBreath
    case fever
    case painsAndNeedles
    case muscleAches
    
    var name: String {
        switch self {
        case .headaches: "Headaches"
        case .energyLevel: "Energy Level"
        case .shortnessOfBreath: "Shortness of Breathe"
        case .fever: "Fever"
        case .painsAndNeedles: "Pains and Needles"
        case .muscleAches: "Muscle Aches"
        }
    }
    
    var icon: String {
        switch self {
        case .headaches: "brain.head.profile.fill"
        case .energyLevel: "bolt.fill"
        case .shortnessOfBreath: "wind"
        case .fever: "thermometer.high"
        case .painsAndNeedles: "flame.fill"
        case .muscleAches: "figure.rolling"
        }
    }
}

// MARK: - ReviewMetricRating

struct ReviewMetricRating {
    let type: ReviewMetricRatingType
    var value: Int?
    
    var color: Color {
        switch value {
        case 0: .green
        case 1: .yellow
        case 2: .orange
        case 3: .red
        default: .gray
        }
    }
    
    var description: String {
        switch value {
        case 0: "None"
        case 1: "Mild"
        case 2: "Moderate"
        case 3: "Severe"
        default: ""
        }
    }
}

extension Array where Element == ReviewMetricRating {
    subscript(type: ReviewMetricRatingType) -> ReviewMetricRating? {
        return first { $0.type == type }
    }
}
