//
//  ReflectionsFilterView.swift
//  iOS
//
//  Created by Grigor Dochev on 03.09.2024.
//

import Combine
import SwiftUI

// MARK: - ReflectionsFilterView

struct ReflectionsFilterView: View {

    // MARK: Dependencies

    @Environment(\.dismiss) private var dismiss

    // MARK: Properties

    @State private var viewModel: ReflectionsFilterViewModel = ScenesContainer.shared.reviewsFilterViewModel()
    @State private var expandedSubactivityActivityIDs: Set<UUID> = []

    let filterAndSortingPublisher: CurrentValueSubject<(ReflectionFilter, ReflectionSorting), Never>?
    let activities: [Activity]

    // MARK: Init

    init(
        filterAndSortingPublisher: CurrentValueSubject<(ReflectionFilter, ReflectionSorting), Never>?,
        activities: [Activity] = []
    ) {
        self.filterAndSortingPublisher = filterAndSortingPublisher
        self.activities = activities
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            filterSections
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Filter Reflections")
                .navigationBarTitleDisplayMode(.inline)
                .modifier(FilterNavigationSubtitleModifier(subtitle: viewModel.navigationSubtitle))
                .toolbar { toolbarContent }
                .onViewFirstAppear {
                    viewModel.onViewFirstAppear()
                    viewModel.setPublisher(filterAndSortingPublisher)
                    viewModel.updateActivities(activities)
                    expandSelectedSubactivityGroups()
                }
                .onChange(of: activities) { _, newValue in
                    viewModel.updateActivities(newValue)
                    expandSelectedSubactivityGroups()
                }
        }
    }
}

// MARK: - Toolbar Content

private extension ReflectionsFilterView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            CloseButton()
        }

        ToolbarItem(placement: .confirmationAction) {
            Button(role: .confirm) {
                dismiss()
            }
        }
    }
}

// MARK: - Filter Sections

