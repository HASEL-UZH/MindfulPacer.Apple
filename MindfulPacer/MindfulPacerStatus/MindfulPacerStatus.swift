//
//  MindfulPacerStatus.swift
//  MindfulPacerStatus
//
//  Created by Grigor Dochev on 21.08.2025.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    private var monitoringState: ComplicationState {
        let defaults = UserDefaults(suiteName: "group.com.MindfulPacer")

        let raw = defaults?.integer(forKey: ComplicationKeys.state) ?? ComplicationState.inactive.rawValue
        let state = ComplicationState(rawValue: raw) ?? .inactive

        /// If app was force-killed, heartbeat stops. Expire "active" to "paused".
        if state == .active {
            let last = defaults?.double(forKey: ComplicationKeys.lastUpdated) ?? 0
            let age = Date().timeIntervalSince1970 - last

            if age > 180 { // 3 minutes, do not set too too low or it'll mislabel during brief OS stalls
                return .paused
            }
        }

        return state
    }
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), state: .active)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), state: monitoringState)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let entry = SimpleEntry(date: Date(), state: monitoringState)
        let next = Date().addingTimeInterval(60)
        let timeline = Timeline(entries: [entry], policy: .after(next))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let state: ComplicationState
}

struct MindfulPacerStatusEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    private var iconName: String {
        switch entry.state {
        case .active: return "checkmark.circle.fill"
        case .paused: return "pause.circle.fill"
        case .inactive: return "xmark.circle.fill"
        }
    }
    
    private var labelText: String {
        switch entry.state {
        case .active: return "Monitoring"
        case .paused: return "Paused"
        case .inactive: return "Inactive"
        }
    }
    
    private var color: Color {
        switch entry.state {
        case .active: return .green
        case .paused: return .yellow
        case .inactive: return .red
        }
    }

    @ViewBuilder
    var body: some View {
        switch family {
        case .accessoryCircular:
            Image(systemName: iconName)
                .font(.headline)
                .widgetLabel { Text(labelText) }
                .widgetAccentable()
                .foregroundColor(color)
                
        case .accessoryRectangular:
            HStack {
                Image(systemName: iconName)
                    .foregroundStyle(color)
                    .symbolRenderingMode(.hierarchical)
                    .font(.largeTitle.bold())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("MindfulPacer")
                        .bold()
                        .widgetAccentable()
                    Text(labelText)
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(color)
                }
                Spacer()
            }
            .padding(.leading, 8)

        case .accessoryCorner:
            Image(systemName: iconName)
                .foregroundStyle(color)
                .symbolRenderingMode(.hierarchical)

        case .accessoryInline:
            Label(labelText, systemImage: iconName)
            
        @unknown default:
            Label(labelText, systemImage: iconName)
        }
    }
}

#Preview(as: .accessoryRectangular) {
    MindfulPacerStatus()
} timeline: {
    SimpleEntry(date: .now, state: .active)
    SimpleEntry(date: .now, state: .paused)
    SimpleEntry(date: .now, state: .inactive)
}
