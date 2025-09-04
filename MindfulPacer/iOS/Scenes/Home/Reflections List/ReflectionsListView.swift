//
//  ReflectionsListView.swift
//  iOS
//
//  Created by Grigor Dochev on 29.08.2024.
//

import SwiftUI

// MARK: - ReflectionsListView

extension HomeView {
    struct ReflectionsListView: View {
        
        // MARK: - Properties

        @Bindable var viewModel: HomeViewModel

        // MARK: Body
        
        var body: some View {
            VStack(spacing: 16) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        reviewFilterDateRangeSummary
                        if viewModel.reviewFilter.activeFilterCount != 0 {
                            reviewFilterSortingSummary
                        }
                    }
                    .safeAreaPadding(.horizontal)
                }
                
                if viewModel.reflections.isEmpty {
                    reviewsEmptyState
                        .frame(maxHeight: .infinity, alignment: .center)
                } else if viewModel.filteredReflections.isEmpty {
                    filteredReflectionsEmptyState
                        .frame(maxHeight: .infinity, alignment: .center)
                    
                } else {
                    RoundedList {
                        ForEach(viewModel.filteredReflections, id: \.id) { reflection in
                            ReflectionCell(reflection: reflection) {
                                viewModel.presentSheet(.editReflectionView(reflection))
                            }
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Reflections")
            .toolbar {
                if !viewModel.reflections.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.presentSheet(.reviewsFilterView)
                        } label: {
                            Label("Filter Reflections", systemImage: "line.3.horizontal.decrease.circle.fill")
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.presentSheet(.editReflectionView(nil))
                    } label: {
                        Label("New Reflection", systemImage: "plus.circle.fill")
                    }
                }
            }
        }
        
        // MARK: Reflections Empty State

        private var reviewsEmptyState: some View {
            VStack(alignment: .leading, spacing: 16) {
                ContentUnavailableView {
                    Label("No Reflections", systemImage: "book.pages.fill")
                } description: {
                    Text("You have not created any reflections.")
                } actions: {
                    Button {
                        viewModel.presentSheet(.editReflectionView(nil))
                    } label: {
                        Text("Create Reflection")
                    }
                    .buttonBorderShape(.capsule)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        
        // MARK: Filtered Reflections Empty State
        
        private var filteredReflectionsEmptyState: some View {
            VStack(alignment: .leading, spacing: 16) {
                ContentUnavailableView {
                    Label("No Results", systemImage: "magnifyingglass")
                } description: {
                    Text("No reflections match your current filter criteria.")
                } actions: {
                    Button {
                        viewModel.presentSheet(.reviewsFilterView)
                    } label: {
                        Text("Modify Filters")
                    }
                    .buttonBorderShape(.capsule)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        
        // MARK: Reflection Filter Date Range Summary
        
        private var reviewFilterDateRangeSummary: some View {
            Button {
                viewModel.presentSheet(.reviewsFilterView)
            } label: {
                HStack(spacing: 4) {
                    Icon(name: "calendar")

                    Text(viewModel.filterDateRangeSummary)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.accent)
                    
                }
                .layoutPriority(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .foregroundStyle(Color("BrandPrimary").opacity(0.1))
                }
            }
        }
        
        // MARK: Reflection Filter Sorting Summary

        private var reviewFilterSortingSummary: some View {
            HStack(spacing: 8) {
                activityFilterSummary
                subactivityFilterSummary
                moodFilterSummary
                crashFilterSummary
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        // MARK: Activity Filter Summary

        private var activityFilterSummary: some View {
            ForEach(viewModel.reviewFilter.selectedActivities) { activity in
                filterItem(
                    icon: activity.icon,
                    label: activity.name,
                    removeAction: { viewModel.toggleFilterActivity(activity) }
                )
            }
        }

        // MARK: Subactivity Filter Summary

        private var subactivityFilterSummary: some View {
            ForEach(viewModel.reviewFilter.selectedSubactivities, id: \.id) { subactivity in
                filterItem(
                    icon: subactivity.icon,
                    label: subactivity.name,
                    removeAction: { viewModel.toggleFilterSubactivity(subactivity) }
                )
            }
        }

        // MARK: Mood Filter Summary

        private var moodFilterSummary: some View {
            ForEach(viewModel.reviewFilter.selectedMoods, id: \.text) { mood in
                filterItem(
                    emoji: mood.emoji,
                    removeAction: { viewModel.toggleFilterMood(mood) }
                )
            }
        }

        // MARK: Crash Filter Summary

        @ViewBuilder
        private var crashFilterSummary: some View {
            if viewModel.reviewFilter.triggeredCrash {
                filterItem(
                    icon: "pill",
                    label: "Triggered Crash",
                    removeAction: { viewModel.toggleTriggeredCrash() }
                )
            }
        }

        // MARK: Filter Item

        @ViewBuilder
        private func filterItem(
            icon: String? = nil,
            emoji: String? = nil,
            label: String? = nil,
            removeAction: @escaping () -> Void
        ) -> some View {
            HStack(spacing: 4) {
                if let icon = icon {
                    Icon(name: icon)
                }
                if let emoji = emoji {
                    Text(emoji)
                        .frame(width: 24, height: 24)
                }
                if let label = label {
                    Text(label)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.accent)
                }
                Button {
                    removeAction()
                } label: {
                    Icon(name: "xmark.circle", renderingMode: .hierarchical)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .foregroundStyle(Color("BrandPrimary").opacity(0.1))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.homeViewModel()

    NavigationStack {
        HomeView.ReflectionsListView(viewModel: viewModel)
    }
    .tint(.brandPrimary)
}
