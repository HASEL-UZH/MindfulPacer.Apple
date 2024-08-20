//
//  ProcessInfo+Extensions.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 20.08.2024.
//

import Foundation

extension ProcessInfo {
    /// Checks if the app is running in an Xcode SwiftUI preview.
    var isRunningInPreview: Bool {
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}
