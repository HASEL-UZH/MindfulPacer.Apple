//
//  BatteryView.swift
//  WatchOS
//
//  Created by Grigor Dochev on 15.08.2025.
//

import SwiftUI
import WatchKit

struct BatteryView: View {
    @State private var batteryLevel: Float = WKInterfaceDevice.current().batteryLevel

    var body: some View {
        HStack {
            ProgressView(value: batteryLevel)
                .progressViewStyle(.linear)
                .tint(batteryTintColor)
                .layoutPriority(1)
        }
        .padding()
        .onAppear {
            let device = WKInterfaceDevice.current()
            device.isBatteryMonitoringEnabled = true
            updateBattery()
            
            NotificationCenter.default.addObserver(
                forName: Notification.Name("WKInterfaceDeviceBatteryLevelDidChangeNotification"),
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor in
                    updateBattery()
                }
            }
        }
    }
    
    private func updateBattery() {
        batteryLevel = WKInterfaceDevice.current().batteryLevel
    }

    private var batteryTintColor: Color {
        switch batteryLevel {
        case ..<0.2: return .red
        case ..<0.5: return .yellow
        default: return .green
        }
    }
}

#Preview {
    BatteryView()
}


#Preview {
    BatteryView()
}
