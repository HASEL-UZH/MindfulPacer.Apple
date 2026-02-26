//
//  AppGroupPaths.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 26.02.2026.
//

import Foundation

enum AppGroupPaths {
    static let groupID = "group.com.MindfulPacer"

    @discardableResult
    static func prepareApplicationSupport() -> URL? {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
            print("AppGroup container not found")
            return nil
        }
        let appSupport = container
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
            return appSupport
        } catch {
            print("Failed to create Application Support in group: \(error)")
            return nil
        }
    }
}
