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
        @State private var selectedDate: Date

        init(viewModel: AnalyticsViewModel) {
            self.viewModel = viewModel
            _selectedDate = State(initialValue: viewModel.selectedDateForPeriod)
        }
        
        // MARK: Body
        
        var body: some View {
            NavigationStack {
                List {
                    Section {
                        DatePicker(
                            "Selected Date",
                            selection: $selectedDate,
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
                        .foregroundStyle(Color.accentColor)
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
                            viewModel.selectedDateForPeriod = selectedDate
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
