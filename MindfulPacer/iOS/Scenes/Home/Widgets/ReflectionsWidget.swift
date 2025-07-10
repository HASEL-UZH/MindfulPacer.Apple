//
//  ReflectionsWidget.swift
//  iOS
//
//  Created by Grigor Dochev on 31.08.2024.
//

import SwiftUI

// MARK: - ReflectionsWidget

extension HomeView {
    struct ReflectionsWidget: View {
        
        // MARK: Properties

        @Bindable var viewModel: HomeViewModel

        // MARK: Body

        var body: some View {
            NavigationLink(value: HomeViewNavigationDestination.reviewsList) {
                IconLabelGroupBox(
                    label: IconLabel(
                        icon: "book.pages.fill",
                        title: String(localized: "My Reflections"),
                        labelColor: Color("BrandPrimary"),
                        background: true
                    ),
                    description:
                        Text("Summary of your most recent reflections.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                ) {
                    if viewModel.reflections.isEmpty {
                        EmptyStateView(
                            image: "book.pages",
                            title: "No Reflections",
                            description: String(localized: "Tap the + button to create a reflection.")
                        )
                    } else {
                        recentReflectionsSummary
                    }
                } accessoryIndicator: {
                    Icon(name: "chevron.right", color: Color(.systemGray2))
                        .font(.subheadline.weight(.semibold))
                } footer: {
                    createReflectionButton
                }
            }
            .foregroundStyle(.primary)
        }

        // MARK: Create Reflection Button

        private var createReflectionButton: some View {
            Button {
                viewModel.presentSheet(.editReflectionView(nil))
            } label: {
                IconLabel(
                    icon: "plus.circle",
                    title: String(localized: "Create Reflection"),
                    labelColor: Color("BrandPrimary")
                )
                    .font(.subheadline.weight(.semibold))
            }
        }

        // MARK: Recent Reflections Summary

        private var recentReflectionsSummary: some View {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.recentReflections) { reflection in
                    ReflectionCell(
                        reflection: reflection,
                        backgroundColor: Color(.tertiarySystemGroupedBackground)
                    ) {
                        viewModel.presentSheet(.editReflectionView(reflection))
                    }
                    if reflection != viewModel.recentReflections.last {
                        Divider()
                    }
                }
            }
            .cornerRadius(16)
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.homeViewModel()

    ScrollView {
        HomeView.ReflectionsWidget(viewModel: viewModel)
            .padding()
    }
    .background(Color(.systemGroupedBackground))
}