private extension ReflectionsFilterView {
    var filterSections: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                dateRangeSection
                activitiesSection
                subactivitiesSection
                moodSection
                crashSection
                sortingSection
            }
            .padding(.vertical, 20)
        }
    }

    var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                FilterSectionHeader(
                    title: "Date Range",
                    subtitle: viewModel.dateRangeSummary
                )

                Spacer()

                clearAllButton
            }

            VStack(spacing: 8) {
                DatePicker(
                    "From",
                    selection: viewModel.fromDateBinding,
                    in: ...viewModel.reviewFilter.toDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.compact)
                .filterControlBackground()

                DatePicker(
                    "To",
                    selection: viewModel.toDateBinding,
                    in: viewModel.reviewFilter.fromDate...,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.compact)
                .filterControlBackground()
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal)
        }
    }

    var activitiesSection: some View {
        filterChipSection(
            title: "Activities",
            subtitle: viewModel.activitiesSubtitle,
            isEmpty: viewModel.activities.isEmpty,
            emptyTitle: "No activities available"
        ) {
            ForEach(viewModel.activities) { activity in
                FilterCapsuleButton(
                    title: activity.name,
                    systemImage: activity.icon,
                    isSelected: viewModel.reviewFilter.selectedActivities.contains(activity)
                ) {
                    viewModel.toggleFilterActivity(activity)
                }
            }
        }
    }

    var subactivitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FilterSectionHeader(
                title: "Subactivities",
                subtitle: viewModel.subactivitiesSubtitle
            )

            if viewModel.activitiesWithSubactivities.isEmpty {
                Text("No subactivities available")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .filterControlBackground()
                    .padding(.horizontal)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(viewModel.activitiesWithSubactivities) { activity in
                        subactivityGroup(for: activity)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    var moodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FilterSectionHeader(
                title: "Mood",
                subtitle: viewModel.moodsSubtitle
            )

            LazyVGrid(columns: filterGridColumns, spacing: 8) {
                ForEach(DefaultMoodData.moods, id: \.emoji) { mood in
                    FilterCapsuleButton(
                        title: mood.text,
                        emoji: mood.emoji,
                        isSelected: viewModel.reviewFilter.selectedMoods.contains(mood)
                    ) {
                        viewModel.toggleFilterMood(mood)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    var crashSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FilterSectionHeader(
                title: "Crash",
                subtitle: viewModel.crashSubtitle
            )

            Toggle(isOn: viewModel.triggeredCrashBinding) {
                Label {
                    Text("Triggered Crash Only")
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }
            .font(.subheadline.weight(.semibold))
            .tint(Color("BrandPrimary"))
            .filterControlBackground()
            .padding(.horizontal)
        }
    }

    var sortingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FilterSectionHeader(
                title: "Sorting",
                subtitle: viewModel.sortingSubtitle
            )

            LazyVGrid(columns: filterGridColumns, spacing: 8) {
                ForEach(ReflectionSorting.allCases, id: \.self) { sorting in
                    FilterCapsuleButton(
                        title: sorting.title,
                        systemImage: sorting.systemImage,
                        isSelected: viewModel.reviewSorting == sorting
                    ) {
                        viewModel.updateSorting(sorting)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Helpers

private extension ReflectionsFilterView {
    var filterGridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
    }

    var clearAllButton: some View {
        Button("Clear All") {
            viewModel.resetFilters()
            expandedSubactivityActivityIDs.removeAll()
        }
        .disabled(!viewModel.hasActiveFilters)
        .fontWeight(.semibold)
        .padding(.trailing)
    }

    func subactivityGroup(for activity: Activity) -> some View {
        let isExpanded = expandedSubactivityActivityIDs.contains(activity.id)

        return VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    toggleSubactivityGroup(activity)
                }
            } label: {
                subactivityDisclosureLabel(for: activity, isExpanded: isExpanded)
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")

            if isExpanded {
                LazyVGrid(columns: filterGridColumns, spacing: 8) {
                    ForEach(activity.subactivities ?? []) { subactivity in
                        FilterCapsuleButton(
                            title: subactivity.name,
                            systemImage: subactivity.icon,
                            isSelected: viewModel.reviewFilter.selectedSubactivities.contains(subactivity)
                        ) {
                            viewModel.toggleFilterSubactivity(subactivity)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    func subactivityDisclosureLabel(for activity: Activity, isExpanded: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: activity.icon)
                .symbolVariant(.fill)
                .foregroundStyle(Color("BrandPrimary"))

            Text(activity.name)
                .font(.subheadline.weight(.semibold))

            Spacer()

            Text(subactivitySelectionSubtitle(for: activity))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.secondary)

            Image(systemName: "chevron.down")
                .font(.footnote.weight(.bold))
                .foregroundStyle(Color.secondary)
                .rotationEffect(.degrees(isExpanded ? 0 : -90))
        }
        .foregroundStyle(Color.primary)
        .contentShape(.rect)
        .padding(.vertical, 2)
    }

    func subactivitySelectionSubtitle(for activity: Activity) -> String {
        let selectedCount = viewModel.selectedSubactivityCount(for: activity)
        return selectedCount == 0 ? String(localized: "All") : String(localized: "\(selectedCount) selected")
    }

    func toggleSubactivityGroup(_ activity: Activity) {
        if expandedSubactivityActivityIDs.contains(activity.id) {
            expandedSubactivityActivityIDs.remove(activity.id)
        } else {
            expandedSubactivityActivityIDs.insert(activity.id)
        }
    }

    func expandSelectedSubactivityGroups() {
        for activity in viewModel.activitiesWithSubactivities where viewModel.selectedSubactivityCount(for: activity) > 0 {
            expandedSubactivityActivityIDs.insert(activity.id)
        }
    }

    @ViewBuilder
    func filterChipSection<Content: View>(
        title: String,
        subtitle: String?,
        isEmpty: Bool,
        emptyTitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            FilterSectionHeader(title: title, subtitle: subtitle)

            if isEmpty {
                Text(emptyTitle)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .filterControlBackground()
                    .padding(.horizontal)
            } else {
                LazyVGrid(columns: filterGridColumns, spacing: 8) {
                    content()
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Filter Navigation Subtitle Modifier

private struct FilterNavigationSubtitleModifier: ViewModifier {
    let subtitle: String

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.navigationSubtitle(subtitle)
        } else {
            content
        }
    }
}

// MARK: - View Helpers

private extension View {
    func filterControlBackground() -> some View {
        self
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background {
                Capsule()
                    .foregroundStyle(Color(.secondarySystemGroupedBackground))
            }
    }

}

// MARK: - Preview

#Preview {
    ReflectionsFilterView(filterAndSortingPublisher: nil)
        .tint(Color("BrandPrimary"))
}
