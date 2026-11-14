#if DEBUG && targetEnvironment(simulator)
import Foundation
import SwiftData
import Factory

/// Opt-in, simulator-only fixtures for the screenshot catalog. Never reads or writes HealthKit.
/// Launch with -redesign-capture; add -capture-empty or -capture-health-error for recovery states.
@MainActor
enum RedesignCaptureSupport {
    static var isEnabled: Bool { ProcessInfo.processInfo.arguments.contains("-redesign-capture") }
    static var isEmpty: Bool { ProcessInfo.processInfo.arguments.contains("-capture-empty") }

    static let container: ModelContainer = {
        let schema = Schema(CurrentScheme.models)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        if !isEmpty { seed(container.mainContext) }
        return container
    }()

    static func configure() {
        guard isEnabled else { return }
        ScenesContainer.shared.editReflectionViewModel.register {
            EditReflectionViewModel(modelContext: container.mainContext)
        }
        ScenesContainer.shared.homeViewModel.register {
            HomeViewModel(modelContext: container.mainContext,
                          checkHealthPermissionsUseCase: CapturePermissions(),
                          fetchCurrentHeartRateUseCase: CaptureCurrentHeartRate(),
                          fetchCurrentStepsUseCase: CaptureCurrentSteps(),
                          fetchHeartRateDataLast24HoursUseCase: CaptureDailyHistory(heartRate: true),
                          fetchMissedReflectionsUseCase: CaptureMissedReflections(),
                          fetchStepDataLast24HoursUseCase: CaptureDailyHistory(heartRate: false))
        }
        ScenesContainer.shared.analyticsViewModel.register {
            AnalyticsViewModel(modelContext: container.mainContext,
                               fetchHeartRateUseCase: CaptureHistory(heartRate: true),
                               fetchStepsUseCase: CaptureHistory(heartRate: false))
        }
        ScenesContainer.shared.onboardingViewModel.register {
            OnboardingViewModel(initializeNotificationsUseCase: CaptureNotifications(),
                                requestHealthAuthorisationUseCase: CaptureHealthAuthorization(),
                                toggleUserHasSeenOnboardingUseCase: UseCasesContainer.shared.toggleUserHasSeenOnboardingUseCase())
        }
    }

    private static func seed(_ context: ModelContext) {
        let specifications = [
            ("movement", "Movement", "figure.run", "walking", "Walking", "figure.walk"),
            ("selfcare", "Selfcare", "shower", "meditation", "Meditation", "figure.mind.and.body"),
            ("cognitive", "Cognitive", "character.book.closed", "reading", "Reading", "book"),
            ("household", "Household", "house", "cooking", "Cooking", "fork.knife")
        ]
        let activities: [Activity] = specifications.map { item in
            let activity = Activity(seedKey: item.0, name: item.1, icon: item.2)
            let subactivity = Subactivity(seedKey: item.0 + "." + item.3, name: item.4, icon: item.5, activity: activity)
            activity.subactivities = [subactivity]
            context.insert(activity)
            return activity
        }
        let now = Date.now
        for index in 0..<28 {
            let activity = activities[index % activities.count]
            let minutes = index < 3 ? Double(12 + index * 18) : Double(150 + (index - 3) * 365)
            let reflection = Reflection(date: now.addingTimeInterval(-minutes * 60), activity: activity,
                subactivity: activity.subactivities?.first, mood: DefaultMoodData.moods[index % DefaultMoodData.moods.count],
                didTriggerCrash: index % 9 == 6, wellBeing: index % 5, fatigue: index % 4,
                shortnessOfBreath: 1, sleepDisorder: 2, cognitiveImpairment: 2, physicalPain: 1,
                depressionOrAnxiety: 1,
                additionalInformation: index % 2 == 0 ? "Took a short break and paced the activity. Felt better after resting." : "")
            context.insert(reflection)
        }
        for (index, strength) in Reminder.ReminderType.allCases.enumerated() {
            context.insert(Reminder(measurementType: .heartRate, reminderType: strength,
                                    threshold: 90 + index * 10, interval: .oneMinute))
            context.insert(Reminder(measurementType: .steps, reminderType: strength,
                                    threshold: 500 + index * 250, interval: .thirtyMinutes))
            for type in Reminder.MeasurementType.allCases {
                let end = now.addingTimeInterval(-Double(30 + index * 150 + (type == .steps ? 60 : 0)) * 60)
                let samples: [MeasurementSample] = (0..<40).map { point in
                    let value = type == .heartRate
                        ? 83 + 25 * sin(Double(point) / 12) + 3 * sin(Double(point))
                        : 12 + 10 * abs(sin(Double(point) / 4))
                    return MeasurementSample(type: type == .heartRate ? .heartRate : .steps,
                                             value: value, date: end.addingTimeInterval(Double(point - 39) * 60))
                }
                context.insert(Reflection(date: end, wellBeing: nil, fatigue: nil, shortnessOfBreath: nil,
                    sleepDisorder: nil, cognitiveImpairment: nil, physicalPain: nil, depressionOrAnxiety: nil,
                    measurementType: type, reminderType: strength, threshold: type == .heartRate ? 90 + index * 10 : 500 + index * 250,
                    interval: type == .heartRate ? .oneMinute : .thirtyMinutes, triggerSamples: samples))
            }
        }
        try! context.save()
    }
}

