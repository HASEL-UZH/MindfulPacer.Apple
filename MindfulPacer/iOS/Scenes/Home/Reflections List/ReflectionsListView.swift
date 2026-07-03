//
//  ReflectionsListView.swift
//  iOS
//
//  Created by Grigor Dochev on 29.08.2024.
//

import SwiftUI
import SwiftData

// MARK: - ReflectionsListView

extension HomeView {
    struct ReflectionsListView: View {
        
        // MARK: - Properties

        @Bindable var viewModel: HomeViewModel
        @State private var activeReflectionID: UUID?
        @State private var reflectionPendingDeletion: Reflection?

        @Query(sort: \Activity.name) private var activities: [Activity]

        // MARK: Body
        
        var body: some View {
            Group {
                if viewModel.reflections.isEmpty {
                    reviewsEmptyState
                        .frame(maxHeight: .infinity, alignment: .center)
                } else if viewModel.filteredReflections.isEmpty {
                    filteredReflectionsEmptyState
                        .frame(maxHeight: .infinity, alignment: .center)
                } else {
                    reflectionsList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Reflections")
            .alert("Delete Reflection", isPresented: isDeleteConfirmationPresented) {
                Button("Delete", role: .destructive) {
                    deletePendingReflection()
                }

                Button("Cancel", role: .cancel) {
                    reflectionPendingDeletion = nil
                }
            } message: {
                Text("Are you sure you want to delete this reflection? This action cannot be undone.")
            }
            .toolbar {
                if !viewModel.reflections.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.presentSheet(.reviewsFilterView)
                        } label: {
                            Label("Filter Reflections", systemImage: filterButtonSystemImage)
                                .foregroundStyle(hasActiveFilters ? Color("BrandPrimary") : .primary)
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

        private var reflectionsList: some View {
            GeometryReader { proxy in
                ScrollView {
                    ZStack(alignment: .top) {
                        Color.clear
                            .contentShape(.rect)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: proxy.size.height)
                            .onTapGesture {
                                clearActiveReflection()
                            }

                        LazyVStack(alignment: .leading, spacing: 6) {
                            ExpandableMetadataSectionHeader(
                                title: "All Reflections",
                                count: viewModel.filteredReflections.count
                            )

                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(viewModel.filteredReflections, id: \.id) { reflection in
                                    reflectionRow(reflection)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                }
                .background(Color(.systemGroupedBackground))
            }
        }

        private var isDeleteConfirmationPresented: Binding<Bool> {
            Binding {
                reflectionPendingDeletion != nil
            } set: { isPresented in
                if !isPresented {
                    reflectionPendingDeletion = nil
                }
            }
        }

        // MARK: Filter Button State

        private var hasActiveFilters: Bool {
            viewModel.reviewFilter.activeFilterCount != 0
        }

        private var filterButtonSystemImage: String {
            hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease"
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

        @ViewBuilder
        private func reflectionRow(_ reflection: Reflection) -> some View {
            let metadataRow = ExpandableMetadataRow(
                id: reflection.id,
                activeID: $activeReflectionID,
                expandedContentLeadingInset: 44
            ) { isActive in
                reflectionRowContent(reflection, isActive: isActive)
            } rowAccessory: { isActive in
                reflectionRowAccessory(reflection, isActive: isActive)
            } expandedContent: {
                reflectionQuickActions(reflection)
            }

            if activeReflectionID != reflection.id {
                metadataRow
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            presentDeleteConfirmation(for: reflection)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } onPresentationChanged: { isPresented in
                        guard isPresented else { return }
                        clearActiveReflection()
                    }
            } else {
                metadataRow
            }
        }

        private func reflectionRowContent(_ reflection: Reflection, isActive: Bool) -> some View {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: reflectionIconName(reflection))
                    .symbolVariant(.circle.fill)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(isActive ? Color("BrandPrimary") : .secondary)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(reflectionTitle(reflection))
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(reflectionSubtitle(reflection))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 4)
        }

        @ViewBuilder
        private func reflectionRowAccessory(_ reflection: Reflection, isActive: Bool) -> some View {
            if isActive {
                Button {
                    viewModel.presentSheet(.editReflectionView(reflection))
                } label: {
                    Image(systemName: "info.circle")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color("BrandPrimary"))
                        .frame(width: 32, height: 32)
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit Reflection")
                .padding(.top, 4)
            }
        }

        private func reflectionQuickActions(_ reflection: Reflection) -> some View {
            ExpandableMetadataScroll {
                ExpandableMetadataMenuChip(
                    title: reflection.activity?.name ?? String(localized: "Activity"),
                    systemImage: reflection.activity?.icon ?? "rectangle.grid.2x2",
                    isActive: reflection.activity != nil
                ) {
                    Section {
                        ForEach(activities) { activity in
                            Button(activity.name, systemImage: activity.icon) {
                                viewModel.updateReflection(reflection, activity: activity)
                            }
                        }
                    }

                    Section {
                        Button("Uncategorized", systemImage: "questionmark") {
                            viewModel.updateReflection(reflection, activity: nil)
                        }
                    }
                }

                if let activity = reflection.activity {
                    ExpandableMetadataMenuChip(
                        title: reflection.subactivity?.name ?? String(localized: "Subactivity"),
                        systemImage: reflection.subactivity?.icon ?? "rectangle.grid.3x3",
                        isActive: reflection.subactivity != nil
                    ) {
                        Section {
                            ForEach((activity.subactivities ?? []).sorted { $0.name < $1.name }) { subactivity in
                                Button(subactivity.name, systemImage: subactivity.icon) {
                                    viewModel.updateReflection(reflection, subactivity: subactivity)
                                }
                            }
                        }

                        Section {
                            Button("None", systemImage: "minus.circle") {
                                viewModel.updateReflection(reflection, subactivity: nil)
                            }
                        }
                    }
                }

                ExpandableMetadataMenuChip(
                    title: reflection.mood?.emoji ?? String(localized: "Mood"),
                    systemImage: "face.smiling",
                    isActive: reflection.mood != nil
                ) {
                    Section {
                        ForEach(DefaultMoodData.moods, id: \.emoji) { mood in
                            Button("\(mood.emoji) \(mood.text)") {
                                viewModel.updateReflection(reflection, mood: mood)
                            }
                        }
                    }

                    Section {
                        Button("None", systemImage: "minus.circle") {
                            viewModel.updateReflection(reflection, mood: nil)
                        }
                    }
                }

                let wellBeing = Symptom.wellBeing(reflection.wellBeing)
                ExpandableMetadataMenuChip(
                    title: wellBeing.description,
                    systemImage: wellBeing.icon,
                    isActive: reflection.wellBeing != nil,
                    tint: wellBeing.color
                ) {
                    Section {
                        ForEach(0 ..< wellBeing.numOptions, id: \.self) { value in
                            Button(wellBeing.description(for: value), systemImage: "\(value).circle") {
                                viewModel.updateReflection(reflection, wellBeing: value)
                            }
                        }
                    }

                    Section {
                        Button("Not Set", systemImage: "minus.circle") {
                            viewModel.updateReflection(reflection, wellBeing: nil)
                        }
                    }
                }

                ExpandableMetadataChipButton(
                    title: "Crash",
                    systemImage: "exclamationmark.triangle.fill",
                    isActive: reflection.didTriggerCrash,
                    tint: .orange
                ) {
                    viewModel.toggleReflectionCrash(reflection)
                }

            }
        }

        private func clearActiveReflection() {
            withAnimation(.snappy(duration: 0.24)) {
                activeReflectionID = nil
            }
        }

        private func presentDeleteConfirmation(for reflection: Reflection) {
            clearActiveReflection()
            reflectionPendingDeletion = reflection
        }

        private func deletePendingReflection() {
            guard let reflection = reflectionPendingDeletion else { return }
            reflectionPendingDeletion = nil
            activeReflectionID = nil
            viewModel.deleteReflection(reflection)
        }

        private func reflectionIconName(_ reflection: Reflection) -> String {
            reflection.subactivity?.icon ?? reflection.activity?.icon ?? "book.closed.fill"
        }

        private func reflectionTitle(_ reflection: Reflection) -> String {
            reflection.subactivity?.name ?? reflection.activity?.name ?? String(localized: "Uncategorized")
        }

        private func reflectionSubtitle(_ reflection: Reflection) -> String {
            var parts: [String] = [
                reflection.date.formatted(.dateTime.day().month().hour().minute())
            ]

            if let mood = reflection.mood {
                parts.append("\(mood.emoji) \(mood.text)")
            }

            if let wellBeing = reflection.wellBeing {
                parts.append(Symptom.wellBeing(wellBeing).description)
            }

            if reflection.didTriggerCrash {
                parts.append(String(localized: "Crash"))
            }

            return parts.joined(separator: " - ")
        }
    }
}

// MARK: - Expandable Metadata Section Header

private struct ExpandableMetadataSectionHeader: View {
    let title: String
    let count: Int

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)

            Text(count, format: .number)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background {
                    Capsule(style: .continuous)
                        .fill(Color(.tertiarySystemGroupedBackground))
                }
        }
        .padding(.top, 6)
        .padding(.bottom, 2)
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
