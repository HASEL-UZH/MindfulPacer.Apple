//
//  CreateReminderView.swift
//  iOS
//
//  Created by Grigor Dochev on 15.08.2024.
//

import SwiftUI

// MARK: - Presentation Enums

enum CreateReminderNavigationDestination: Hashable {
    case measurementType
    case reminderType
    case threshold
    case interval
    case summary
}

enum CreateReminderSheet: Identifiable {
    case reminderTypeInfo
    case heartRateThresholdInfo
    case intervalInfo

    var id: Int {
        hashValue
    }
}

enum CreateReminderAlert: Identifiable {
    case deleteConfirmation
    case unableToSaveReminder
    case unableToSendTestNotification

    var id: Int {
        hashValue
    }
}

// MARK: - CreateReminderView

struct CreateReminderView: View {
    
    // MARK: Properties

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CreateReminderViewModel = ScenesContainer.shared.createReminderViewModel()
    @State private var isKeyboardShowing = false
    
    var reminder: Reminder?

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
                editModeToolbar
            }
            .onViewFirstAppear {
                viewModel.configureMode(with: reminder)
            }
            .navigationBarTitleDisplayMode(.large)
            .alert(item: $viewModel.activeAlert) { alert in
                alertContent(for: alert)
            }
            .sheet(item: $viewModel.activeSheet) { sheet in
                sheetContent(for: sheet)
            }
            .navigationDestination(for: CreateReminderNavigationDestination.self) { destination in
                navigationDestination(for: destination)
            }
            .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
                if shouldDismiss {
                    dismiss()
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

    // MARK: Alerts

    private func alertContent(for alert: CreateReminderAlert) -> Alert {
        switch alert {
        case .deleteConfirmation:
            return reminderDeletionConfirmationAlert
        case .unableToSaveReminder:
            return unableToSaveReminderAlert
        case .unableToSendTestNotification:
            return unableToSendTestNotificationAlert
        }
    }

    // MARK: Sheets

    @ViewBuilder
    private func sheetContent(for sheet: CreateReminderSheet) -> some View {
        switch sheet {
        case .reminderTypeInfo:
            reminderTypeInfoSheet
        case .heartRateThresholdInfo:
            thresholdInfoSheet
        case .intervalInfo:
            intervalInfoSheet
        }
    }

    // MARK: Navigation Destination

    @ViewBuilder
    private func navigationDestination(for destination: CreateReminderNavigationDestination) -> some View {
        switch destination {
        case .measurementType:
            MeasurementTypeView(viewModel: viewModel)
        case .reminderType:
            ReminderTypeView(viewModel: viewModel)
        case .threshold:
            ThresholdView(viewModel: viewModel) { isFocused in
                isKeyboardShowing = isFocused
            }
        case .interval:
            IntervalView(viewModel: viewModel)
        case .summary:
            SummaryView(viewModel: viewModel)
        }
    }

    // MARK: Edit Mode Toolbar

    private var editModeToolbar: some ToolbarContent {
        Group {
            if viewModel.mode == .edit {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        viewModel.saveReminder(reminder)
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.isSaveButtonDisabled)
                }
            }
        }
    }

    // MARK: Action Button

    private var actionButton: some View {
        PrimaryButton(title: viewModel.actionButtonTitle) {
            viewModel.actionButtonTapped()
        }
        .padding(isKeyboardShowing ? .all : [.horizontal, .top])
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
            .frame(maxWidth: .infinity, alignment: .trailing)

            VStack(spacing: 32) {
                Text("Create Reminder")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top)

                Image("Create Reminder")
                    .resizable()
                    .scaledToFit()

                Text("This allows you to add a new Reminder which can be triggered on your Apple Watch or iPhone.")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: Reminder Type Info Sheet

    private var reminderTypeInfoSheet: some View {
        InfoSheet(
            title: String(localized: "Reminder Type Information"),
            info: String(localized: "You can choose between three different Reminder types.")
        ) {
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

    // swiftlint:disable trailing_whitespace
    private var thresholdInfoSheet: some View {
        InfoSheet(
            title: String(localized: "Threshold Information"),
            info: String(localized: "Set a threshold that triggers a reminder when reached for a specified interval.")
        ) {
            VStack(spacing: 16) {
                IconLabelGroupBox(
                    label: IconLabel(icon: "figure.walk", title: "Steps", labelColor: .teal)
                ) {
                    Text(
                        """
                        The current step count, as detected by the Apple Watch, must stay at or above the threshold for a Reminder to be triggered.
                        
                        For example: Completing more than 2000 steps in 30 minutes.\n\nPlease note that you can set the interval on the next page.
                        """
                    )
                    
                }

                IconLabelGroupBox(
                    label: IconLabel(icon: "heart", title: "Heart Rate", labelColor: .pink)
                ) {
                    Text(
                        """
                        The current heart rate (in beats per minute, BPM), as detected by the Apple Watch, must stay at or above the threshold for a Reminder to be triggered.
                        
                        Please note that such thresholds for pacing and managing your activity are highly individual. We recommend to experiment with different (and several) thresholds to identify what works best for you. One starting point could be (220 - AgeInYears) * 0.5. For example, a 40-year old person would set a threshold as (220-40)*0.5=90 beats per minute.
                        
                        For example: Do a quick reflection when completing 2000 or more steps within 30 minutes.\n\nPlease note that you can set the interval on the next page.
                        """
                    )
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
            title: String(localized: "Interval Information"),
            info: String(localized: "Duration during which the heart rate has to be greater than or equal to the threshold (threshold selected on previous page) in order for the Reminder to be triggered.")
        ) {
            VStack(spacing: 16) {
                IconLabelGroupBox(
                    label: IconLabel(icon: "figure.walk", title: "Steps", labelColor: .teal)
                ) {
                    Text(
                        """
                        The period during which the heart rate, as measured by the Apple Watch, must stay at or above the specified threshold for the Reminder to be triggered.
                        
                        For example: Do a quick reflection when the detected heart rate is greater than 120 for 30 seconds or longer.
                        """
                    )
                }

                IconLabelGroupBox(
                    label: IconLabel(icon: "heart", title: "Heart Rate", labelColor: .pink)
                ) {
                    Text(
                        """
                        The period during which the total number of steps, as measured by the Apple Watch, must stay at or above the threshold for the Reminder to be triggered.
                        
                        For example: Do a quick reflection when completing 2000 or more steps within 30 minutes.
                        """
                    )
                }
            }
            .font(.subheadline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(16)
    }
    // swiftlint:enable trailing_whitespace

    // MARK: Unable to Save Reminder Alert

    private var unableToSaveReminderAlert: Alert {
        Alert(
            title: Text("Error Saving Reminder"),
            message: Text("Unable to save your Reminder.\nPlease try again.\nIf this problem persists, please contact us."),
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

    // MARK: Reflection Deletion Confirmation Alert

    private var reminderDeletionConfirmationAlert: Alert {
        Alert(
            title: Text("Delete Reminder"),
            message: Text("Are you sure you want to delete this Reminder? This action cannot be undone."),
            primaryButton: .destructive(Text("Delete")) {
                viewModel.deleteReminder(reminder)
                dismiss()
            },
            secondaryButton: .cancel()
        )
    }
}

// MARK: - Preview

#Preview {
    CreateReminderView()
        .tint(Color("BrandPrimary"))
}
