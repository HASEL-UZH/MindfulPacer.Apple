//
//  CreateReviewReminderView.swift
//  iOS
//
//  Created by Grigor Dochev on 15.08.2024.
//

import SwiftUI

// MARK: - Presentation Enums

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

enum CreateReviewReminderAlert: Identifiable {
    case deleteConfirmation
    case unableToSaveReviewReminder
    case unableToSendTestNotification
    
    var id: Int {
        hashValue
    }
}

// MARK: - CreateReviewReminderView

struct CreateReviewReminderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.keyboardShowing) private var keyboardShowing
    @State var viewModel: CreateReviewReminderViewModel = ScenesContainer.shared.createReviewReminderViewModel()
    
    var reviewReminder: ReviewReminder?

    // MARK: Body
    
    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                switch viewModel.mode {
                case .create:
                    intro
                case .edit:
                    SummaryView(viewModel: viewModel)
                }
            }
            .toolbar {
                if viewModel.mode == .edit {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            viewModel.saveReviewReminder(reviewReminder)
                            dismiss()
                        }
                        .fontWeight(.semibold)
                        .disabled(viewModel.isSaveButtonDisabled)
                    }
                }
            }
            .onViewFirstAppear {
                viewModel.configureMode(with: reviewReminder)
            }
            .alert(item: $viewModel.activeAlert) { alert in
                switch alert {
                case .deleteConfirmation:
                    reviewReminderDeletionConfirmationAlert
                case .unableToSaveReviewReminder:
                    unableToSaveReviewReminderAlert
                case .unableToSendTestNotification:
                    unableToSendTestNotificationAlert
                }
            }
            .sheet(item: $viewModel.activeSheet) { sheet in
                switch sheet {
                case .alarmTypeInfo:
                    alarmTypeInfoSheet
                case .heartRateThresholdInfo:
                    thresholdInfoSheet
                case .intervalInfo:
                    intervalInfoSheet
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
            if viewModel.mode == .create {
                if viewModel.showActionButton {
                    actionButton
                }
            }
        }
    }
    
    // MARK: Action Button
    
    private var actionButton: some View {
        PrimaryButton(title: viewModel.actionButtonTitle) {
            viewModel.actionButtonTapped()
        }
        .padding(keyboardShowing ? [.all] : [.horizontal, .top])
        .disabled(viewModel.isActionButtonDisabled)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
    }
    
    // MARK: Intro
    
    private var intro: some View {
        VStack {
            Button("Cancel") {
                dismiss()
            }
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
    
    // MARK: Alarm Type Info Sheet
    
    private var alarmTypeInfoSheet: some View {
        InfoSheet(
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
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(16)
    }
    
    // MARK: Threshold Info Sheet
    
    private var thresholdInfoSheet: some View {
        InfoSheet(
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
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(16)
    }
    
    // MARK: Interval Info Sheet
    
    private var intervalInfoSheet: some View {
        InfoSheet(
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
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(16)
    }
    
    // MARK: Unable to Save Review Reminder Alert
    
    private var unableToSaveReviewReminderAlert: Alert {
        Alert(
            title: Text("Error Saving Review Reminder"),
            message: Text("Unable to save your Review Reminder.\nPlease try again.\nIf this problem persists, please contact us."),
            dismissButton: .default(Text("Ok"))
        )
    }
    
    // MARK: Unable to Send Test Notification Alert
    
    private var unableToSendTestNotificationAlert: Alert {
        Alert(
            title: Text("Unable to Send Notification"),
            message: Text("Please make sure that you are wearing your Apple Watch and you have the MindfulPacer Watch app open, then try again."),
            dismissButton: .default(Text("Ok"))
        )
    }
    
    // MARK: Review Deletion Confirmation Alert
    
    private var reviewReminderDeletionConfirmationAlert: Alert {
        Alert(
            title: Text("Delete Review Reminder"),
            message: Text("Are you sure you want to delete this review reminder? This action cannot be undone."),
            primaryButton: .destructive(Text("Delete")) {
                viewModel.deleteReviewReminder(reviewReminder)
                dismiss()
            },
            secondaryButton: .cancel()
        )
    }
}

// MARK: - Preview

#Preview {
    CreateReviewReminderView()
        .tint(Color("BrandPrimary"))
}
