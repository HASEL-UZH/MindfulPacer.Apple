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
            .toolbar {
                toolbarContent
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
            if viewModel.mode == .create, viewModel.showActionButton {
                actionButton
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
            SummaryView(viewModel: viewModel)
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
            SummaryView(viewModel: viewModel)
        }
    }

    // MARK: Edit Mode Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
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
                    .buttonStyle(.borderedProminent)
                    .fontWeight(.semibold)
                    .disabled(viewModel.isSaveButtonDisabled)
                }
            }

            if viewModel.mode == .create {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: Action Button

    @ViewBuilder
    private var actionButton: some View {
        Group {
            if #available(iOS 26.0, *) {
                actionButtonBase
                    .buttonStyle(.glassProminent)
            } else {
                actionButtonBase
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal)
        .padding(.horizontal)
        .padding(.top, 8)
        .background(.bar)
    }

    private var actionButtonBase: some View {
        Button {
            viewModel.actionButtonTapped()
        } label: {
            Text(viewModel.actionButtonTitle)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
        }
        .controlSize(.large)
        .buttonBorderShape(.capsule)
        .tint(Color("BrandPrimary"))
        .disabled(viewModel.isActionButtonDisabled)
    }

    // MARK: Intro

    private var intro: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Create Reminder")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top)

                LabeledCard {
                    Text("This allows you to add a new Reminder which can be triggered on your Apple Watch or iPhone.")
                } label: {
                    Label {
                        Text(String(localized: "Reminder"))
                    } icon: {
                        Image(systemName: "exclamationmark.applewatch")
                    }
                    .foregroundStyle(Color("BrandPrimary"))
                }

                Spacer(minLength: 24)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
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
        Button(action: action) {
            HStack(spacing: 12) {
                content()
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? tint : .secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
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
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } icon: {
            Image(systemName: systemImage)
                .symbolVariant(.fill)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 28, alignment: .center)
        }
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
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        }
    }
}

// MARK: - Preview

#Preview {
    CreateReminderView()
        .tint(Color("BrandPrimary"))
}
