//
//  MissedReflectionsListView.swift
//  iOS
//
//  Created by Grigor Dochev on 28.03.2025.
//

import SwiftUI

// MARK: - MissedReflectionsListView

struct MissedReflectionsListView: View {
    
    // MARK: Properties
    
    @Bindable var viewModel: SettingsViewModel
    
    // MARK: Body
    
    var body: some View {
        NavigationStack {
            RoundedList {
                ForEach(viewModel.missedReflections) { missedReflection in
                    NavigationLink {
                        VStack(spacing: 32) {
                            Card {
                                VStack(spacing: 16) {
                                    HStack(spacing: 16) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            IconLabel(
                                                icon: missedReflection.measurementType.icon,
                                                title: missedReflection.measurementType.rawValue,
                                                labelColor: missedReflection.measurementType == .heartRate ? .pink : .teal
                                            )
                                            .font(.subheadline.weight(.semibold))
                                            
                                            Text(missedReflection.triggerSummary)
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer()
                                        
                                        Icon(
                                            name: "alarm",
                                            color: missedReflection.reminderType.color,
                                            background: true
                                        )
                                    }
                                    .foregroundStyle(Color.primary)
                                }
                            }
                            .padding()
                            
                            ReflectionChartView(
                                reflection: missedReflection,
                                stepData: viewModel.stepData,
                                heartRateData: viewModel.heartRateData
                            )
                            
                            IconLabelGroupBox(
                                label: IconLabel(
                                    icon: "ellipsis.curlybraces",
                                    title: "Raw Data",
                                    labelColor: Color.brandPrimary,
                                    background: true
                                ),
                                description:
                                    Text("Only data points in bold considered.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            ) {
                                ScrollView(showsIndicators: false) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        if missedReflection.measurementType == .steps {
                                            let stepPoints = stepPoints(for: missedReflection)
                                            if stepPoints.isEmpty {
                                                Text("No step data available")
                                                    .foregroundStyle(.secondary)
                                            } else {
                                                ForEach(stepPoints) { point in
                                                    let isWithinWindow = point.startDate >= windowStart(for: missedReflection) && point.startDate <= missedReflection.date
                                                    HStack {
                                                        Text(point.startDate.formatted(.dateTime.month().day().hour().minute().second()))
                                                            .foregroundStyle(isWithinWindow ? .primary : .secondary)
                                                            .fontWeight(isWithinWindow ? .bold : .regular)
                                                        Spacer()
                                                        Text("\(Int(point.stepCount)) steps")
                                                            .foregroundStyle(isWithinWindow ? .teal : .teal.opacity(0.5))
                                                            .fontWeight(isWithinWindow ? .bold : .regular)
                                                    }
                                                    
                                                    Divider()
                                                }
                                            }
                                        } else {
                                            let heartRatePoints = heartRatePoints(for: missedReflection)
                                            if heartRatePoints.isEmpty {
                                                Text("No heart rate data available")
                                                    .foregroundStyle(.secondary)
                                            } else {
                                                ForEach(heartRatePoints) { point in
                                                    let isWithinWindow = point.date >= windowStart(for: missedReflection) && point.date <= missedReflection.date
                                                    HStack {
                                                        Text(point.date.formatted(.dateTime.month().day().hour().minute().second()))
                                                            .foregroundStyle(isWithinWindow ? .primary : .secondary)
                                                            .fontWeight(isWithinWindow ? .bold : .regular)
                                                        Spacer()
                                                        Text("\(Int(point.heartRate)) bpm")
                                                            .foregroundStyle(isWithinWindow ? .pink : .pink.opacity(0.5))
                                                            .fontWeight(isWithinWindow ? .bold : .regular)
                                                    }
                                                    
                                                    Divider()
                                                }
                                            }
                                        }
                                    }
                                }
                                .navigationTitle(missedReflection.date.formatted(.dateTime.month().day().hour().minute()))
                            }
                            .iconLabelGroupBoxStyle(.divider)
                            .padding()
                        }
                    } label: {
                        HStack {
                            IconLabel(
                                icon: missedReflection.measurementType.icon,
                                title: missedReflection.date.formatted(.dateTime.day().month().year().day().minute().hour()),
                                description: missedReflection.triggerSummary,
                                labelColor: missedReflection.measurementType.color,
                                background: true
                            )
                            .font(.subheadline.weight(.semibold))
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Icon(name: "chevron.right", color: Color(.systemGray2))
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                    }
                }
            }
            .navigationTitle("All Missed Reflections")
        }
    }
    
    // MARK: - Chart Data Helpers (Copied from ReflectionChartView)
    
    private func windowStart(for reflection: MissedReflection) -> Date {
        if reflection.interval == .oneDay && reflection.measurementType == .steps {
            return viewModel.stepData.min(by: { $0.startDate < $1.startDate })?.startDate ?? reflection.date
        } else if reflection.interval == .immediately && reflection.measurementType == .heartRate {
            return reflection.date
        }
        return reflection.date.addingTimeInterval(-reflection.interval.timeInterval)
    }
    
    private func plotStart(for reflection: MissedReflection) -> Date {
        let baseStart = windowStart(for: reflection).addingTimeInterval(-reflection.interval.buffer(for: reflection.measurementType == .steps ? .steps : .heartRate))
        let extensionDuration = xAxisLabelFrequencyDuration(for: reflection)
        return baseStart.addingTimeInterval(-extensionDuration)
    }
    
    private func plotEnd(for reflection: MissedReflection) -> Date {
        let baseEnd = reflection.date.addingTimeInterval(reflection.interval.buffer(for: reflection.measurementType == .steps ? .steps : .heartRate))
        let extensionDuration = xAxisLabelFrequencyDuration(for: reflection)
        return baseEnd.addingTimeInterval(extensionDuration)
    }
    
    private func stepPoints(for reflection: MissedReflection) -> [StepDataPoint] {
        viewModel.stepData
            .filter { $0.startDate >= plotStart(for: reflection) && $0.startDate <= plotEnd(for: reflection) }
            .map { StepDataPoint(startDate: $0.startDate, endDate: $0.endDate, stepCount: $0.stepCount) }
    }
    
    private func heartRatePoints(for reflection: MissedReflection) -> [HeartRateDataPoint] {
        viewModel.heartRateData
            .filter { $0.startDate >= plotStart(for: reflection) && $0.startDate <= plotEnd(for: reflection) }
            .map { HeartRateDataPoint(date: $0.startDate, heartRate: $0.stepCount) }
    }
    
    private func xAxisStride(for reflection: MissedReflection) -> (unit: Calendar.Component, count: Int) {
        switch (reflection.measurementType, reflection.interval) {
        // Heart Rate Intervals
        case (.heartRate, .immediately):
            return (.minute, 1) // Labels every 1 minute
        case (.heartRate, .fiveMinutes):
            return (.minute, 1) // Labels every 1 minute
        case (.heartRate, .tenMinutes):
            return (.minute, 2) // Labels every 2 minutes
        case (.heartRate, .fifteenMinutes):
            return (.minute, 3) // Labels every 3 minutes
        case (.heartRate, .thirtyMinutes):
            return (.minute, 5) // Labels every 5 minutes
        case (.heartRate, .oneHour):
            return (.minute, 5) // Labels every 5 minutes
            
        // Steps Intervals
        case (.steps, .oneHour):
            return (.minute, 10) // Labels every 10 minutes
        case (.steps, .twoHours):
            return (.minute, 20) // Labels every 15 minutes
        case (.steps, .fourHours):
            return (.minute, 30) // Labels every 30 minutes
        case (.steps, .oneDay):
            return (.hour, 3) // Labels every 3 hours
            
        // Fallback for any other cases
        default:
            return (.minute, 15) // Default to 15 minutes
        }
    }
    
    private func xAxisLabelFrequencyDuration(for reflection: MissedReflection) -> TimeInterval {
        let (unit, count) = xAxisStride(for: reflection)
        switch unit {
        case .minute:
            return TimeInterval(count * 60) // Convert minutes to seconds
        case .hour:
            return TimeInterval(count * 3600) // Convert hours to seconds
        default:
            return TimeInterval(15 * 60) // Fallback to 15 minutes in seconds
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: SettingsViewModel = ScenesContainer.shared.settingsViewModel()
    
    MissedReflectionsListView(viewModel: viewModel)
}
