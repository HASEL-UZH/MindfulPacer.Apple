//
//  DateSelectionSheet.swift
//  iOS
//
//  Created by Grigor Dochev on 29.09.2025.
//

import SwiftUI

// MARK: - DateSelectionSheet

extension AnalyticsView {
    struct DateSelectionSheet: View {
        
        // MARK: Properties
        
        @Environment(\.dismiss) private var dismiss
        @Bindable var viewModel: AnalyticsViewModel
        
        // MARK: Body
        
        var body: some View {
            NavigationStack {
                VStack(alignment: .leading, spacing: 16) {
                    IconLabelGroupBox(
                        label:
                            IconLabel(
                                icon: "calendar",
                                title: String(localized: "Date Selection"),
                                labelColor: .brandPrimary,
                                background: true
                            ),
                        description:
                            Text("Select the date for which to view reflections.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    ) {
                        DatePicker(
                            "",
                            selection: $viewModel.selectedDateForPeriod,
                            in: Date.distantPast...Date(),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .datePickerStyle(.graphical)
                    } footer: {
                        HStack {
                            Button {
                                viewModel.onTodayTapped()
                                dismiss()
                            } label: {
                                IconLabel(
                                    icon: "calendar",
                                    title: String(localized: "Today"),
                                    labelColor: .brandPrimary
                                )
                                .font(.subheadline.weight(.semibold))
                            }
                            
                            Spacer()
                        }
                    }
                    .iconLabelGroupBoxStyle(.divider)
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(role: .cancel) {
                            dismiss()
                        } label: {
                            Text("Cancel")
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.onSelectedDateForPeriodChanged()
                            dismiss()
                        } label: {
                            Text("Done")
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: AnalyticsViewModel = ScenesContainer.shared.analyticsViewModel()
    AnalyticsView.DateSelectionSheet(viewModel: viewModel)
        .tint(.brandPrimary)
}
