//
//  MissedReflectionsView.swift
//  iOS
//
//  Created by Grigor Dochev on 30.12.2024.
//

import SwiftUI
import Charts
import CardStack

// MARK: - MissedReflectionsView

struct MissedReflectionsView: View {
    
    // MARK: Properties
    
    @Bindable var viewModel: HomeViewModel
    
    // MARK: Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                CardStack(viewModel.missedReflections) { missedReflection in
                    missedReflectionCard(missedReflection)
                }
                .padding(.horizontal)
                
                IconLabel(
                    icon: "arrow.left.and.line.vertical.and.arrow.right",
                    title: "Swipe the cards to view more missed reflections",
                    labelColor: .secondary
                )
                .font(.footnote)
            }
            .navigationTitle("Missed Reflections")
            .frame(maxHeight: .infinity, alignment: .top)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CloseButton()
                }
            }
        }
    }
    
    // MARK: - Missed Reflection Card
    
    // swiftlint:disable:next function_body_length
    @ViewBuilder func missedReflectionCard(_ missedReflection: MissedReflection) -> some View {
        VStack {
            VStack(spacing: 32) {
                Card(backgroundColor: Color(.tertiarySystemGroupedBackground)) {
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
                        
                        Divider()
                        
                        IconLabel(title: String(localized: "Triggered on \(missedReflection.date.formatted(.dateTime.month().day().hour().minute()))"))
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                
                Spacer()
                
                ReflectionChartView(
                    reflection: missedReflection,
                    stepData: viewModel.stepData,
                    heartRateData: viewModel.heartRateData
                )
                
                Spacer()
                
                actionButtons(for: missedReflection)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .foregroundStyle(Color(.secondarySystemGroupedBackground))
                
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            }
        )
        .padding()
        .padding(.bottom, 32)
    }
    
    // MARK: Action Buttons
    
    @ViewBuilder
    private func actionButtons(for missedReflection: MissedReflection) -> some View {
        HStack(spacing: 0) {
            Button {
                viewModel.rejectMissedReflection(missedReflection)
            } label: {
                ZStack {
                    UnevenRoundedRectangle(cornerRadii: .init(topLeading: 16, bottomLeading: 16))
                        .foregroundStyle(.red.opacity(0.7))
                    
                    IconLabel(icon: "xmark", title: String(localized: "Reject"))
                        .font(.body.weight(.semibold))
                    
                    UnevenRoundedRectangle(cornerRadii: .init(topLeading: 16, bottomLeading: 16))
                        .stroke(Color.secondary, lineWidth: 1)
                }
            }
            
            Button {
                viewModel.acceptMissedReflection(missedReflection)
            } label: {
                ZStack {
                    UnevenRoundedRectangle(cornerRadii: .init(bottomTrailing: 16, topTrailing: 16))
                        .foregroundStyle(.green.opacity(0.7))
                    
                    IconLabel(icon: "checkmark", title: String(localized: "Accept"))
                        .font(.body.weight(.semibold))
                    
                    UnevenRoundedRectangle(cornerRadii: .init(bottomTrailing: 16, topTrailing: 16))
                        .stroke(Color.secondary, lineWidth: 1)
                }
            }
        }
        .frame(height: 52)
    }
    
    // MARK: - Chart Data Helpers (Copied from ReflectionChartView)
    
    private func windowStart(for reflection: MissedReflection) -> Date {
        if reflection.interval == .oneDay && reflection.measurementType == .steps {
            return viewModel.stepData.min(by: { $0.startDate < $1.startDate })?.startDate ?? reflection.date
        } else if reflection.interval == .immediately && reflection.measurementType == .heartRate {
            return reflection.date
        }
        return reflection.date.addingTimeInterval(-Interval.timeInterval(reflection.interval))
    }
    
    private func plotStart(for reflection: MissedReflection) -> Date {
        let baseStart = windowStart(for: reflection).addingTimeInterval(-Interval.buffer(reflection.interval))
        let extensionDuration = xAxisLabelFrequencyDuration(for: reflection)
        return baseStart.addingTimeInterval(-extensionDuration)
    }
    
    private func plotEnd(for reflection: MissedReflection) -> Date {
        let baseEnd = reflection.date.addingTimeInterval(Interval.buffer(reflection.interval))
        let extensionDuration = xAxisLabelFrequencyDuration(for: reflection)
        return baseEnd.addingTimeInterval(extensionDuration)
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
    let viewModel = ScenesContainer.shared.homeViewModel()
    
    MissedReflectionsView(viewModel: viewModel)
}
