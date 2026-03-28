//
//  ErrorTypeTests.swift
//  iOSTests
//
//  Tests for `HealthKitError` and `NotificationError`, the app's structured
//  error types for HealthKit and notification operations. Both implement
//  `LocalizedError` to provide user-facing error descriptions, recovery
//  suggestions, and failure reasons. These messages are shown in alert
//  dialogs when something goes wrong with health data access or notifications.
//

import Testing
import Foundation
@testable import iOS

// MARK: - HealthKitError

/// Validates that each `HealthKitError.ErrorType` produces meaningful,
/// non-empty error descriptions and appropriate recovery suggestions.
struct HealthKitErrorTests {

    /// Every error type should have a non-empty errorDescription so the user
    /// always sees a meaningful message in the error alert.
    @Test(arguments: [
        HealthKitError.ErrorType.permissionDenied,
        .permissionNotDetermined,
        .healthDataUnavailable,
        .heartRateTypeUnavailable,
        .stepCountTypeUnavailable,
        .failedToFetchSamples,
        .failedToFetchStepCount,
        .unknownError
    ])
    func errorDescription_allTypes_nonEmpty(type: HealthKitError.ErrorType) {
        let error = HealthKitError(type: type)
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    /// Permission-related errors should include a recovery suggestion guiding
    /// the user to enable permissions.
    @Test func recoverySuggestion_permissionDenied_present() {
        let error = HealthKitError(type: .permissionDenied)
        #expect(error.recoverySuggestion != nil)
    }

    /// The unknown error should also have a recovery suggestion ("try again later").
    @Test func recoverySuggestion_unknownError_present() {
        let error = HealthKitError(type: .unknownError)
        #expect(error.recoverySuggestion != nil)
    }

    /// Errors without a specific recovery path should return nil.
    @Test func recoverySuggestion_fetchFailed_nil() {
        let error = HealthKitError(type: .failedToFetchSamples)
        #expect(error.recoverySuggestion == nil)
    }

    /// When no underlying error is provided, failureReason should be nil.
    @Test func failureReason_noUnderlyingError_isNil() {
        let error = HealthKitError(type: .unknownError)
        #expect(error.failureReason == nil)
    }

    /// When an underlying error is provided, failureReason should include it.
    @Test func failureReason_withUnderlyingError_isPresent() {
        let underlying = NSError(domain: "test", code: 42, userInfo: [NSLocalizedDescriptionKey: "Something broke"])
        let error = HealthKitError(type: .failedToFetchSamples, underlyingError: underlying)
        #expect(error.failureReason != nil)
        #expect(error.failureReason!.contains("Something broke"))
    }
}

// MARK: - NotificationError

/// Validates that each `NotificationError.ErrorType` produces meaningful,
/// non-empty error descriptions and recovery suggestions.
struct NotificationErrorTests {

    /// Every error type should have a non-empty errorDescription.
    @Test(arguments: [
        NotificationError.ErrorType.permissionDenied,
        .permissionNotDetermined,
        .failedToSendNotification,
        .unknownError
    ])
    func errorDescription_allTypes_nonEmpty(type: NotificationError.ErrorType) {
        let error = NotificationError(type: type)
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    /// All notification error types should have recovery suggestions since
    /// there's always an actionable step the user can take.
    @Test(arguments: [
        NotificationError.ErrorType.permissionDenied,
        .permissionNotDetermined,
        .failedToSendNotification,
        .unknownError
    ])
    func recoverySuggestion_allTypes_present(type: NotificationError.ErrorType) {
        let error = NotificationError(type: type)
        #expect(error.recoverySuggestion != nil)
    }

    /// When no underlying error is provided, failureReason should be nil.
    @Test func failureReason_noUnderlyingError_isNil() {
        let error = NotificationError(type: .unknownError)
        #expect(error.failureReason == nil)
    }

    /// When an underlying error is provided, failureReason should include it.
    @Test func failureReason_withUnderlyingError_isPresent() {
        let underlying = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network timeout"])
        let error = NotificationError(type: .failedToSendNotification, underlyingError: underlying)
        #expect(error.failureReason != nil)
        #expect(error.failureReason!.contains("Network timeout"))
    }
}
