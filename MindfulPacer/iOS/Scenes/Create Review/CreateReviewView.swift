//
//  CreateReviewView.swift
//  iOS
//
//  Created by Grigor Dochev on 06.08.2024.
//

import SwiftUI
import SwiftData

// MARK: - Navigation

enum CreateReviewNavigationDestination: Hashable {
    case category
    case subcategory(Category?)
    case mood
}

// MARK: - Create Review

struct CreateReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.keyboardShowing) private var keyboardShowing
    @State var viewModel: CreateReviewViewModel = ScenesContainer.shared.createReviewViewModel()
    
    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            List {
                category
                mood
                triggeredCrashView
                ratings
                additionalInformation
            }
            .navigationTitle("Create Review")
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                createButton
            }
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    hideKeyboardButton
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onViewFirstAppear {
                viewModel.onViewFirstAppear()
            }
            .sheet(isPresented: $viewModel.isRatingSheetPresented, onDismiss: {
                viewModel.currentRatingType = nil
            }) {
                if let ratingType = viewModel.currentRatingType,
                   let rating = viewModel.ratings.first(where: { $0.type == ratingType }
                   ) {
                    RatingSelectionView(
                        rating: rating,
                        onRatingSelected: { value in
                            viewModel.updateRating(for: ratingType, with: value)
                        }
                    )
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                }
            }
            .navigationDestination(for: CreateReviewNavigationDestination.self) { destination in
                switch destination {
                case .category:
                    reviewCategoryView
                case .subcategory(let category):
                    reviewSubCategoryView(category.unsafelyUnwrapped)
                case .mood:
                    reviewMoodView
                }
            }
        }
    }
    
    private var category: some View {
        Section {
            NavigationLink(value: CreateReviewNavigationDestination.category) {
                HStack {
                    Label("Category", systemImage: "square.grid.2x2.fill")
                    Spacer()
                    if let selectedCategory = viewModel.selectedCategory {
                        Text(selectedCategory.name)
                            .foregroundStyle(.gray)
                    }
                }
            }
            
            if viewModel.selectedCategory.isNotNil {
                NavigationLink(value: CreateReviewNavigationDestination.subcategory(viewModel.selectedCategory)) {
                    HStack {
                        Label("Subcategory", systemImage: "rectangle.grid.3x3.fill")
                        Spacer()
                        if let selectedSubcategory = viewModel.selectedSubcategory {
                            Text(selectedSubcategory.name)
                                .foregroundStyle(.gray)
                        }
                    }
                }
            }
        }
    }
    
    private var mood: some View {
        Section {
            NavigationLink(value: CreateReviewNavigationDestination.mood) {
                HStack {
                    Label("Mood", systemImage: "face.smiling.inverse")
                    Spacer()
                    if let selectedMood = viewModel.selectedMood {
                        Text(selectedMood)
                    }
                }
            }
        }
    }
    
    private var ratings: some View {
        Section {
            ForEach(viewModel.ratings, id: \.type) { rating in
                Button {
                    viewModel.showRatingSheet(for: rating.type)
                } label: {
                    HStack {
                        Label {
                            Text(rating.type.name)
                                .foregroundStyle(Color.primary)
                        } icon: {
                            Image(systemName: rating.type.icon)
                        }
                        Spacer()
                        Text(rating.description)
                            .foregroundColor(rating.color)
                    }
                }
            }
        }
    }
    
    private var additionalInformation: some View {
        TextField("Additional information", text: $viewModel.additionalInformation, axis: .vertical)
    }
    
    private var createButton: some View {
        PrimaryButton(title: "Create") {
            viewModel.createReview()
            dismiss()
        }
        .padding(keyboardShowing ? [.all] : [.horizontal, .top])
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
    }
    
    private var hideKeyboardButton: some View {
        Button {
            hideKeyboard()
        } label: {
            Image(systemName: "keyboard.chevron.compact.down.fill")
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

// MARK: - Review Category

extension CreateReviewView {
    private var reviewCategoryView: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(spacing: 16), count: 3),
                spacing: 16
            ) {
                ForEach(viewModel.categories) { category in
                    SelectableButton(
                        shape: .roundedRectangle(cornerRadius: 16),
                        isSelected: viewModel.selectedCategory == category,
                        action: {
                            viewModel.selectCategory(category)
                        }) {
                            VStack(spacing: 16) {
                                Image(systemName: category.icon)
                                    .resizable()
                                    .scaledToFit()
                                    .symbolVariant(.fill)
                                    .frame(height: 32)
                                Text(category.name)
                                    .font(.subheadline)
                                    .lineLimit(1)
                            }
                        }
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Category")
        .background {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
        }
    }
}

// MARK: - Review Subcategory

extension CreateReviewView {
    @ViewBuilder
    private func reviewSubCategoryView(_ category: Category) -> some View {
        ScrollView {
            
        }
    }
}

// MARK: - Review Mood

extension CreateReviewView {
    private var reviewMoodView: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(spacing: 16), count: 5),
                spacing: 16
            ) {
                ForEach(viewModel.moods, id: \.self) { mood in
                    SelectableButton(
                        shape: .circle,
                        isSelected: viewModel.selectedMood == mood,
                        action: {
                            viewModel.selectMood(mood)
                        }) {
                            Text(mood)
                                .font(.title)
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
}

// MARK: - Review Crash Status

extension CreateReviewView {
    private var triggeredCrashView: some View {
        Section {
            Toggle(isOn: $viewModel.didTriggerCrash) {
                Label("Did this trigger a crash?", systemImage: "bandage.fill")
            }
            .tint(.accentColor)
        }
    }
}

// MARK: - Rating Selecion

fileprivate struct RatingSelectionView: View {
    let rating: ReviewMetricRating
    let onRatingSelected: (Int?) -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack(alignment: .leading, spacing: 16) {
                    GroupBox {
                        Label {
                            Text("How much this did affect you?")
                        } icon: {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .backgroundStyle(Color(.secondarySystemGroupedBackground))
                    
                    HStack(spacing: 16) {
                        ForEach(0 ..< 4, id: \.self) { index in
                            SelectableButton(
                                shape: .circle,
                                selectionColor: rating.color,
                                isSelected: rating.value == index,
                                action: {
                                    onRatingSelected(index)
                                }) {
                                    Text("\(index)")
                                        .fontWeight(.semibold)
                                }
                                .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(rating.type.name)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview

#Preview {
    let container = ModelContainer.preview
    let viewModel = CreateReviewViewModel(
        modelContext: container.mainContext,
        createReviewUseCase: UseCasesContainer.shared.createReviewUseCase(),
        fetchDefaultCategoriesUseCase: UseCasesContainer.shared.fetchDefaultCategoriesUseCase()
    )
    
    return CreateReviewView(viewModel: viewModel)
        .modelContainer(container)
        .tint(Color("PrimaryGreen"))
}
