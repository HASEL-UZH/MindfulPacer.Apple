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
    
    // MARK: Body
    
    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        date
                        category
                        
                        if viewModel.selectedCategory.isNotNil {
                            subcategory
                        }
                        
                        mood
                        ratings(width: proxy.size.width / 2)
                        triggerCrash
                        additionalInformation
                            .padding(.bottom)
                    }
                    .padding(.horizontal)
                }
            }
            .foregroundStyle(Color.primary)
            .scrollContentBackground(.hidden)
            .background {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
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
                        .presentationCornerRadius(16)
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
    
    // MARK: Date
    
    private var date: some View {
        DatePicker(selection: $viewModel.date) {
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
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .foregroundStyle(Color(.secondarySystemGroupedBackground))
        }
    }
    
    // MARK: Category
    
    private var category: some View {
        NavigationLink(value: CreateReviewNavigationDestination.category) {
            HStack {
                IconLabel(
                    icon: "rectangle.grid.2x2.fill",
                    title: "Category",
                    labelColor: Color("BrandPrimary"),
                    background: true
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .layoutPriority(1)
                
                Spacer()
                
                HStack(spacing: 4) {
                    if let category = viewModel.selectedCategory {
                        Text(category.name)
                            .foregroundStyle(Color(.systemGray2))
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    
                    Icon(name: "chevron.right", color: Color(.systemGray2))
                        .font(.subheadline.weight(.semibold))
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .foregroundStyle(Color(.secondarySystemGroupedBackground))
            }
        }
    }
    
    // MARK: Subcategory
    
    private var subcategory: some View {
        NavigationLink(value: CreateReviewNavigationDestination.subcategory(viewModel.selectedCategory)) {
            HStack {
                IconLabel(
                    icon: "rectangle.grid.3x3.fill",
                    title: "Subcategory",
                    labelColor: Color("BrandPrimary"),
                    background: true
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .layoutPriority(1)
                
                Spacer()
                
                HStack(spacing: 4) {
                    if let subcategory = viewModel.selectedSubcategory {
                        Text(subcategory.name)
                            .foregroundStyle(Color(.systemGray2))
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    
                    Icon(name: "chevron.right", color: Color(.systemGray2))
                        .font(.subheadline.weight(.semibold))
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .foregroundStyle(Color(.secondarySystemGroupedBackground))
            }
        }
    }
    
    // MARK: Mood
    
    private var mood: some View {
        NavigationLink(value: CreateReviewNavigationDestination.mood) {
            HStack {
                IconLabel(
                    icon: "face.smiling.fill",
                    title: "Mood",
                    labelColor: Color("BrandPrimary"),
                    background: true
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .layoutPriority(1)
                
                Spacer()
                
                HStack(spacing: 4) {
                    if let mood = viewModel.selectedMood {
                        Text(mood.emoji)
                            .frame(width: 24, height: 24)
                    }
                    
                    Icon(name: "chevron.right", color: Color(.systemGray2))
                        .font(.subheadline.weight(.semibold))
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .foregroundStyle(Color(.secondarySystemGroupedBackground))
            }
        }
    }
    
    // MARK: Ratings
    
    @ViewBuilder private func ratings(width: CGFloat) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(spacing: 16), count: 2),
            spacing: 16
        ) {
            ForEach(viewModel.ratings, id: \.type) { rating in
                Button {
                    viewModel.presentRatingSheet(for: rating.type)
                } label: {
                    IconLabelGroupBox(
                        label: IconLabel(
                            icon: rating.type.icon,
                            title: rating.type.name,
                            labelColor: Color("BrandPrimary"),
                            background: true,
                            axis: .vertical
                        )
                    ) {
                        Text(rating.description)
                            .foregroundColor(rating.description == "Not Set" ? .secondary : rating.color)
                    }
                }
                .frame(maxWidth: width)
            }
        }
    }
    
    // MARK: Trigger Crash
    
    private var triggerCrash: some View {
        Toggle(isOn: $viewModel.didTriggerCrash) {
            IconLabel(
                icon: "bandage.fill",
                title: "Did this trigger a crash?",
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
        .background {
            RoundedRectangle(cornerRadius: 16)
                .foregroundStyle(Color(.secondarySystemGroupedBackground))
        }
    }
    
    // MARK: Additional Information
    
    private var additionalInformation: some View {
        IconLabelGroupBox(
            label: IconLabel(
                icon: "pencil.line",
                title: "Additional Information",
                labelColor: Color("BrandPrimary"),
                background: true
            )
        ) {
            TextField("You can write anything here", text: $viewModel.additionalInformation, axis: .vertical)
        }
    }
    
    // MARK: Create Button
    
    private var createButton: some View {
        PrimaryButton(title: "Create") {
            viewModel.saveReview()
            dismiss()
        }
        .padding(keyboardShowing ? [.all] : [.horizontal, .top])
        .background(.ultraThinMaterial)
        .disabled(viewModel.isCreateButtonDisabled)
        .overlay(alignment: .top) {
            Divider()
        }
    }
    
    // MARK: Hide Keyboard Button
    
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
