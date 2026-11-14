//
//  ActivityView.swift
//  iOS
//
//  Created by Grigor Dochev on 20.08.2024.
//

import SwiftUI
import SwiftData

// MARK: - ActivityView

extension EditReflectionView {
    struct ActivityView: View {
        
        // MARK: Properties

        @Environment(\.dismiss) private var dismiss
        @Bindable var viewModel: EditReflectionViewModel
        
        @Query(sort: \Activity.name) private var activities: [Activity]

        // MARK: Body

        var body: some View {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(activities) { activity in
                        SingleSelectRow(
                            isSelected: viewModel.selectedActivity == activity
                        ) {
                            viewModel.selectedActivity = viewModel.selectedActivity == activity ? nil : activity
                            dismiss()
                        } content: {
                            Label {
                                Text(activity.name)
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)
                            } icon: {
                                Image(systemName: activity.icon)
                                    .symbolVariant(.fill)
                                    .frame(width: 24)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Activity")
            .background {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.editReflectionViewModel()

    NavigationStack {
        EditReflectionView.ActivityView(viewModel: viewModel)
            .navigationTitle("Activity")
            .tint(Color("BrandPrimary"))
            .onAppear {
                viewModel.onViewFirstAppear()
            }
    }
}
