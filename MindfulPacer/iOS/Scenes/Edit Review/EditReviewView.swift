//
//  EditReviewView.swift
//  iOS
//
//  Created by Grigor Dochev on 06.08.2024.
//

import SwiftUI

// MARK: - Presentation Enums

enum EditReviewNavigationDestination: Hashable {
    case category
    case subcategory(Category?)
    case mood
}

enum EditReviewSheet: Identifiable {
    case ratingSheet
    
    var id: Int {
        hashValue
    }
}

enum EditReviewAlert: Identifiable {
    case deleteConfirmation
    case unableToSaveReview
    
    var id: Int {
        hashValue
    }
}

// MARK: - EditReviewView

struct EditReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.keyboardShowing) private var keyboardShowing
    @State var viewModel: EditReviewViewModel = ScenesContainer.shared.editReviewViewModel()
    
    var review: Review?
        
    // MARK: Body
    
    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        date
                                                
                        VStack(spacing: 0) {
                            category
                            if viewModel.selectedCategory.isNotNil {
                                Divider()
                                subcategory
                            }
                        }
                        
                        mood
                        ratings(width: proxy.size.width / 2)
                        triggerCrash
                        additionalInformation
                        
                        if !viewModel.isReviewDeleted {
                            reviewReminder
                        }
                        
                        if viewModel.mode == .edit {
                            deleteButton
                        }
                    }
                    .padding(.horizontal)
                }
                .safeAreaPadding(.bottom)
            }
            .foregroundStyle(Color.primary)
            .scrollContentBackground(.hidden)
            .background {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
            }
            .navigationTitle(viewModel.navigationTitle)
            .safeAreaInset(edge: .bottom) {
                if viewModel.mode == .create {
                    createButton
                }
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
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.mode == .edit {
                        Button("Save") {
                            viewModel.saveReview(review)
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .onViewFirstAppear {
                viewModel.onViewFirstAppear()
                viewModel.configureMode(with: review)
            }
            .alert(item: $viewModel.activeAlert) { alert in
                alertContent(for: alert)
            }
            .sheet(item: $viewModel.activeSheet) { sheet in
                sheetContent(for: sheet)
            }
            .navigationDestination(for: EditReviewNavigationDestination.self) { destination in
                navigationDestination(for: destination)
            }
        }
    }
    
    // MARK: Alert Content
    
    private func alertContent(for alert: EditReviewAlert) -> Alert {
        switch alert {
        case .deleteConfirmation:
            return reviewDeletionConfirmationAlert
        case .unableToSaveReview:
            return unableToSaveReviewAlert
        }
    }
    
    // MARK: Sheet Content
    
    @ViewBuilder
    private func sheetContent(for sheet: EditReviewSheet) -> some View {
        switch sheet {
        case .ratingSheet:
            if let ratingType = viewModel.currentRatingType,
               let rating = viewModel.ratings.first(where: { $0.type == ratingType }) {
                
                RatingSelectionView(
                    rating: rating,
                    onRatingSelected: { value in
                        viewModel.setRating(for: ratingType, with: value)
                    }
                )
                .presentationDetents([.height(220)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(16)
            } else {
                AnyView(EmptyView())
            }
        }
    }
    
    // MARK: Navigation Destination
    
    @ViewBuilder
    private func navigationDestination(for destination: EditReviewNavigationDestination) -> some View {
        switch destination {
        case .category:
            CategoryView(viewModel: viewModel)
        case .subcategory(let category):
            SubcategoryView(
                category: category.unsafelyUnwrapped,
                viewModel: viewModel
            )
        case .mood:
            MoodView(viewModel: viewModel)
        }
    }
    
    // MARK: Date
    
    private var date: some View {
        Card {
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
        }
    }
    
    // MARK: Category
    
    private var category: some View {
        NavigationLink(value: EditReviewNavigationDestination.category) {
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
                
                Spacer(minLength: 16)
                
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
                if viewModel.selectedCategory.isNil {
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundStyle(Color(.secondarySystemGroupedBackground))
                } else {
                    UnevenRoundedRectangle(cornerRadii: .init(topLeading: 16, topTrailing: 16))
                        .foregroundStyle(Color(.secondarySystemGroupedBackground))
                }
            }
        }
    }
    
    // MARK: Subcategory
    
    private var subcategory: some View {
        NavigationLink(value: EditReviewNavigationDestination.subcategory(viewModel.selectedCategory)) {
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
                
                Spacer(minLength: 16)
                
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
                UnevenRoundedRectangle(cornerRadii: .init(bottomLeading: 16, bottomTrailing: 16))
                    .foregroundStyle(Color(.secondarySystemGroupedBackground))
            }
        }
    }
    
    // MARK: Mood
    
    private var mood: some View {
        NavigationLink(value: EditReviewNavigationDestination.mood) {
            Card {
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
                            .foregroundColor(rating.description == "Not Set" ? Color(.systemGray2) : rating.color)
                    }
                }
                .frame(maxWidth: width)
            }
        }
    }
    
    // MARK: Trigger Crash
    
    private var triggerCrash: some View {
        Card {
            Toggle(isOn: $viewModel.didTriggerCrash) {
                IconLabel(
                    icon: "exclamationmark.triangle.fill",
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
    
    // MARK: - Review Reminder
    
    @ViewBuilder
    private var reviewReminder: some View {
        if let review = review {
            if let reviewReminder = review.reviewReminder {
                IconLabelGroupBox(
                    label: IconLabel(
                        icon: "alarm",
                        title: "Review Reminder",
                        labelColor: Color("BrandPrimary"),
                        background: true
                    ),
                    description: Text("The review reminder that triggered this review.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                ) {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            IconLabel(
                                icon: reviewReminder.measurementType.icon,
                                title: reviewReminder.measurementType.rawValue,
                                labelColor: reviewReminder.measurementType == .heartRate ? .pink : .teal
                            )
                            .font(.subheadline.weight(.semibold))
                            
                            Text(reviewReminder.triggerSummary)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Icon(
                            name: "alarm",
                            color: reviewReminder.reviewReminderType.color,
                            background: true
                        )
                    }
                    .foregroundStyle(Color.primary)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .foregroundStyle(Color(.tertiarySystemGroupedBackground))
                    }
                }
                .iconLabelGroupBoxStyle(.divider)
            } else {
                manualReview
            }
        } else {
            manualReview
        }
    }
    
    // MARK: Manual Review
    
    private var manualReview: some View {
        Card(backgroundColor: Color(.tertiarySystemFill)) {
            IconLabel(
                icon: "person",
                title: "Manually Created Review",
                labelColor: .secondary,
                background: true
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .layoutPriority(1)
        }
    }
    
    // MARK: Create Button
    
    private var createButton: some View {
        PrimaryButton(title: "Create") {
            viewModel.createReview()
            dismiss()
            // TODO: Show a toast when a Review is successfully created
        }
        .padding(keyboardShowing ? [.all] : [.horizontal, .top])
        .background(.ultraThinMaterial)
        .disabled(viewModel.isActionButtonDisabled)
        .overlay(alignment: .top) {
            Divider()
        }
    }
    
    // MARK: Delete Button
    
    private var deleteButton: some View {
        PrimaryButton(
            title: "Delete Review",
            icon: "trash",
            color: .red
        ) {
            viewModel.presentAlert(.deleteConfirmation)
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
    
    // MARK: Review Deletion Confirmation Alert
    
    private var reviewDeletionConfirmationAlert: Alert {
        Alert(
            title: Text("Delete Review"),
            message: Text("Are you sure you want to delete this review? This action cannot be undone."),
            primaryButton: .destructive(Text("Delete")) {
                viewModel.deleteReview(review)
                dismiss()
            },
            secondaryButton: .cancel()
        )
    }
    
    // MARK: - Unable to Save Review Alert
    
    private var unableToSaveReviewAlert: Alert {
        Alert(
            title: Text("Save Error"),
            message: Text("Unable to save your Review.\nPlease try again.\nIf this problem persists, please contact us."),
            dismissButton: .default(Text("Ok"))
        )
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.editReviewViewModel()
    
    return EditReviewView(viewModel: viewModel)
        .tint(Color("BrandPrimary"))
}
