//
//  AppInfoService.swift
//  WatchOS
//
//  Created by Grigor Dochev on 15.08.2025.
//

import Foundation

struct AppInfoService {
    static var appVersion: String {
        // "CFBundleShortVersionString" is the user-facing version number (e.g., 1.2.3)
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
    }
    
    static var buildNumber: String {
        // "CFBundleVersion" is the build number (e.g., 145)
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "N/A"
    }
    
    static var bundleIdentifier: String {
        return Bundle.main.bundleIdentifier ?? "N/A"
    }
}
