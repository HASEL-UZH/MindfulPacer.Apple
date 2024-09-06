//
//  ReviewsFilterView.swift
//  iOS
//
//  Created by Grigor Dochev on 03.09.2024.
//

import SwiftUI

// MARK: - ReviewsFilterView

struct ReviewsFilterView: View {
    @Bindable var viewModel: HomeViewModel

    // MARK: Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    categoriesLink
                    moodLink
                    triggerCrash
                    
                    Card {
                        Picker(selection: $viewModel.reviewSorting) {
                            Label("Date Ascending", systemImage: "arrow.up")
                                .tag(HomeViewModel.ReviewSorting.dateAscending)
                            
                            Label("Date Descending", systemImage: "arrow.down")
                                .tag(HomeViewModel.ReviewSorting.dateDescending)
                        } label: {
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
                        }
                        .pickerStyle(.menu)
                    }
                }
                .padding(.horizontal)
            }
            .cornerRadius(30)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Filter Reviews")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    resetButton
                }
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
    
    // MARK: - Categories Link
    
    private var categoriesLink: some View {
        NavigationLink {
            categoriesFilterView
        } label: {
            Card {
                HStack {
                    Label {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Categories")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.accent)
                            
                            if !viewModel.reviewFilter.selectedCategories.isEmpty {
                                Text(viewModel.selectedFilterCategoriesSummary)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    } icon: {
                        Icon(name: "rectangle.grid.2x2.fill", background: true)
                        
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 4) {
                        if !viewModel.reviewFilter.selectedCategories.isEmpty {
                            Text("\(viewModel.reviewFilter.selectedCategories.count)")
                                .foregroundStyle(Color(.systemGray2))
                        }
                        
                        Icon(name: "chevron.right", color: Color(.systemGray2))
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
        }
        .foregroundStyle(.primary)
    }
    
    // MARK: - Mood Link
    
    private var moodLink: some View {
        NavigationLink {
            moodFilterView
        } label: {
            Card {
                HStack {
                    Label {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Mood")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.accent)
                            
                            if !viewModel.reviewFilter.selectedMoods.isEmpty {
                                Text(viewModel.selectedFilterMoodsSummary)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    } icon: {
                        Icon(name: "face.smiling.fill", background: true)
                        
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 4) {
                        if !viewModel.reviewFilter.selectedMoods.isEmpty {
                            Text("\(viewModel.reviewFilter.selectedMoods.count)")
                                .foregroundStyle(Color(.systemGray2))
                        }
                        
                        Icon(name: "chevron.right", color: Color(.systemGray2))
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
        }
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
        .background {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
        }
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
                        isSelected: viewModel.reviewFilter.selectedMoods.contains(mood) ,
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
        .background {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
        }
    }
    
    // MARK: Trigger Crash
    
    private var triggerCrash: some View {
        Card {
            Toggle(isOn: $viewModel.reviewFilter.triggeredCrash) {
                IconLabel(
                    icon: "bandage.fill",
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
        }
    }
}

// MARK: - Preview

#Preview {    
    let viewModel: HomeViewModel = ScenesContainer.shared.homeViewModel()
    
    ReviewsFilterView(viewModel: viewModel)
        .tint(Color("BrandPrimary"))
}
