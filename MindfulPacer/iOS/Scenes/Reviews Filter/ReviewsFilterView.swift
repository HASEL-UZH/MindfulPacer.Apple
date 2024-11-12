//
//  ReviewsFilterView.swift
//  iOS
//
//  Created by Grigor Dochev on 03.09.2024.
//

import Combine
import SwiftUI

// MARK: - ReviewsFilterView

// swiftlint:disable:next type_body_length
struct ReviewsFilterView: View {
    
    // MARK: Properties

    @State private var viewModel: ReviewsFilterViewModel = ScenesContainer.shared.reviewsFilterViewModel()

    let filterAndSortingPublisher: CurrentValueSubject<(ReviewFilter, ReviewSorting), Never>?

    // MARK: Body

    var body: some View {
        NavigationStack {
            RoundedList {
                dateRange

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
                ToolbarItem(placement: .topBarLeading) {
                    resetButton
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    CloseButton()
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

    // MARK: Date Range

    private var dateRange: some View {
        Section {
            VStack(spacing: 16) {
                IconLabel(
                    icon: "calendar",
                    title: "Date",
                    labelColor: Color("BrandPrimary"),
                    background: true
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .layoutPriority(1)

                Group {
                    DatePicker(
                        "From",
                        selection: viewModel.fromDateBinding,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)

                    DatePicker(
                        "To",
                        selection: viewModel.toDateBinding,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                }
                .font(.subheadline.weight(.semibold))
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
        }
    }

    // MARK: Categories

    private var categories: some View {
        NavigationLink {
            categoriesFilterView
        } label: {
            filterItem(
                icon: "rectangle.grid.2x2.fill",
                title: "Categories",
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
                icon: "rectangle.grid.3x3.fill",
                title: "Subategories",
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
                icon: "face.smiling.fill",
                title: "Mood",
                selectedCount: viewModel.reviewFilter.selectedMoods.count,
                selectedSummary: viewModel.selectedFilterMoodsSummary
            )
        }
    }

    // MARK: Filter Item

    @ViewBuilder
    private func filterItem(
        icon: String,
        title: String,
        selectedCount: Int,
        selectedSummary: String
    ) -> some View {
        HStack {
            IconLabel(
                icon: icon,
                title: title,
                description: selectedSummary.isEmpty ? nil : selectedSummary,
                labelColor: Color("BrandPrimary"),
                background: true
            )
            .font(.subheadline.weight(.semibold))
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
                ForEach(viewModel.categories) { activity in
                    SelectableButton(
                        shape: .roundedRectangle(cornerRadius: 16),
                        isSelected: viewModel.reviewFilter.selectedCategories.contains(activity)
                    ) {
                        viewModel.toggleFilterActivity(activity)
                    } label: {
                        VStack(spacing: 16) {
                            Image(systemName: activity.icon)
                                .resizable()
                                .scaledToFit()
                                .symbolVariant(.fill)
                                .frame(width: 24, height: 24)
                            Text(activity.name)
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
                ForEach(viewModel.subcategories) { subactivity in
                    SelectableButton(
                        shape: .roundedRectangle(cornerRadius: 16),
                        isSelected: viewModel.reviewFilter.selectedSubcategories.contains(subactivity)
                    ) {
                        viewModel.toggleFilterSubactivity(subactivity)
                    } label: {
                        VStack(spacing: 16) {
                            Image(systemName: subactivity.icon)
                                .resizable()
                                .scaledToFit()
                                .symbolVariant(.fill)
                                .frame(width: 24, height: 24)
                            Text(subactivity.name)
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
                ForEach(DefaultMoodData.moods, id: \.emoji) { mood in
                    SelectableButton(
                        shape: .roundedRectangle(cornerRadius: 12),
                        isSelected: viewModel.reviewFilter.selectedMoods.contains(mood)
                    ) {
                        viewModel.toggleFilterMood(mood)
                    } label: {
                        Text(mood.emoji)
                            .font(.title)
                    }
                    .contextMenu {
                        Text(mood.text)
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
    ReviewsFilterView(filterAndSortingPublisher: nil)
        .tint(Color("BrandPrimary"))
}
