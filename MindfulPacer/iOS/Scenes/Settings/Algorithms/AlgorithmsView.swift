//
//  AlgorithmsView.swift
//  iOS
//
//  Created by Grigor Dochev on 06.04.2025.
//

import SwiftUI

// MARK: - AlgorithmsView

struct AlgorithmsView: View {
    
    // MARK: Properties
    
    @ObservedObject private var settings = IntervalSettingsManager.shared
    
    // MARK: Body
    
    var body: some View {
        RoundedList {
            VStack(spacing: 16) {
                IconLabelGroupBox(
                    label:
                        IconLabel(
                            icon: "slider.horizontal.below.square.and.square.filled",
                            title: "Missed Reflections",
                            labelColor: .brandPrimary,
                            background: true
                        ),
                    description:
                        Text("The buffer sets the minimum time between repeated missed reflection triggers for the same reminder.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                ) {
                    IconLabel(
                        icon: "heart",
                        title: "Heart Rate",
                        labelColor: .pink,
                        background: true
                    )
                    .font(.subheadline.weight(.semibold))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            ForEach(Reminder.Interval.heartRateIntervals, id: \.self) { interval in
                                Card(backgroundColor: Color(.tertiarySystemGroupedBackground)) {
                                    IntervalSliderView(
                                        interval: interval,
                                        context: .heartRate,
                                        settings: settings
                                    )
                                }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                    
                    Divider()
                    
                    IconLabel(
                        icon: "figure.walk",
                        title: "Steps",
                        labelColor: .teal,
                        background: true
                    )
                    .font(.subheadline.weight(.semibold))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            ForEach(Reminder.Interval.stepsIntervals, id: \.self) { interval in
                                Card(backgroundColor: Color(.tertiarySystemGroupedBackground)) {
                                    IntervalSliderView(
                                        interval: interval,
                                        context: .steps,
                                        settings: settings
                                    )
                                }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                }
                .iconLabelGroupBoxStyle(.divider)
                
                PrimaryButton(
                    title: "Reset to Defaults",
                    icon: "arrow.clockwise",
                    color: .red
                ) {
                    settings.resetToDefaults()
                }
            }
        }
        .navigationTitle("Algorithms")
    }
}

// MARK: - IntervalSliderView

private struct IntervalSliderView: View {
    let interval: Reminder.Interval
    let context: IntervalContext
    @ObservedObject var settings: IntervalSettingsManager
    
    private var defaultBuffer: Double {
        switch (interval, context) {
        case (.immediately, _): return 0
        case (.fiveMinutes, .heartRate): return 60
        case (.tenMinutes, .heartRate): return 120
        case (.fifteenMinutes, .heartRate): return 180
        case (.thirtyMinutes, .heartRate): return 360
        case (.thirtyMinutes, .steps): return 450
        case (.oneHour, .heartRate): return 720
        case (.oneHour, .steps): return 900
        case (.twoHours, .steps): return 1800
        case (.fourHours, .steps): return 3600
        case (.oneDay, .steps): return 0
        default: return 0
        }
    }
    
    private var bufferRange: ClosedRange<Double> {
        let buffer = defaultBuffer
        let delta = buffer * 0.5 // ±50% of the default buffer
        let lowerBound = max(0, buffer - delta)
        let upperBound: Double
        switch interval {
        case .immediately:
            return 0...10        // Special case: 0 to 10 seconds
        case .oneDay:
            upperBound = 7200    // Special case: up to 120 minutes
        default:
            upperBound = buffer + delta
        }
        return lowerBound...upperBound
    }
    
    private var bufferStep: Double {
        switch interval {
        case .immediately:
            return 1             // 1-second steps
        case .oneMinute:
            return 5
        case .fiveMinutes, .tenMinutes, .fifteenMinutes:
            return 5             // 5-second steps
        case .thirtyMinutes:
            return 15            // 15-second steps
        case .oneHour:
            return 30            // 30-second steps
        case .twoHours:
            return 60            // 1-minute steps
        case .fourHours, .oneDay:
            return 300           // 5-minute steps
        }
    }
    
    private func formattedTime(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        switch interval {
        case .immediately, .oneMinute, .fiveMinutes, .tenMinutes, .fifteenMinutes:
            return "\(totalSeconds) sec"
        case .thirtyMinutes, .oneHour:
            let minutes = totalSeconds / 60
            return "\(minutes) min"
        case .twoHours, .fourHours, .oneDay:
            let hours = totalSeconds / 3600
            let remainingMinutes = (totalSeconds % 3600) / 60
            if hours == 0 {
                return "\(remainingMinutes) min"
            } else if remainingMinutes == 0 {
                return "\(hours) hr"
            } else {
                return "\(hours) hr \(remainingMinutes) min"
            }
        }
    }
    
    private func formattedBuffer(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        switch interval {
        case .immediately, .oneMinute, .fiveMinutes, .tenMinutes, .fifteenMinutes:
            return "\(totalSeconds) sec"
        case .thirtyMinutes, .oneHour:
            let minutes = totalSeconds / 60
            return "\(minutes) min"
        case .twoHours, .fourHours, .oneDay:
            let hours = totalSeconds / 3600
            let remainingMinutes = (totalSeconds % 3600) / 60
            if hours == 0 {
                return "\(remainingMinutes) min"
            } else if remainingMinutes == 0 {
                return "\(hours) hr"
            } else {
                return "\(hours) hr \(remainingMinutes) min"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            IconLabel(
                icon: interval.icon,
                title: interval.localized,
                description: formattedBuffer(settings.buffer(for: interval, context: context))
            )
            .font(.subheadline.weight(.semibold))
            
            Slider(
                value: Binding(
                    get: { settings.buffer(for: interval, context: context) },
                    set: { settings.setBuffer($0, for: interval, context: context) }
                ),
                in: bufferRange,
                step: bufferStep
            ) {
                IconLabel(
                    icon: interval.icon,
                    title: interval.localized,
                    description: "Buffer: \(formattedBuffer(settings.buffer(for: interval, context: context)))",
                    labelColor: .brandPrimary,
                    background: true
                )
                .font(.subheadline.weight(.semibold))
            }
            .tint(.brandPrimary)
        }
        .frame(minWidth: 256)
    }
}

// MARK: - Preview

#Preview {
    AlgorithmsView()
}
