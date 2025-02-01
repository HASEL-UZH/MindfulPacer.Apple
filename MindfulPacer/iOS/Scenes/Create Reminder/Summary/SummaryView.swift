//
//  SummaryView.swift
//  iOS
//
//  Created by Grigor Dochev on 18.08.2024.
//

import SwiftUI

// MARK: - SummaryView

extension CreateReminderView {
    struct SummaryView: View {
        
        // MARK: Properties
        
        @Bindable var viewModel: CreateReminderViewModel
        
        // MARK: Body
        
        var body: some View {
            GeometryReader { proxy in
                ZStack(alignment: .top) {
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            measurementType
                            reminderType
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
                .toolbar {
                    if viewModel.mode == .create {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Cancel") {
                                viewModel.dismissView()
                            }
                        }
                    }
                }
            }
        }
        
        // MARK: Summary Widget
        
        @ViewBuilder
        private func summaryWidget<Content: View>(
            icon: String,
            title: String,
            destination: CreateReminderNavigationDestination?,
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
                if let destination {
                    Button {
                        viewModel.navigationPath.append(destination)
                    } label: {
                        Icon(name: "pencil.circle", variant: .fill)
                    }
                }
            }
        }
        
        // MARK: Measurement Type
        
        private var measurementType: some View {
            summaryWidget(
                icon: "ruler",
                title: "Measurement Type",
                destination: viewModel.mode == .create ? .measurementType : nil
            ) {
                if let measurementType = viewModel.selectedMeasurementType {
                    Text(measurementType.rawValue)
                } else {
                    Text("No Measurement Type Selected")
                        .foregroundStyle(.red)
                }
            }
        }
        
        // MARK: Reflection Reminder Type
        
        private var reminderType: some View {
            summaryWidget(
                icon: "alarm",
                title: "Reflection Reminder Type",
                destination: .reminderType
            ) {
                if let reminderType = viewModel.selectedReminderType {
                    Text(reminderType.rawValue)
                } else {
                    Text("No Reflection Reminder Type Selected")
                        .foregroundStyle(.red)
                }
            }
        }
        
        // MARK: Threshold
        
        private var threshold: some View {
            summaryWidget(
                icon: "chart.line.flattrend.xyaxis",
                title: "Threshold",
                destination: .threshold
            ) {
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
                destination: .interval
            ) {
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
                            Text("Reflection Reminder Triggered")
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
        
        // MARK: Delete Button
        
        private var deleteButton: some View {
            PrimaryButton(
                title: "Delete Reflection Reminder",
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
    let viewModel = ScenesContainer.shared.createReminderViewModel()
    
    NavigationStack {
        CreateReminderView.SummaryView(viewModel: viewModel)
    }
    .tint(Color("BrandPrimary"))
}
