//
//  SummaryView.swift
//  iOS
//
//  Created by Grigor Dochev on 18.08.2024.
//

import SwiftUI
import SwiftData

// MARK: - SummaryView

extension CreateReviewReminderView {
    struct SummaryView: View {
        @Bindable var viewModel: CreateReviewReminderViewModel
        
        // MARK: Body
        
        var body: some View {
            GeometryReader { proxy in
                ZStack(alignment: .top) {
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            measurementType
                            alarmType
                            threshold
                            interval
                            notificationPreview
                        }
                        .padding(.horizontal)
                        .padding(.bottom, proxy.safeAreaInsets.bottom + 48)
                    }
                }
                .navigationTitle("Summary")
            }
        }
        
        // MARK: Summary Widget
        
        @ViewBuilder private func summaryWidget<Content: View>(
            icon: String,
            title: String,
            destination: CreateReviewReminderNavigationDestination,
            @ViewBuilder label: @escaping () -> Content
        ) -> some View {
            IconLabelGroupBox(
                label: IconLabel(
                    icon: icon,
                    title: title,
                    labelColor: Color("BrandPrimary"),
                    background: true
                )
            ) {
                label()
            } accessoryIndicator: {
                Button {
                    viewModel.navigationPath.append(destination)
                } label: {
                    Icon(name: "pencil.circle", variant: .fill)
                }
            }
        }
        
        // MARK: Measurement Type
        
        private var measurementType: some View {
            summaryWidget(
                icon: "ruler",
                title: "Measurement Type",
                destination: .measurementType) {
                    if let measurementType = viewModel.selectedMeasurementType {
                        Text(measurementType.rawValue)
                    } else {
                        Text("No Measurement Type Selected")
                            .foregroundStyle(.red)
                    }
                }
        }
        
        // MARK: Alarm Type
        
        private var alarmType: some View {
            summaryWidget(
                icon: "alarm",
                title: "Alarm Type",
                destination: .alarmType) {
                    if let alarmType = viewModel.selectedAlarmType {
                        Text(alarmType.rawValue)
                    } else {
                        Text("No Alarm Type Selected")
                            .foregroundStyle(.red)
                    }
                }
        }
        
        // MARK: Threshold
        
        private var threshold: some View {
            summaryWidget(
                icon: "chart.line.flattrend.xyaxis",
                title: "Threshold",
                destination: .threshold) {
                    if let threshold = viewModel.threshold {
                        HStack(alignment: .bottom, spacing: 4) {
                            Text("\(threshold)")
                            Text(viewModel.thresholdUnitText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("No Threshold Set")
                            .foregroundStyle(.red)
                    }
                }
        }
        
        // MARK: Interval
        
        private var interval: some View {
            summaryWidget(
                icon: "timer",
                title: "Interval",
                destination: .interval) {
                    if let interval = viewModel.selectedInterval {
                        Text(interval.rawValue)
                    } else {
                        Text("No Interval Selected")
                            .foregroundStyle(.red)
                    }
                }
        }
        
        // MARK: Notification Preview
        
        private var notificationPreview: some View {
            IconLabelGroupBox(
                label: IconLabel(
                    icon: "eye",
                    title: "Preview Notification",
                    labelColor: Color("BrandPrimary"),
                    background: true
                ),
                description:
                    Text("See how the notification will look.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            ) {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        Image("MindfulPacer Icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Review Reminder Triggered")
                                .font(.subheadline.weight(.semibold))
                            
                            Text(viewModel.notificationPreviewBodyText)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundStyle(.thinMaterial)
                    }
                }
            } footer: {
                notificationPreviewButton
            }
            .iconLabelGroupBoxStyle(.divider)
        }
        
        // MARK: Notification Preview Button
        
        private var notificationPreviewButton: some View {
            Button {
                viewModel.sendNotificationToWatch()
            } label: {
                IconLabel(
                    icon: "bell.badge",
                    title: "Test on Apple Watch",
                    labelColor: viewModel.isActionButtonDisabled ? Color.secondary : Color("BrandPrimary")
                )
                .font(.subheadline.weight(.semibold))
            }
            .disabled(viewModel.isActionButtonDisabled)
        }
    }
}

// MARK: - Preview

#Preview {
    let container = ModelContainer.preview
    let viewModel = ScenesContainer.shared.createReviewReminderViewModel()
    
    NavigationStack {
        CreateReviewReminderView.SummaryView(viewModel: viewModel)
    }
    .tint(Color("BrandPrimary"))
}
