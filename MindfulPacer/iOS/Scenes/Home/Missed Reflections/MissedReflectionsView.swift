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
    @AppStorage(ModeOfUse.appStorageKey) private var modeOfUse: ModeOfUse = .essentials
    @State private var selectedMissedReflection: MissedReflection?
    
    // MARK: Body
    
    var body: some View {
        NavigationStack {
            if viewModel.missedReflections.isEmpty {
                emptyState
                    .navigationTitle("Missed Reflections")
            } else {
                cardStack
            }
        }
    }
    
    // MARK: Card Stack
    
    private var cardStack: some View {
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
        .sheet(item: $selectedMissedReflection) { missedReflection in
            NavigationStack {
                VStack(spacing: 32) {
                    ReflectionChartView(
                        reflection: missedReflection,
                        stepData: viewModel.stepData,
                        heartRateData: viewModel.heartRateData
                    )
                    
                    rawData(for: missedReflection)
                        .navigationTitle("Raw Data")
                        .background(
                            Color(.systemGroupedBackground)
                                .ignoresSafeArea()
                        )
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                CloseButton()
                            }
                        }
                }
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
            }
            .presentationCornerRadius(16)
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: Empty State
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Missed Reflections", systemImage: "square.stack.fill")
        } description: {
            Text("You do not have any missed reflection.")
        }
    }
    
    // MARK: Missed Reflection Card
    
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
                                    .lineLimit(2)
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
                                                
                        if modeOfUse == .expanded {
                            Divider()

                            Button {
                                selectedMissedReflection = missedReflection
                            } label: {
                                Label("View Raw Data", systemImage: "ellipsis.curlybraces")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
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
    
    // MARK: Raw Data
    
    @ViewBuilder
    private func rawData(for missedReflection: MissedReflection) -> some View {
        RoundedList {
            if missedReflection.measurementType == .steps {
                let stepPoints = stepPoints(for: missedReflection)
                if stepPoints.isEmpty {
                    Text("No step data available")
                        .foregroundStyle(.secondary)
                } else {
                    Section {
                        ForEach(stepPoints) { point in
                            let isWithinWindow = point.startDate >= windowStart(for: missedReflection) && point.startDate <= missedReflection.date
                            
                            RoundedListCell(
                                label: IconLabel(
                                    icon: "figure.walk",
                                    title: "\(Int(point.stepCount)) steps",
                                    description: point.startDate.formatted(.dateTime.month().day().hour().minute().second()) + " - " + point.endDate.formatted(.dateTime.month().day().hour().minute().second()),
                                    labelColor: isWithinWindow ? Color.teal : Color.secondary,
                                    background: true
                                )
                            )
                        }
                    } header: {
                        Text("**NOTE:** Only highlighted points are considered for the missed reflection.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                let heartRatePoints = heartRatePoints(for: missedReflection)
                if heartRatePoints.isEmpty {
                    Text("No heart rate data available")
                        .foregroundStyle(.secondary)
                } else {
                    Section {
                        ForEach(heartRatePoints) { point in
                            let isWithinWindow = point.date >= windowStart(for: missedReflection) && point.date <= missedReflection.date
                            
                            RoundedListCell(
                                label: IconLabel(
                                    icon: "heart",
                                    title: "\(Int(point.heartRate)) bpm",
                                    description: point.date.formatted(.dateTime.month().day().hour().minute().second()),
                                    labelColor: isWithinWindow ? Color.pink : Color.secondary,
                                    background: true
                                )
                            )
                        }
                    } header: {
                        Text("**NOTE:** Only highlighted points are considered for the missed reflection.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
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
                        .foregroundStyle(.red.opacity(0.1))
                    
                    IconLabel(icon: "xmark", title: String(localized: "Reject"), labelColor: .red)
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
                        .foregroundStyle(.green.opacity(0.1))
                    
                    IconLabel(icon: "checkmark", title: String(localized: "Accept"), labelColor: .green)
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
            let now = Date()
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = 0
            components.minute = 0
            components.second = 0
            components.timeZone = TimeZone.current
            
            return calendar.date(from: components) ?? reflection.date
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
    
    private func plotEnd(for reflection: MissedReflection) -> Date {
        let baseEnd = reflection.date.addingTimeInterval(reflection.interval.buffer(for: reflection.measurementType == .steps ? .steps : .heartRate))
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
