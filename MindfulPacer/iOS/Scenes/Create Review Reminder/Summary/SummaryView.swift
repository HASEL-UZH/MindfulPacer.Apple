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
        
        var body: some View {
            ZStack(alignment: .top) {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        measurementType
                        alarmType
                        threshold
                        vibrationStrength
                        interval
                        notificationPreview
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Summary")
        }
    }
}

// MARK: - Widget View

extension CreateReviewReminderView.SummaryView {
    @ViewBuilder private func widgetView<Content: View>(
        title: String,
        destination: CreateReviewReminderNavigationDestination,
        @ViewBuilder label: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .foregroundStyle(.secondary)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button {
                    viewModel.navigationPath.append(destination)
                } label: {
                    Image(systemName: "pencil.circle.fill")
                }
            }
            
            label()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .foregroundStyle(Color(.secondarySystemGroupedBackground))
        }
    }
}

// MARK: - Measurement Type

extension CreateReviewReminderView.SummaryView {
    private var measurementType: some View {
        widgetView(
            title: "Measurement Type",
            destination: .measurementType) {
                if let selectedMeasurementType = viewModel.selectedMeasurementType {
                    SFSymbolLabel(icon: selectedMeasurementType.icon, title: selectedMeasurementType.rawValue)
                } else {
                    Text("No Measurement Type Selected")
                }
            }
    }
}

// MARK: - Alarm Type

extension CreateReviewReminderView.SummaryView {
    private var alarmType: some View {
        widgetView(
            title: "Alarm Type",
            destination: .alarmType) {
                if let selectedAlarmType = viewModel.selectedAlarmType {
                    SFSymbolLabel(icon: selectedAlarmType.icon, title: selectedAlarmType.rawValue)
                } else {
                    Text("No Alarm Type Selected")
                }
            }
    }
}

// MARK: - Threshold

extension CreateReviewReminderView.SummaryView {
    private var threshold: some View {
        widgetView(
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
                }
            }
    }
}

// MARK: - Vibration Strength

extension CreateReviewReminderView.SummaryView {
    private var vibrationStrength: some View {
        widgetView(
            title: "Vibration Strength",
            destination: .vibrationStrength) {
                if let selectedVibrationStrength = viewModel.selectedVibrationStrength {
                    Text(selectedVibrationStrength.rawValue)
                } else {
                    Text("No Vibration Strength Selected")
                }
            }
    }
}

// MARK: - Interval

extension CreateReviewReminderView.SummaryView {
    private var interval: some View {
        widgetView(
            title: "Interval",
            destination: .interval) {
                if let selectedInterval = viewModel.selectedInterval {
                    SFSymbolLabel(icon: selectedInterval.icon, title: selectedInterval.rawValue)
                } else {
                    Text("No Interval Selected")
                }
            }
    }
}

// MARK: - Notification Preview

extension CreateReviewReminderView.SummaryView {
    private var notificationPreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            SFSymbolLabel(icon: "app.badge.fill", title: "Notification Preview")
                .foregroundStyle(Color("BrandPrimary"))
            Divider()
            HStack(spacing: 8) {
                Image("MindfulPacer Icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Review Reminder")
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("now")
                            .font(.footnote)
                            .foregroundStyle(.primary.opacity(0.4))
                    }
                    Text(viewModel.notificationPreviewBodyText)
                        .font(.subheadline)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .foregroundStyle(.ultraThinMaterial)
            }
            
            Button {
                viewModel.sendNotificationToWatch()
            } label: {
                Text("Send Test Notification")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .foregroundStyle(Color(.secondarySystemGroupedBackground))
        }
        .padding(.bottom, 64)
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
