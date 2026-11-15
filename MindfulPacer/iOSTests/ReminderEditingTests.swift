import Testing
import Foundation
import SwiftData
@testable import iOS

@MainActor
struct ReminderEditingTests {
    /// Editing an existing reminder saves a changed strength, also for background detection.
    @Test func savingAnExistingReminderPersistsItsNewStrength() throws {
        let container = try ModelContainer(for: Reminder.self, configurations:
            ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        let reminder = Reminder(measurementType: .heartRate, reminderType: .light, threshold: 120, interval: .fiveMinutes)
        container.mainContext.insert(reminder)
        let reminderID = reminder.id
        // Saving mirrors the reminder into the shared background store.
        defer { BackgroundRemindersStore.shared.remove(id: reminderID) }
        let model = CreateReminderViewModel(
            modelContext: container.mainContext,
            watchUpdateService: WatchUpdateService.shared,
            triggerWatchNotificationUseCase: DefaultTriggerWatchNotificationUseCase()
        )

        model.configureMode(with: reminder)
        #expect(model.selectedReminderType == .light)
        model.selectedReminderType = .strong
        model.saveReminder(reminder)

        #expect(reminder.reminderType == .strong)
        #expect(reminder.measurementType == .heartRate)
        #expect(reminder.threshold == 120)
        #expect(reminder.interval == .fiveMinutes)
        let mirrored = BackgroundRemindersStore.shared.load().first { $0.id == reminderID }
        #expect(mirrored?.reminderType == .strong, "Background detection must use the edited strength.")
        #expect(model.shouldDismiss)
    }
}
