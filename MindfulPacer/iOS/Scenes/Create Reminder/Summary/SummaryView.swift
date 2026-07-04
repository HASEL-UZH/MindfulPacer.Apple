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
            List {
                Section {
                    measurementType
                    reminderType
                    threshold
                    interval
                } header: {
                    ReminderCreationListHero(
                        title: "Review Reminder",
                        systemImage: viewModel.selectedMeasurementType?.icon ?? "checkmark.circle",
                        tint: viewModel.selectedMeasurementType?.color ?? Color("BrandPrimary")
                    )
                }
                .listRowBackground(Color(.quaternarySystemFill))

                if viewModel.mode == .edit {
                    Section {
                        deleteButton
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(viewModel.mode == .edit ? viewModel.summaryViewTitle : "")
        }
        
        // MARK: Summary Row

        @ViewBuilder
        private func summaryRow<Content: View>(
            icon: String,
            title: String,
            destination: CreateReminderNavigationDestination?,
            tint: Color = Color("BrandPrimary"),
            @ViewBuilder value: @escaping () -> Content
        ) -> some View {
            if let destination {
                Button {
                    viewModel.navigationPath.append(destination)
                } label: {
                    summaryRowContent(
                        icon: icon,
                        title: title,
                        tint: tint,
                        value: value
                    )
                }
                .buttonStyle(.plain)
            } else {
                summaryRowContent(
                    icon: icon,
                    title: title,
                    tint: tint,
                    value: value
                )
            }
        }

        private func summaryRowContent<Content: View>(
            icon: String,
            title: String,
            tint: Color,
            @ViewBuilder value: @escaping () -> Content
        ) -> some View {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .symbolVariant(.fill)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    value()
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if viewModel.mode == .create {
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .contentShape(.rect)
        }
        
        // MARK: Measurement Type
        
        private var measurementType: some View {
            summaryRow(
                icon: "ruler",
                title: String(localized: "Measurement Type"),
                destination: viewModel.mode == .create ? .measurementType : nil,
                tint: viewModel.selectedMeasurementType?.color ?? Color("BrandPrimary")
            ) {
                if let measurementType = viewModel.selectedMeasurementType {
                    Text(measurementType.localized)
                } else {
                    Text("No Measurement Type Selected")
                        .foregroundStyle(.red)
                }
            }
        }
        
        // MARK: Reminder Type
        
        private var reminderType: some View {
            summaryRow(
                icon: "alarm",
                title: String(localized: "Reminder Type"),
                destination: .reminderType,
                tint: viewModel.selectedReminderType?.color ?? Color("BrandPrimary")
            ) {
                if let reminderType = viewModel.selectedReminderType {
                    Text(reminderType.localized)
                } else {
                    Text("No Reminder Type Selected")
                        .foregroundStyle(.red)
                }
            }
        }
        
        // MARK: Threshold
        
        private var threshold: some View {
            summaryRow(
                icon: "chart.line.flattrend.xyaxis",
                title: String(localized: "Threshold"),
                destination: .threshold,
                tint: viewModel.selectedMeasurementType?.color ?? Color("BrandPrimary")
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
            summaryRow(
                icon: "timer",
                title: String(localized: "Interval"),
                destination: .interval
            ) {
                if let interval = viewModel.selectedInterval {
                    Text(interval.localized)
                } else {
                    Text("No Interval Selected")
                        .foregroundStyle(.red)
                }
            }
        }
        
        // MARK: Delete Button
        
        private var deleteButton: some View {
            Button(role: .destructive) {
                viewModel.presentAlert(.deleteConfirmation)
            } label: {
                Label("Delete Reminder", systemImage: "trash")
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
