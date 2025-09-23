//
//  AppDelegate.swift
//  iOS
//
//  Created by Grigor Dochev on 12.08.2025.
//

import Foundation
import UIKit
import WatchConnectivity
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {
    
    private let connectivityService = ConnectivityService.shared
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        
        MissedReflectionsMonitorService.shared.registerBackgroundTask()
        MissedReflectionsMonitorService.shared.scheduleAppRefresh()
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = connectivityService
            session.activate()
            print("DEBUGY IPHONE: AppDelegate configured WCSession delegate.")
        } else {
            print("DEBUGY IPHONE: WCSession not supported on this device.")
        }
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        MissedReflectionsMonitorService.shared.scheduleAppRefresh()
    }
}
