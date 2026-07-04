//
//  IntervalView.swift
//  iOS
//
//  Created by Grigor Dochev on 18.08.2024.
//

import SwiftUI

// MARK: - IntervalView

extension CreateReminderView {
    struct IntervalView: View {
        
        // MARK: Properties

        @Bindable var viewModel: CreateReminderViewModel

        // MARK: Body

        var body: some View {
            List {
                Section {
                    intervalSelectionList
                } header: {
                    ReminderCreationListHero(
                        title: "Choose the Interval",
                        systemImage: viewModel.selectedInterval?.icon ?? "timer",
                        tint: Color("BrandPrimary")
                    )
                } footer: {
                    description
                }
                .listRowBackground(Color(.quaternarySystemFill))
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.presentSheet(.intervalInfo)
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
        }

        // MARK: Interval Selection List

        @ViewBuilder
        private var intervalSelectionList: some View {
            if viewModel.validIntervals.isEmpty {
                InfoBox(text: "Select a measurement type to see the available intervals.")
            } else {
                ForEach(viewModel.validIntervals, id: \.self) { interval in
                    ReminderCreationSelectionRow(
                        isSelected: viewModel.selectedInterval == interval,
                        tint: Color("BrandPrimary")
                    ) {
                        viewModel.toggleSelection(
                            interval,
                            selectedItem: &viewModel.selectedInterval
                        )
                    } label: {
                        ReminderCreationOptionLabel(
                            title: interval.localized,
                            subtitle: nil,
                            systemImage: interval.icon,
                            tint: Color("BrandPrimary")
                        )
                    }
                }
            }
        }

        // MARK: Description

        private var description: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Duration during which the heart rate has to be greater than or equal to the threshold (threshold selected on previous page) in order for the Reminder to be triggered.")

                Button("Learn More") {
                    viewModel.presentSheet(.intervalInfo)
                }
                .font(.subheadline.weight(.semibold))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.createReminderViewModel()

    NavigationStack {
        CreateReminderView.IntervalView(viewModel: viewModel)
    }
    .tint(Color("BrandPrimary"))
}
