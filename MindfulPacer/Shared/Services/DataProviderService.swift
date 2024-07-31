//
//  DataProviderService.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 21.07.2024.
//

import Foundation
import SwiftData
import SwiftUI

protocol DataProviderServiceProtocol: Sendable {
    func dataHandlerCreator(preview: Bool) -> @Sendable () async -> DataHandler
    func dataHandlerWithMainContextCreator(preview: Bool) -> @Sendable @MainActor () async -> DataHandler
}

final class DataProviderService: NSObject, DataProviderServiceProtocol, @unchecked Sendable {
    static let shared = DataProviderService()
    
    let sharedModelContainer: ModelContainer = {
        let schema = Schema(CurrentScheme.models)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    let previewContainer: ModelContainer = {
        let schema = Schema(CurrentScheme.models)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
        
    func dataHandlerCreator(preview: Bool = false) -> @Sendable () async -> DataHandler {
        let container = preview ? previewContainer : sharedModelContainer
        return { DataHandler(modelContainer: container) }
    }
    
    func dataHandlerWithMainContextCreator(preview: Bool = false) -> @Sendable @MainActor () async -> DataHandler {
        let container = preview ? previewContainer : sharedModelContainer
        return { DataHandler(modelContainer: container, mainActor: true) }
    }
}

public struct DataHandlerKey: EnvironmentKey {
    public static let defaultValue: @Sendable () async -> DataHandler? = { nil }
}

extension EnvironmentValues {
    public var createDataHandler: @Sendable () async -> DataHandler? {
        get { self[DataHandlerKey.self] }
        set { self[DataHandlerKey.self] = newValue }
    }
}

public struct MainActorDataHandlerKey: EnvironmentKey {
    public static let defaultValue: @Sendable @MainActor () async -> DataHandler? = { nil }
}

extension EnvironmentValues {
    public var createDataHandlerWithMainContext: @Sendable @MainActor () async -> DataHandler? {
        get { self[MainActorDataHandlerKey.self] }
        set { self[MainActorDataHandlerKey.self] = newValue }
    }
}

@ModelActor
public actor DataHandler {
    @MainActor
    public init(modelContainer: ModelContainer, mainActor _: Bool) {
        let modelContext = modelContainer.mainContext
        modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
        self.modelContainer = modelContainer
    }
    
    @discardableResult
    public func newItem(timestamp: Date, heartRate: Double) throws -> PersistentIdentifier {
        let heartRateSample = HeartRateSample(timestamp: timestamp, heartRate: heartRate)
        modelContext.insert(heartRateSample)
        try modelContext.save()
        return heartRateSample.persistentModelID
    }
}
