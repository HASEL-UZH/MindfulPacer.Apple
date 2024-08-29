//
//  SummaryView.swift
//  iOS
//
//  Created by Grigor Dochev on 18.08.2024.
//

import SwiftUI
import SwiftData

// MARK: - Create Review Reminder Summary View

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
                        //                        vibrationStrength
                        interval
                        notificationPreview
                            .padding(.bottom, 64)
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
}

// MARK: - Measurement Type

extension CreateReviewReminderView.SummaryView {
    private var measurementType: some View {
        widgetView(
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
}

// MARK: - Alarm Type

extension CreateReviewReminderView.SummaryView {
    private var alarmType: some View {
        widgetView(
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
}

// MARK: - Threshold

extension CreateReviewReminderView.SummaryView {
    private var threshold: some View {
        widgetView(
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
}

// MARK: - Vibration Strength

//extension CreateReviewReminderView.SummaryView {
//    private var vibrationStrength: some View {
//        widgetView(
//            icon: "hammer",
//            title: "Vibration Strength",
//            destination: .vibrationStrength) {
//                if let vibrationStrength = viewModel.selectedVibrationStrength {
//                    Text(vibrationStrength.rawValue)
//                } else {
//                    Text("No Vibration Strength Selected")
//                        .foregroundStyle(.red)
//                }
//            }
//    }
//}

// MARK: - Interval

extension CreateReviewReminderView.SummaryView {
    private var interval: some View {
        widgetView(
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
}

// MARK: - Notification Preview

extension CreateReviewReminderView.SummaryView {
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
                
//                notificationPreviewButton
            }
        } footer: {
            notificationPreviewButton
        }
        .iconLabelGroupBoxStyle(.divider)
    }
    
    private var notificationPreviewButton: some View {
        Button {
            viewModel.sendNotificationToWatch()
        } label: {
            IconLabel(
                icon: "bell.badge",
                title: "Test on Apple Watch",
                labelColor: Color("BrandPrimary")
            )
            .font(.subheadline.weight(.semibold))
        }
        .disabled(viewModel.isContinueButtonDisabled)
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
