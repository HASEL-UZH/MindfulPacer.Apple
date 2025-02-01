//
//  ReflectionsFilterView.swift
//  iOS
//
//  Created by Grigor Dochev on 03.09.2024.
//

import Combine
import SwiftUI

// MARK: - ReflectionsFilterView

// swiftlint:disable:next type_body_length
struct ReflectionsFilterView: View {
    
    // MARK: Properties

    @State private var viewModel: ReflectionsFilterViewModel = ScenesContainer.shared.reviewsFilterViewModel()
    let filterAndSortingPublisher: CurrentValueSubject<(ReflectionFilter, ReflectionSorting), Never>?

    // MARK: Body

    var body: some View {
        NavigationStack {
            RoundedList {
                dateRange

                Section {
                    activities
                    subactivities
                    moods
                    triggeredCrash
                }

                dateSorting

            }
            .navigationTitle("Filter Reflections")
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

    // MARK: Activities

    private var activities: some View {
        NavigationLink {
            activitiesFilterView
        } label: {
            filterItem(
                icon: "rectangle.grid.2x2.fill",
                title: "Activities",
                selectedCount: viewModel.reviewFilter.selectedActivities.count,
                selectedSummary: viewModel.selectedFilterActivitiesSummary
            )
        }
    }

    // MARK: Subactivities

    private var subactivities: some View {
        NavigationLink {
            subactivitiesFilterView
        } label: {
            filterItem(
                icon: "rectangle.grid.3x3.fill",
                title: "Subactivities",
                selectedCount: viewModel.reviewFilter.selectedSubactivities.count,
                selectedSummary: viewModel.selectedFilterSubactivitiesSummary
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

    // MARK: Activities Filter View

    private var activitiesFilterView: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(spacing: 16), count: 3),
                spacing: 16
            ) {
                ForEach(viewModel.activities) { activity in
                    SelectableButton(
                        shape: .roundedRectangle(cornerRadius: 16),
                        isSelected: viewModel.reviewFilter.selectedActivities.contains(activity)
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
        .navigationTitle("Activities")
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: Subactivities Filter View

    private var subactivitiesFilterView: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(spacing: 16), count: 3),
                spacing: 16
            ) {
                ForEach(viewModel.subactivities) { subactivity in
                    SelectableButton(
                        shape: .roundedRectangle(cornerRadius: 16),
                        isSelected: viewModel.reviewFilter.selectedSubactivities.contains(subactivity)
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
        .navigationTitle("Subactivities")
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
                        .tag(ReflectionSorting.dateDescending)
                    Label("Ascending", systemImage: "arrow.up")
                        .tag(ReflectionSorting.dateAscending)
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
    ReflectionsFilterView(filterAndSortingPublisher: nil)
        .tint(Color("BrandPrimary"))
}
