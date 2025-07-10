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
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    intervalSelectionList
                    description
                    Spacer()
                }
                .padding(.horizontal)
            }
            .navigationTitle("Interval")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        viewModel.dismissView()
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
                    SelectableButton(
                        shape: .roundedRectangle(cornerRadius: 16),
                        isSelected: viewModel.selectedInterval == interval
                    ) {
                        viewModel.toggleSelection(
                            interval,
                            selectedItem: &viewModel.selectedInterval
                        )
                    } label: {
                        HStack {
                            IconLabel(
                                icon: interval.icon,
                                title: interval.localized,
                                labelColor: viewModel.selectedInterval == interval ? Color("BrandPrimary") : .primary
                            )
                            Spacer()
                            if viewModel.selectedInterval == interval {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                    }
                }
            }
        }

        // MARK: Description

        private var description: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Duration during which the heart rate has to be greater than or equal to the threshold (threshold selected on previous page) in order for the Reminder to be triggered.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                
                Button("Learn More") {
                    viewModel.presentSheet(.intervalInfo)
                }
                .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal)
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
