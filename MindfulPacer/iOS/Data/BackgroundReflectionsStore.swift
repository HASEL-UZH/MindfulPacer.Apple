//
//  BackgroundReflectionsStore.swift
//  iOS
//
//  Created by Grigor Dochev on 08.01.2026.
//

import Foundation

// Uses the same suite name as your reminders store

struct BackgroundReflectionSnapshot: Codable, Sendable, Equatable, Hashable {
    let id: UUID
    let date: Date
    let measurementType: Reminder.MeasurementType? // nil matters for your "rejectedAnyType" logic
    let isRejected: Bool
    let isHandled: Bool // true if user handled it (activity != nil) or your chosen definition

    init(
        id: UUID,
        date: Date,
        measurementType: Reminder.MeasurementType?,
        isRejected: Bool,
        isHandled: Bool
    ) {
        self.id = id
        self.date = date
        self.measurementType = measurementType
        self.isRejected = isRejected
        self.isHandled = isHandled
    }
}

@MainActor
final class BackgroundReflectionsStore {
    static let shared = BackgroundReflectionsStore()

    private let defaults: UserDefaults = UserDefaults(suiteName: AppGroups.suite) ?? .standard
    private let key = "BackgroundReflectionSnapshots.v1"

    private init() {}

    func load() -> [BackgroundReflectionSnapshot] {
        guard let data = defaults.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([BackgroundReflectionSnapshot].self, from: data)
        } catch {
            defaults.removeObject(forKey: key)
            return []
        }
    }

    func save(_ items: [BackgroundReflectionSnapshot]) {
        do {
            let data = try JSONEncoder().encode(items)
            defaults.set(data, forKey: key)
        } catch {
            // swallow
        }
    }

    func upsert(_ snapshot: BackgroundReflectionSnapshot) {
        var current = load()
        if let idx = current.firstIndex(where: { $0.id == snapshot.id }) {
            current[idx] = snapshot
        } else {
            current.append(snapshot)
        }
        save(current)
    }

    func remove(id: UUID) {
        var current = load()
        current.removeAll { $0.id == id }
        save(current)
    }

    func replace(with snapshots: [BackgroundReflectionSnapshot]) {
        save(snapshots)
    }
}

extension BackgroundReflectionSnapshot {
    init(from reflection: Reflection) {
        self.init(
            id: reflection.id,
            date: reflection.date,
            measurementType: reflection.measurementType,
            isRejected: reflection.isRejected,
            isHandled: (reflection.activity != nil)
        )
    }
}
