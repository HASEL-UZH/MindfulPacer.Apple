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
        @Bindable var viewModel: EditReflectionViewModel

        // MARK: Body

        var body: some View {
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(spacing: 16), count: 2),
                    spacing: 16
                ) {
                    ForEach(activity.subactivities!) { subactivity in
                        SelectableButton(
                            shape: .roundedRectangle(cornerRadius: 16),
                            isSelected: viewModel.selectedSubactivity == subactivity
                        ) {
                            viewModel.toggleSelection(subactivity, selectedItem: &viewModel.selectedSubactivity)
                        } label: {
                            VStack(spacing: 16) {
                                Image(systemName: subactivity.icon)
                                    .resizable()
                                    .scaledToFit()
                                    .symbolVariant(.fill)
                                    .frame(width: 32, height: 32)
                                Text(subactivity.name)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                                    .truncationMode(.middle)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Subactivity")
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

    EditReflectionView.SubactivityView(activity: Activity(), viewModel: viewModel)
        .tint(Color("BrandPrimary"))
}
