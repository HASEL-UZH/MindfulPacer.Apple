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
            ReminderTypeInfoSheet()
        case .heartRateThresholdInfo:
            ThresholdInfoSheet()
        case .intervalInfo:
            IntervalInfoSheet()
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

            VStack {
                Text("Create Reminder")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top)
                
                IconLabelGroupBox(
                    label:
                        IconLabel(
                            icon: "exclamationmark.applewatch",
                            title: "Reminder",
                            labelColor: .brandPrimary,
                            background: true
                        )
                ) {
                    VStack(spacing: 16) {
                        Text("This allows you to add a new Reminder which can be triggered on your Apple Watch or iPhone.")
                    }
                }
            }

            Spacer()
        }
        .padding()
    }
    
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
