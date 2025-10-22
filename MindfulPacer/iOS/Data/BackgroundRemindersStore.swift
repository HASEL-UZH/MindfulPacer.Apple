//
//  BackgroundRemindersStore.swift
//  iOS
//
//  Created by Grigor Dochev on 29.09.2025.
//

import Foundation

enum AppGroups {
    static let suite = "group.com.MindfulPacer"
}

struct BackgroundReminderConfig: Codable, Sendable, Equatable, Hashable {
    let id: UUID
    let measurementType: Reminder.MeasurementType
    let reminderType: Reminder.ReminderType
    let threshold: Int
    let interval: Reminder.Interval

    init(
        id: UUID,
        measurementType: Reminder.MeasurementType,
        reminderType: Reminder.ReminderType,
        threshold: Int,
        interval: Reminder.Interval
    ) {
        self.id = id
        self.measurementType = measurementType
        self.reminderType = reminderType
        self.threshold = threshold
        self.interval = interval
    }

    init(from reminder: Reminder) {
        self.init(
            id: reminder.id,
            measurementType: reminder.measurementType,
            reminderType: reminder.reminderType,
            threshold: reminder.threshold,
            interval: reminder.interval
        )
    }
}

@MainActor
final class BackgroundRemindersStore {
    static let shared = BackgroundRemindersStore()

    private let defaults: UserDefaults = UserDefaults(suiteName: AppGroups.suite) ?? .standard
    private let key = "BackgroundReminderConfigs.v1"

    private init() {}

    func load() -> [BackgroundReminderConfig] {
        guard let data = defaults.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([BackgroundReminderConfig].self, from: data)
        } catch {
            defaults.removeObject(forKey: key)
            return []
        }
    }

    func save(_ items: [BackgroundReminderConfig]) {
        do {
            let data = try JSONEncoder().encode(items)
            defaults.set(data, forKey: key)
        } catch {
            // swallow
        }
    }

    func upsert(_ config: BackgroundReminderConfig) {
        var current = load()
        if let idx = current.firstIndex(where: { $0.id == config.id }) {
            current[idx] = config
        } else {
            current.append(config)
        }
        save(current)
    }

    func remove(id: UUID) {
        var current = load()
        current.removeAll { $0.id == id }
        save(current)
    }

    func replace(with reminders: [Reminder]) {
        let mapped = reminders.map(BackgroundReminderConfig.init(from:))
        save(mapped)
    }
}
