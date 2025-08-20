//
//  Services.swift
//  WatchOS
//
//  Created by Grigor Dochev on 20.08.2025.
//

import Foundation

@MainActor
class Services {
    static let shared = Services()
    
    let monitorService = HealthMonitorService()
    let systemDelegate = SystemDelegate()
    let navigationManager = NavigationManager()
    
    private init() {}
    
    func configure() {
        systemDelegate.configure()
    }
}
