//
//  CreateReviewReminderView.swift
//  iOS
//
//  Created by Grigor Dochev on 15.08.2024.
//

import SwiftUI

// MARK: - Navigation Enums

enum CreateReviewReminderNavigationDestination: Hashable {
    case measurementType
    case alarmType
    case threshold
    case interval
    case summary
}

enum CreateReviewReminderSheet: Identifiable {
    case alarmTypeInfo
    case heartRateThresholdInfo
    case intervalInfo
    
    var id: Int {
        hashValue
    }
}

// MARK: - CreateReviewReminderView

struct CreateReviewReminderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.keyboardShowing) private var keyboardShowing
    @State var viewModel: CreateReviewReminderViewModel = ScenesContainer.shared.createReviewReminderViewModel()
    
    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                intro
            }
            .alert(item: $viewModel.alertItem) { $0.alert }
            .sheet(item: $viewModel.activeSheet) { sheet in
                switch sheet {
                case .alarmTypeInfo:
                    alarmTypeInfoView
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                        .presentationCornerRadius(16)
                case .heartRateThresholdInfo:
                    thresholdInfoView
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                        .presentationCornerRadius(16)
                case .intervalInfo:
                    intervalInfoView
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                        .presentationCornerRadius(16)
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: CreateReviewReminderNavigationDestination.self) { destination in
                switch destination {
                case .measurementType:
                    MeasurementTypeView(viewModel: viewModel)
                case .alarmType:
                    AlarmTypeView(viewModel: viewModel)
                case .threshold:
                    ThresholdView(viewModel: viewModel)
                case .interval:
                    IntervalView(viewModel: viewModel)
                case .summary:
                    SummaryView(viewModel: viewModel)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if viewModel.showContinueButton {
                continueButton
            }
        }
    }
    
    private var continueButton: some View {
        PrimaryButton(title: viewModel.continueButtonTitle) {
            viewModel.continueButtonTapped()
        }
        .padding(keyboardShowing ? [.all] : [.horizontal, .top])
        .disabled(viewModel.isContinueButtonDisabled)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
    }
    
    private var intro: some View {
        VStack {
            Button("Cancel") {
                dismiss()
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 32) {
                Text("Create Review Reminder")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top)
                
                // TODO: Change to literal using . notation
                Image("Create Review Reminder")
                    .resizable()
                    .scaledToFit()
                
                Text("This allows you to add a new Review Reminder which can be triggered on your Apple Watch or iPhone.")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var alarmTypeInfoView: some View {
        InfoSheetView(
            title: "Alarm Type Information",
            info: "You can choose between three different alarm types.") {
                Text(
                    """
                    1. **Light**: shows a yellow color 🟡.
                    2. **Medium**: shows an orange color 🟠.
                    3. **Strong**: shows a red color 🔴.
                    """
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.subheadline)
            }
    }
    
    private var thresholdInfoView: some View {
        InfoSheetView(
            title: "Threshold Information",
            info: "Set a threshold that triggers a reminder when reached for a specified interval."
        ) {
            VStack(spacing: 16) {
                IconLabelGroupBox(
                    label: IconLabel(icon: "figure.walk", title: "Steps", labelColor: .teal)
                ) {
                    Text("The current step count, as detected by the Apple Watch, must stay at or above the threshold for a Review Reminder to be triggered.\n\n For example: Completing more than 2000 steps in 30 minutes.\n\nPlease note that you can set the interval on the next page.")

                }
                            
                IconLabelGroupBox(
                    label: IconLabel(icon: "heart", title: "Heart Rate", labelColor: .pink)
                ) {
                    Text("The current heart rate (in beats per minute, BPM), as detected by the Apple Watch, must stay at or above the threshold for a Review Reminder to be triggered.\n\nPlease note that such thresholds for pacing and managing your activity are highly individual. We recommend to experiment with different (and several) thresholds to identify what works best for you. One starting point could be (220 - AgeInYears) * 0.5. For example, a 40-year old person would set a threshold as (220-40)*0.5=90 beats per minute.\n\nFor example: Do a quick review when completing 2000 or more steps within 30 minutes.\n\nPlease note that you can set the interval on the next page.")
                }
            }
            .font(.subheadline)
        }
    }
    
    private var intervalInfoView: some View {
        InfoSheetView(
            title: "Interval Information",
            info: "Duration during which the heart rate has to be greater than or equal to the threshold (threshold selected on previous page) in order for the Review Reminder to be triggered."
        ) {
            VStack(spacing: 16) {
                IconLabelGroupBox(
                    label: IconLabel(icon: "figure.walk", title: "Steps", labelColor: .teal)
                ) {
                    Text("The period during which the heart rate, as measured by the Apple Watch, must stay at or above the specified threshold for the Review Reminder to be triggered.\n\nFor example: Do a quick review when the detected heart rate is greater than 120 for 30 seconds or longer.")
                }
                
                IconLabelGroupBox(
                    label: IconLabel(icon: "heart", title: "Heart Rate", labelColor: .pink)
                ) {
                    Text("The period during which the total number of steps, as measured by the Apple Watch, must stay at or above the threshold for the Review Reminder to be triggered.\n\nFor example: Do a quick review when completing 2000 or more steps within 30 minutes.")
                }
            }
            .font(.subheadline)
        }
    }
}

// MARK: - Preview

#Preview {
    CreateReviewReminderView()
        .tint(Color("BrandPrimary"))
}
