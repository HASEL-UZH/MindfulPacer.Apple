//
//  MindfulPacerStatusBundle.swift
//  MindfulPacerStatus
//
//  Created by Grigor Dochev on 21.08.2025.
//

import WidgetKit
import SwiftUI

@main
struct MindfulPacerStatus: Widget {
    let kind: String = "MindfulPacerStatus"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MindfulPacerStatusEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Monitoring Status")
        .description("See if MindfulPacer monitoring is active at a glance.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}
