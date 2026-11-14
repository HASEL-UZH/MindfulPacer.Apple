//
//  SubactivityView.swift
//  iOS
//
//  Created by Grigor Dochev on 20.08.2024.
//

import SwiftUI

// MARK: - SubactivityView

extension EditReflectionView {
    struct SubactivityView: View {
        
        // MARK: Properties

        var activity: Activity
        @Environment(\.dismiss) private var dismiss
        @Bindable var viewModel: EditReflectionViewModel
        
        // MARK: Body
        
        var body: some View {
            if (activity.subactivities ?? []).isEmpty {
                ContentUnavailableView {
                    Label("No Subactivities", systemImage: "exclamationmark.circle.fill")
                } description: {
                    Text("There are no subactivities for this activity.")
                }
                .navigationTitle(activity.name)
                .background {
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(activity.subactivities ?? []) { subactivity in
                            SingleSelectRow(
                                isSelected: viewModel.selectedSubactivity == subactivity
                            ) {
                                viewModel.selectedSubactivity = viewModel.selectedSubactivity == subactivity ? nil : subactivity
                                dismiss()
                            } content: {
                                Label {
                                    Text(subactivity.name)
                                        .font(.body)
                                        .fixedSize(horizontal: false, vertical: true)
                                } icon: {
                                    Image(systemName: subactivity.icon)
                                        .symbolVariant(.fill)
                                        .frame(width: 24)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
                .navigationTitle(activity.name)
                .background {
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.editReflectionViewModel()

    EditReflectionView.SubactivityView(activity: Activity(), viewModel: viewModel)
        .tint(Color("BrandPrimary"))
}
