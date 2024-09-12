//
//  HealthKitError.swift
//  iOS
//
//  Created by Grigor Dochev on 11.09.2024.
//

import Foundation
import HealthKit

// MARK: - HealthKitError

struct HealthKitError: Error, LocalizedError {
    enum ErrorType {
        case permissionDenied
        case permissionNotDetermined
        case healthDataUnavailable
        case heartRateTypeUnavailable
        case stepCountTypeUnavailable
        case failedToFetchSamples
        case failedToFetchStepCount
        case unknownError
    }

    let type: ErrorType
    let underlyingError: Error?

    var errorDescription: String? {
        switch type {
        case .permissionDenied:
            return "HealthKit permission was denied by the user."
        case .permissionNotDetermined:
            return "HealthKit permission has not been determined yet."
        case .healthDataUnavailable:
            return "Health data types are unavailable."
        case .heartRateTypeUnavailable:
            return "Heart rate data is unavailable."
        case .stepCountTypeUnavailable:
            return "Step count data is unavailable."
        case .failedToFetchSamples:
            return "Failed to fetch heart rate samples."
        case .failedToFetchStepCount:
            return "Failed to fetch current step count."
        case .unknownError:
            return "An unknown error occurred."
        }
    }

    var recoverySuggestion: String? {
        switch type {
        case .permissionDenied:
            return "Please enable HealthKit permissions in the app settings."
        case .permissionNotDetermined:
            return "Please allow HealthKit permissions when prompted."
        case .healthDataUnavailable:
            return "Ensure HealthKit is available and configured correctly on this device."
        case .unknownError:
            return "Please try again later."
        default:
            return nil
        }
    }

    var failureReason: String? {
        if let underlyingError = underlyingError {
            return "Underlying error: \(underlyingError.localizedDescription)"
        }
        return nil
    }

    init(type: ErrorType, underlyingError: Error? = nil) {
        self.type = type
        self.underlyingError = underlyingError
    }
}
