//
//  SummaryView.swift
//  iOS
//
//  Created by Grigor Dochev on 18.08.2024.
//

import SwiftUI

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
                            reviewReminderType
                            threshold
                            interval
                            notificationPreview
                            
                            if viewModel.mode == .edit {
                                deleteButton
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, viewModel.mode == .create ? proxy.safeAreaInsets.bottom + 48 : 0)
                    }
                }
                .navigationTitle(viewModel.summaryViewTitle)
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
        
        // MARK: Review Reminder Type
        
        private var reviewReminderType: some View {
            summaryWidget(
                icon: "alarm",
                title: "Review Reminder Type",
                destination: .reviewReminderType) {
                    if let reviewReminderType = viewModel.selectedReviewReminderType {
                        Text(reviewReminderType.rawValue)
                    } else {
                        Text("No Review Reminder Type Selected")
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
        
        // MARK: - Delete Button
        
        private var deleteButton: some View {
            PrimaryButton(
                title: "Delete Review Reminder",
                icon: "trash",
                color: .red
            ) {
                viewModel.presentAlert(.deleteConfirmation)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.createReviewReminderViewModel()
    
    NavigationStack {
        CreateReviewReminderView.SummaryView(viewModel: viewModel)
    }
    .tint(Color("BrandPrimary"))
}
