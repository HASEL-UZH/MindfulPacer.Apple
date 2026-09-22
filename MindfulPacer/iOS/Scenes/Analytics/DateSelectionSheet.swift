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
                List {
                    Section {
                        DatePicker(
                            "",
                            selection: $viewModel.selectedDateForPeriod,
                            in: Date.distantPast...Date(),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .datePickerStyle(.graphical)
                    } header: {
                        Text("Date Selection")
                    } footer: {
                        Text("Select the date for which to view health data and reflections.")
                    }

                    Section {
                        Button {
                            viewModel.onTodayTapped()
                            dismiss()
                        } label: {
                            Label("Today", systemImage: "calendar")
                        }
                        .foregroundStyle(.primary)
                    }
                }
                .navigationTitle("Date")
                .navigationBarTitleDisplayMode(.inline)
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
                        }
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
