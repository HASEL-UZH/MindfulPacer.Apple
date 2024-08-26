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
//                        alarmType
                        threshold
//                        vibrationStrength
                        interval
                        notificationPreviewButton
                            .padding(.top)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Summary")
        }
        
        private var notificationPreviewButton: some View {
            Button {
                viewModel.sendNotificationToWatch()
            } label: {
                SFSymbolLabel(
                    icon: "bell.badge",
                    title: "Test Notification on Apple Watch",
                    iconColor: viewModel.isContinueButtonDisabled ? Color.primary : Color("BrandPrimary"),
                    symbolRenderingMode: .hierarchical
                )
                .fontWeight(.semibold)
            }
            .buttonBorderShape(.capsule)
            .buttonStyle(.bordered)
            .disabled(viewModel.isContinueButtonDisabled)
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
        SFSymbolGroupBox(
            label: SFSymbolLabel(icon: icon, title: title)
        ) {
            label()
        } button: {
            Button {
                viewModel.navigationPath.append(destination)
            } label: {
                Image(systemName: "pencil.circle.fill")
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

//extension CreateReviewReminderView.SummaryView {
//    private var alarmType: some View {
//        widgetView(
//            icon: "alarm",
//            title: "Alarm Type",
//            destination: .alarmType) {
//                if let alarmType = viewModel.selectedAlarmType {
//                    Text(alarmType.rawValue)
//                } else {
//                    Text("No Alarm Type Selected")
//                        .foregroundStyle(.red)
//                }
//            }
//    }
//}

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

// MARK: - Preview

#Preview {
    let container = ModelContainer.preview
    let viewModel = ScenesContainer.shared.createReviewReminderViewModel()
    
    NavigationStack {
        CreateReviewReminderView.SummaryView(viewModel: viewModel)
    }
    .tint(Color("BrandPrimary"))
}
