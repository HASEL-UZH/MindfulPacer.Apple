//
//  ActivityView.swift
//  iOS
//
//  Created by Grigor Dochev on 20.08.2024.
//

import SwiftUI

// MARK: - ActivityView

extension EditReflectionView {
    struct ActivityView: View {
        
        // MARK: Properties

        @Bindable var viewModel: EditReflectionViewModel

        // MARK: Body

        var body: some View {
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(spacing: 16), count: 2),
                    spacing: 16
                ) {
                    ForEach(viewModel.activities) { activity in
                        SelectableButton(
                            shape: .roundedRectangle(cornerRadius: 16),
                            isSelected: viewModel.selectedActivity == activity
                        ) {
                            viewModel.toggleSelection(activity, selectedItem: &viewModel.selectedActivity)
                        } label: {
                            VStack(spacing: 16) {
                                Image(systemName: activity.icon)
                                    .resizable()
                                    .scaledToFit()
                                    .symbolVariant(.fill)
                                    .frame(width: 32, height: 32)
                                Text(activity.name)
                                    .font(.subheadline)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
                .padding(.horizontal)
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
