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
    
    var reminder: Reminder?

    // MARK: Body

    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            Group {
                rootContent
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
    }

    // MARK: Root Content

    @ViewBuilder
    private var rootContent: some View {
        switch viewModel.mode {
        case .create:
            intro
        case .edit:
            SummaryView(viewModel: viewModel, reminder: reminder)
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
            ThresholdView(viewModel: viewModel)
        case .interval:
            IntervalView(viewModel: viewModel)
        case .summary:
            SummaryView(viewModel: viewModel, reminder: reminder)
        }
    }

    // MARK: Action Button

    @ViewBuilder
    private var actionButton: some View {
        ReminderCreationActionBar(
            title: viewModel.actionButtonTitle,
            isDisabled: viewModel.isActionButtonDisabled
        ) {
            viewModel.actionButtonTapped()
        }
    }

    // MARK: Intro

    private var intro: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ReminderCreationHeroIcon(
                    systemImage: "bell.badge.fill",
                    tint: .brandPrimary,
                    size: 80
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)

                Text("Create Reminder")
                    .font(.largeTitle.bold())

                LabeledCard(contentSpacing: 12) {
                    Text("This allows you to add a new Reminder which can be triggered on your Apple Watch or iPhone.")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                } label: {
                    Label("Reminders", systemImage: "bell.fill")
                        .foregroundStyle(.brandPrimary)
                }
            }
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .safeAreaBar(edge: .bottom) { actionButton }
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button("Close", systemImage: "xmark") { viewModel.shouldDismiss = true }
            }
        }
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

// MARK: - Reminder Creation Selection Row

struct ReminderCreationSelectionRow<Content: View>: View {
    let isSelected: Bool
    let tint: Color
    let action: () -> Void
    @ViewBuilder let content: () -> Content

    init(
        isSelected: Bool,
        tint: Color,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Content
    ) {
        self.isSelected = isSelected
        self.tint = tint
        self.action = action
        self.content = label
    }

    var body: some View {
        SingleSelectRow(isSelected: isSelected, tint: tint, action: action, content: content)
    }
}

struct ReminderCreationHeroIcon: View {
    let systemImage: String
    let tint: Color
    var size: CGFloat = 128

    var body: some View {
        Image(systemName: systemImage)
            .resizable()
            .symbolRenderingMode(.hierarchical)
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(tint)
            .accessibilityHidden(true)
    }
}

struct ReminderCreationListHero: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            ReminderCreationHeroIcon(systemImage: systemImage, tint: tint)
                .frame(maxWidth: .infinity)

            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom)
        .textCase(nil)
    }
}

struct ReminderCreationOptionLabel: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    let tint: Color

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(Color.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
            }
        } icon: {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 28, alignment: .center)
        }
    }
}

struct ReminderCreationActionBar: View {
    let title: String
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        ReminderCreationActionButton(
            title: title,
            isDisabled: isDisabled,
            action: action
        )
        .frame(maxWidth: 600)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
    }
}

struct ReminderCreationActionButton: View {
    let title: String
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        PrimaryButton(title: title, action: action)
            .disabled(isDisabled)
    }
}

struct ReminderCreationInfoBlock: View {
    let title: String
    let systemImage: String
    let tint: Color
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(title)
                    .font(.headline)
            } icon: {
                Image(systemName: systemImage)
                    .symbolVariant(.fill)
                    .foregroundStyle(tint)
            }

            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        }
    }
}

// MARK: - Preview

#Preview {
    CreateReminderView()
        .tint(Color("BrandPrimary"))
}