private enum CaptureHealthData {
    static var empty: Bool { ProcessInfo.processInfo.arguments.contains("-capture-empty") }
    static var failed: Bool { ProcessInfo.processInfo.arguments.contains("-capture-health-error") }

    static func heartRate(at date: Date) -> Double {
        let phase = date.timeIntervalSince1970 / 3600
        return 78 + 13 * sin(phase * 1.4) + 5 * sin(phase * 7) + 2 * sin(phase * 20)
    }

    /// One underlying minute-resolution series, aggregated consistently for every chart period.
    static func steps(from start: Date, to end: Date) -> Double {
        stride(from: start.timeIntervalSince1970, to: end.timeIntervalSince1970, by: 60).reduce(0) { total, time in
            let date = Date(timeIntervalSince1970: time)
            let hour = Calendar.current.component(.hour, from: date)
            let phase = time / 3600
            return total + (hour < 7 || hour > 22 ? 0 : max(0, 3 + 5 * sin(phase * 2)))
        }.rounded()
    }

    static func entries(heartRate: Bool, period: Period, start: Date, end: Date) -> [ChartDataItem] {
        guard !empty else { return [] }
        if ProcessInfo.processInfo.arguments.contains("-capture-single-reading") {
            let date = end.addingTimeInterval(-15 * 60)
            return [ChartDataItem(startDate: date, endDate: date, value: heartRate ? 85 : 125)]
        }
        let cadence: Double = period == .week ? (heartRate ? 3600 : 86400) : (period == .day ? 900 : 180)
        let first = !heartRate && period == .week
            ? Calendar.current.startOfDay(for: start).timeIntervalSince1970
            : floor(start.timeIntervalSince1970 / cadence) * cadence
        return stride(from: first, to: end.timeIntervalSince1970, by: cadence).map { time in
            let date = Date(timeIntervalSince1970: time)
            let bucketEnd = min(date.addingTimeInterval(cadence), end)
            let value = heartRate ? self.heartRate(at: date) : steps(from: date, to: bucketEnd)
            return ChartDataItem(startDate: date, endDate: heartRate ? date : bucketEnd, value: value)
        }
    }
}

