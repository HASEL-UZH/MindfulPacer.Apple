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

        /// If app was force-killed, heartbeat stops. Use tiered timeout to detect this:
        /// - First 2 minutes: Definitely active (allows for normal variance)
        /// - 2-5 minutes: Show as paused (might be force-closed or system suspended)
        /// - 5+ minutes: Show as inactive (definitely force-closed)
        if state == .active {
            let last = defaults?.double(forKey: ComplicationKeys.lastUpdated) ?? 0
            let age = Date().timeIntervalSince1970 - last

            if age > 300 {
                return .inactive  // Definitely dead after 5 minutes
            } else if age > 120 {
                return .paused    // Possibly dead after 2 minutes
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
    @Environment(\.widgetFamily) private var family

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
                .font(.title2.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .widgetLabel { Text(LocalizedStringKey(labelText)) }
                .widgetAccentable()
                .foregroundStyle(color)
                
        case .accessoryRectangular:
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .foregroundStyle(color)
                    .symbolRenderingMode(.hierarchical)
                    .font(.title2.weight(.semibold))
                    .widgetAccentable()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("MindfulPacer")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(LocalizedStringKey(labelText))
                        .font(.headline)
                        .foregroundStyle(color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

        case .accessoryCorner:
            Image(systemName: iconName)
                .foregroundStyle(color)
                .symbolRenderingMode(.hierarchical)
                .widgetAccentable()
                .widgetLabel { Text(LocalizedStringKey(labelText)) }

        case .accessoryInline:
            Label(LocalizedStringKey(labelText), systemImage: iconName)
            
        @unknown default:
            Label(LocalizedStringKey(labelText), systemImage: iconName)
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
