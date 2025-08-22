//
//  MindfulPacerStatus.swift
//  MindfulPacerStatus
//
//  Created by Grigor Dochev on 21.08.2025.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    private var isMonitoringActive: Bool {
        let defaults = UserDefaults(suiteName: "group.com.MindfulPacer")
        return defaults?.bool(forKey: "isMonitoringActive") ?? false
    }
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), isMonitoring: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), isMonitoring: isMonitoringActive)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
         let entry = SimpleEntry(date: Date(), isMonitoring: isMonitoringActive)
         
         let timeline = Timeline(entries: [entry], policy: .never)
         completion(timeline)
     }
 }

struct SimpleEntry: TimelineEntry {
    let date: Date
    let isMonitoring: Bool
}

struct MindfulPacerStatusEntryView : View {
    var entry: Provider.Entry
    
    @Environment(\.widgetFamily) var family

    @ViewBuilder
    var body: some View {
        switch family {
        case .accessoryCircular:
            Label("MP", systemImage: entry.isMonitoring ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(entry.isMonitoring ? .accent : .red)
                .symbolRenderingMode(.hierarchical)
                .widgetLabel {
                    Text(entry.isMonitoring ? "Monitoring" : "Inactive")
                }
                .widgetAccentable()
        case .accessoryRectangular:
            HStack {
                Image(systemName: entry.isMonitoring ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(entry.isMonitoring ? .accent : .red)
                    .symbolRenderingMode(.hierarchical)
                    .font(.largeTitle.bold())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("MindfulPacer")
                        .bold()
                        .widgetAccentable()
                    Text(entry.isMonitoring ? "Monitoring" : "Inactive")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(entry.isMonitoring ? .accent : .red)
                    
                }
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .foregroundStyle(.primary.opacity(0.1))
            )
        case .accessoryCorner:
            Image(systemName: entry.isMonitoring ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(entry.isMonitoring ? .accent : .red)
                .symbolRenderingMode(.hierarchical)
                .font(.largeTitle.bold())
        case .accessoryInline:
            Label(entry.isMonitoring ? "Monitoring" : "Inactive", systemImage: entry.isMonitoring ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(entry.isMonitoring ? .accent : .red)
                .symbolRenderingMode(.hierarchical)
                .widgetLabel {
                    Text(entry.isMonitoring ? "Monitoring" : "Inactive")
                }
                .widgetAccentable()
        @unknown default:
            Label(entry.isMonitoring ? "Monitoring" : "Inactive", systemImage: entry.isMonitoring ? "checkmark.circle.fill" : "xmark.circle.fill")
        }
    }
}

#Preview(as: .accessoryRectangular) {
    MindfulPacerStatus()
} timeline: {
    SimpleEntry(date: .now, isMonitoring: true)
    SimpleEntry(date: .now, isMonitoring: false)
}

#Preview(as: .accessoryCircular) {
    MindfulPacerStatus()
} timeline: {
    SimpleEntry(date: .now, isMonitoring: true)
    SimpleEntry(date: .now, isMonitoring: false)
}

#Preview(as: .accessoryCorner) {
    MindfulPacerStatus()
} timeline: {
    SimpleEntry(date: .now, isMonitoring: true)
    SimpleEntry(date: .now, isMonitoring: false)
}

#Preview(as: .accessoryInline) {
    MindfulPacerStatus()
} timeline: {
    SimpleEntry(date: .now, isMonitoring: true)
    SimpleEntry(date: .now, isMonitoring: false)
}
