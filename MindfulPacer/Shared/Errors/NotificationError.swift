//
//  NotificationError.swift
//  iOS
//
//  Created by Grigor Dochev on 11.09.2024.
//

import Foundation

// MARK: - NotificationError

struct NotificationError: Error, LocalizedError {
    // Define error types specific to notification-related operations
    enum ErrorType {
        case permissionDenied
        case permissionNotDetermined
        case failedToSendNotification
        case unknownError
    }
    
    let type: ErrorType
    let underlyingError: Error?

    // Provide a human-readable description for each error case
    var errorDescription: String? {
        switch type {
        case .permissionDenied:
            return "Notification permission was denied by the user."
        case .permissionNotDetermined:
            return "Notification permission has not been determined yet."
        case .failedToSendNotification:
            return "Failed to send the notification."
        case .unknownError:
            return "An unknown error occurred."
        }
    }

    // Optionally, provide a recovery suggestion for each error case
    var recoverySuggestion: String? {
        switch type {
        case .permissionDenied:
            return "Please enable notifications in the app settings."
        case .permissionNotDetermined:
            return "Please allow notification permissions when prompted."
        case .failedToSendNotification:
            return "Try again later."
        case .unknownError:
            return "Please contact support."
        }
    }

    // Optionally, provide a more detailed failure reason if needed
    var failureReason: String? {
        if let underlyingError = underlyingError {
            return "Underlying error: \(underlyingError.localizedDescription)"
        }
        return nil
    }
    
    // Optionally, provide custom initializers
    init(type: ErrorType, underlyingError: Error? = nil) {
        self.type = type
        self.underlyingError = underlyingError
    }
}