private struct CaptureHistory: FetchHeartRateUseCase, FetchStepsUseCase {
    let heartRate: Bool
    func execute(for period: Period, endDate: Date, completion: @escaping @Sendable (Result<[ChartDataItem], HealthKitError>) -> Void) {
        executeHistory(for: period, startDate: period.startDate(relativeTo: endDate), endDate: endDate, completion: completion)
    }
    func executeBucketed(for period: Period, endDate: Date, completion: @escaping @Sendable (Result<[ChartDataItem], HealthKitError>) -> Void) {
        execute(for: period, endDate: endDate, completion: completion)
    }
    func executeHistory(for period: Period, startDate: Date, endDate: Date, completion: @escaping @Sendable (Result<[ChartDataItem], HealthKitError>) -> Void) {
        if CaptureHealthData.failed { completion(.failure(HealthKitError(type: .failedToFetchSamples))); return }
        completion(.success(CaptureHealthData.entries(heartRate: heartRate, period: period, start: startDate, end: endDate)))
    }
}

private struct CaptureDailyHistory: FetchHeartRateDataLast24HoursUseCase, FetchStepsDataLast24HoursUseCase {
    let heartRate: Bool
    func execute(completion: @Sendable @escaping ([(startDate: Date, endDate: Date, stepCount: Double)]) -> Void) {
        completion(CaptureHealthData.entries(heartRate: heartRate, period: .day, start: .now.addingTimeInterval(-86400), end: .now)
            .map { (startDate: $0.startDate, endDate: $0.endDate, stepCount: $0.value) })
    }
}
private struct CaptureCurrentHeartRate: FetchCurrentHeartRateUseCase {
    func execute(completion: @escaping @Sendable (Result<(heartRate: Double, timestamp: Date), Error>) -> Void) {
        if CaptureHealthData.empty { completion(.failure(HealthKitError(type: .failedToFetchSamples))); return }
        let timestamp = Date.now.addingTimeInterval(-120)
        completion(.success((heartRate: CaptureHealthData.heartRate(at: timestamp), timestamp: timestamp)))
    }
}
private struct CaptureCurrentSteps: FetchCurrentStepsUseCase {
    func execute(completion: @escaping @Sendable (Result<(stepCount: Double, timestamp: Date), Error>) -> Void) {
        if CaptureHealthData.empty { completion(.failure(HealthKitError(type: .failedToFetchSamples))); return }
        let timestamp = Date.now
        completion(.success((stepCount: CaptureHealthData.steps(from: Calendar.current.startOfDay(for: timestamp), to: timestamp), timestamp: timestamp)))
    }
}
private struct CapturePermissions: CheckHealthPermissionsUseCase {
    func execute(deviceMode: DeviceMode, completion: @escaping @Sendable (HealthPermissionsState) -> Void) {
        completion(CaptureHealthData.failed ? .needsRequest : .ok)
    }
}
private struct CaptureMissedReflections: FetchMissedReflectionsUseCase {
    private func complete(_ completion: @escaping @MainActor (Result<[Reflection], HealthKitError>) -> Void) {
        Task { @MainActor in
            let all = (try? RedesignCaptureSupport.container.mainContext.fetch(FetchDescriptor<Reflection>())) ?? []
            completion(.success(all.filter { $0.isMissedReflection && !$0.isRejected }.sorted { $0.date > $1.date }))
        }
    }
    func execute(reminders: [Reminder], existingReflections: [Reflection], completion: @escaping @MainActor (Result<[Reflection], HealthKitError>) -> Void) { complete(completion) }
    func execute(reminderConfigs: [BackgroundReminderConfig], existingReflections: [Reflection], completion: @escaping @MainActor (Result<[Reflection], HealthKitError>) -> Void) { complete(completion) }
    func execute(reminderConfigs: [BackgroundReminderConfig], existingReflectionSnapshots: [BackgroundReflectionSnapshot], completion: @escaping @MainActor (Result<[Reflection], HealthKitError>) -> Void) { complete(completion) }
}
private struct CaptureNotifications: InitializeNotificationsUseCase {
    func execute(completion: @escaping @Sendable (Result<Void, NotificationError>) -> Void) { completion(.success(())) }
}
private struct CaptureHealthAuthorization: RequestHealthAuthorisationUseCase {
    func execute(completion: @escaping @Sendable (Bool, HealthKitError?) -> Void) { completion(true, nil) }
}
#endif
