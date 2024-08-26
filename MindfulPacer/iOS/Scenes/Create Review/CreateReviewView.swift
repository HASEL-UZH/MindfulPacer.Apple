//
//  CreateReviewView.swift
//  iOS
//
//  Created by Grigor Dochev on 06.08.2024.
//

import SwiftUI
import SwiftData

// MARK: - Navigation Enums

enum CreateReviewNavigationDestination: Hashable {
    case category
    case subcategory(Category?)
    case mood
}

enum CreateReviewSheet: Identifiable {
    case ratingSheet
    
    var id: Int {
        hashValue
    }
}

// MARK: - CreateReviewView

struct CreateReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.keyboardShowing) private var keyboardShowing
    @State var viewModel: CreateReviewViewModel = ScenesContainer.shared.createReviewViewModel()
    
    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            List {
                date
                category
                mood
                ratings
                triggeredCrashView
                additionalInformation
            }
            .navigationTitle("Create Review")
            .safeAreaInset(edge: .bottom) {
                createButton
            }
            .scrollDismissesKeyboard(.interactively)
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
            .alert(item: $viewModel.alertItem) { $0.alert }
            .sheet(item: $viewModel.activeSheet) { sheet in
                switch sheet {
                case .ratingSheet:
                    if let ratingType = viewModel.currentRatingType,
                       let rating = viewModel.ratings.first(where: { $0.type == ratingType }
                       ) {
                        RatingSelectionView(
                            rating: rating,
                            onRatingSelected: { value in
                                viewModel.setRating(for: ratingType, with: value)
                            }
                        )
                        .presentationDetents([.height(220)])
                        .presentationDragIndicator(.visible)
                    }
                }
            }
            .navigationDestination(for: CreateReviewNavigationDestination.self) { destination in
                switch destination {
                case .category:
                    ReviewCategoryView(viewModel: viewModel)
                case .subcategory(let category):
                    ReviewSubcategoryView(
                        viewModel: viewModel,
                        category: category.unsafelyUnwrapped
                    )
                case .mood:
                    ReviewMoodView(viewModel: viewModel)
                }
            }
        }
    }
    
    private var date: some View {
        Section {
            DatePicker(selection: $viewModel.date) {
                SFSymbolLabel(
                    icon: "calendar",
                    title: "Date",
                    iconColor: Color("BrandPrimary")
                )
            }
        }
    }
    
    private var category: some View {
        Section {
            NavigationLink(value: CreateReviewNavigationDestination.category) {
                HStack {
                    SFSymbolLabel(
                        icon: "square.grid.2x2.fill",
                        title: "Category",
                        iconColor: Color("BrandPrimary")
                    )
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
                        SFSymbolLabel(
                            icon: "rectangle.grid.3x3.fill",
                            title: "Subcategory",
                            iconColor: Color("BrandPrimary")
                        )
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
                    SFSymbolLabel(
                        icon: "face.smiling.inverse",
                        title: "Mood",
                        iconColor: Color("BrandPrimary")
                    )
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
                    viewModel.presentRatingSheet(for: rating.type)
                } label: {
                    HStack {
                        SFSymbolLabel(
                            icon: rating.type.icon,
                            title: rating.type.name,
                            iconColor: Color("BrandPrimary")
                        )
                        Spacer()
                        Text(rating.description)
                            .foregroundColor(rating.color)
                    }
                }
            }
        }
    }
    
    private var triggeredCrashView: some View {
        Section {
            Toggle(isOn: $viewModel.didTriggerCrash) {
                Label("Did this trigger a crash?", systemImage: "bandage.fill")
            }
            .tint(.accentColor)
        }
    }
    
    private var additionalInformation: some View {
        TextField("Additional information", text: $viewModel.additionalInformation, axis: .vertical)
    }
    
    private var createButton: some View {
        PrimaryButton(title: "Create") {
            viewModel.saveReview()
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

// MARK: - Preview

#Preview {
    let container = ModelContainer.preview
    let viewModel = ScenesContainer.shared.createReviewViewModel()
    
    return CreateReviewView(viewModel: viewModel)
        .modelContainer(container)
        .tint(Color("BrandPrimary"))
}
