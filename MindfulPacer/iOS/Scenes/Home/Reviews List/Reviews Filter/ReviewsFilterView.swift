//
//  ReviewsFilterView.swift
//  iOS
//
//  Created by Grigor Dochev on 03.09.2024.
//

import Combine
import SwiftUI

// MARK: - ReviewsFilterView

struct ReviewsFilterView: View {
    // MARK: Properties
    
    @State private var viewModel: ReviewsFilterViewModel = ScenesContainer.shared.reviewsFilterViewModel()
    
    let filterAndSortingPublisher: CurrentValueSubject<(ReviewFilter, ReviewSorting), Never>?
    
    // MARK: Body
    
    var body: some View {
        NavigationStack {
            RoundedList {
                Section {
                    categories
                    subcategories
                    moods
                    triggeredCrash
                }
                
                dateSorting
                
            }
            .navigationTitle("Filter Reviews")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    resetButton
                }
            }
            .onViewFirstAppear {
                viewModel.onViewFirstAppear()
                viewModel.setPublisher(filterAndSortingPublisher)
            }
        }
    }
    
    // MARK: Reset Button
    
    private var resetButton: some View {
        Button("Reset") {
            viewModel.resetFilters()
        }
        .fontWeight(.semibold)
    }
    
    // MARK: Categories
    
    private var categories: some View {
        NavigationLink {
            categoriesFilterView
        } label: {
            filterItem(
                label: "Categories",
                icon: "rectangle.grid.2x2.fill",
                selectedCount: viewModel.reviewFilter.selectedCategories.count,
                selectedSummary: viewModel.selectedFilterCategoriesSummary
            )
        }
    }
    
    // MARK: Subcategories
    
    private var subcategories: some View {
        NavigationLink {
            subcategoriesFilterView
        } label: {
            filterItem(
                label: "Subategories",
                icon: "rectangle.grid.3x3.fill",
                selectedCount: viewModel.reviewFilter.selectedSubcategories.count,
                selectedSummary: viewModel.selectedFilterSubcategoriesSummary
            )
        }
    }
    
    // MARK: Moods
    
    private var moods: some View {
        NavigationLink {
            moodFilterView
        } label: {
            filterItem(
                label: "Mood",
                icon: "face.smiling.fill",
                selectedCount: viewModel.reviewFilter.selectedMoods.count,
                selectedSummary: viewModel.selectedFilterMoodsSummary
            )
        }
    }
    
    // MARK: Filter Item
    
    @ViewBuilder
    private func filterItem(
        label: String,
        icon: String,
        selectedCount: Int,
        selectedSummary: String
    ) -> some View {
        HStack {
            Label {
                VStack(alignment: .leading, spacing: 8) {
                    Text(label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.accent)
                    
                    if !selectedSummary.isEmpty {
                        Text(selectedSummary)
                            .font(.footnote)
                            .foregroundStyle(Color.secondary)
                            .lineLimit(1)
                    }
                }
            } icon: {
                Icon(name: icon, background: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 4) {
                if selectedCount > 0 {
                    Text("\(selectedCount)")
                        .foregroundStyle(Color(.systemGray2))
                }
                
                Icon(name: "chevron.right", color: Color(.systemGray2))
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .foregroundStyle(.primary)
    }
    
    // MARK: Categories Filter View
    
    private var categoriesFilterView: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(spacing: 16), count: 3),
                spacing: 16
            ) {
                ForEach(viewModel.categories) { category in
                    SelectableButton(
                        shape: .roundedRectangle(cornerRadius: 16),
                        isSelected: viewModel.reviewFilter.selectedCategories.contains(category),
                        action: {
                            viewModel.toggleFilterCategory(category)
                        }) {
                            VStack(spacing: 16) {
                                Image(systemName: category.icon)
                                    .resizable()
                                    .scaledToFit()
                                    .symbolVariant(.fill)
                                    .frame(width: 24, height: 24)
                                Text(category.name)
                                    .font(.footnote)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Categories")
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
    
    // MARK: Subcategories Filter View
    
    private var subcategoriesFilterView: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(spacing: 16), count: 3),
                spacing: 16
            ) {
                ForEach(viewModel.subcategories) { subcategory in
                    SelectableButton(
                        shape: .roundedRectangle(cornerRadius: 16),
                        isSelected: viewModel.reviewFilter.selectedSubcategories.contains(subcategory),
                        action: {
                            viewModel.toggleFilterSubcategory(subcategory)
                        }) {
                            VStack(spacing: 16) {
                                Image(systemName: subcategory.icon)
                                    .resizable()
                                    .scaledToFit()
                                    .symbolVariant(.fill)
                                    .frame(width: 24, height: 24)
                                Text(subcategory.name)
                                    .font(.footnote)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Subcategories")
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
    
    // MARK: Mood Filter View
    
    private var moodFilterView: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(spacing: 16), count: 5),
                spacing: 16
            ) {
                ForEach(DefaultMoodData.moods, id: \.id) { mood in
                    SelectableButton(
                        shape: .roundedRectangle(cornerRadius: 12),
                        isSelected: viewModel.reviewFilter.selectedMoods.contains(mood),
                        action: {
                            viewModel.toggleFilterMood(mood)
                        }) {
                            Text(mood.emoji)
                                .font(.title)
                        }
                        .contextMenu {
                            Text(mood.description)
                        }
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Mood")
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
    
    // MARK: Triggered Crash
    
    private var triggeredCrash: some View {
        Toggle(isOn: viewModel.triggeredCrashBinding) {
            IconLabel(
                icon: "exclamationmark.triangle.fill",
                title: "Triggered Crash",
                labelColor: Color("BrandPrimary"),
                background: true
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .layoutPriority(1)
        }
        .tint(.accentColor)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
    }
    
    // MARK: Date Sorting
    
    private var dateSorting: some View {
        Section {
            HStack {
                IconLabel(
                    icon: "arrow.up.arrow.down",
                    title: "Date",
                    labelColor: Color("BrandPrimary"),
                    background: true
                )
                .font(.subheadline.weight(.semibold))
                
                Spacer(minLength: 32)
                
                Picker(String(), selection: viewModel.reviewSortingBinding) {
                    Label("Descending", systemImage: "arrow.down")
                        .tag(ReviewSorting.dateDescending)
                    Label("Ascending", systemImage: "arrow.up")
                        .tag(ReviewSorting.dateAscending)
                }
                .pickerStyle(.segmented)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
        } header: {
            Text("Sorting")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: ReviewsFilterViewModel = ScenesContainer.shared.reviewsFilterViewModel()
    
    ReviewsFilterView(filterAndSortingPublisher: nil)
        .tint(Color("BrandPrimary"))
}
