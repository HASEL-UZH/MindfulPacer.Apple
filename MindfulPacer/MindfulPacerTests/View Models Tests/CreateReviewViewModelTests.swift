//
//  CreateReviewViewModelTests.swift
//  MindfulPacerTests
//
//  Created by Grigor Dochev on 25.08.2024.
//

import Foundation
import SwiftData
import XCTest

@testable import iOS

class CreateReviewViewModelTests: XCTestCase {
    var viewModel: CreateReviewViewModel!
    var mockCreateReviewUseCase: MockCreateReviewUseCase!
    var mockFetchDefaultCategoriesUseCase: MockFetchDefaultCategoriesUseCase!
    var mockModelContext: ModelContext!
    
    @MainActor
    override func setUp() {
        super.setUp()
        mockCreateReviewUseCase = MockCreateReviewUseCase()
        mockFetchDefaultCategoriesUseCase = MockFetchDefaultCategoriesUseCase()
        mockModelContext = ModelContainer.testing.mainContext
        
        viewModel = CreateReviewViewModel(
            modelContext: mockModelContext,
            createReviewUseCase: mockCreateReviewUseCase,
            fetchDefaultCategoriesUseCase: mockFetchDefaultCategoriesUseCase
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockCreateReviewUseCase = nil
        mockFetchDefaultCategoriesUseCase = nil
        super.tearDown()
    }
    
    @MainActor
    func testInitialization() {
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.categories.count, 0)
        XCTAssertNil(viewModel.selectedCategory)
        XCTAssertNil(viewModel.activeSheet)
    }
    
    @MainActor
    func testOnViewFirstAppearFetchesCategories() {
        // Arrange
        let expectedCategories = [iOS.Category(name: "Category1"), iOS.Category(name: "Category2")]
        mockFetchDefaultCategoriesUseCase.categoriesToReturn = expectedCategories
        
        // Act
        viewModel.onViewFirstAppear()
        
        // Assert
        XCTAssertEqual(viewModel.categories.count, expectedCategories.count)
        XCTAssertEqual(viewModel.categories.first?.name, "Category1")
    }
    
    @MainActor
    func testToggleSelection() {
        // Arrange
        let category = iOS.Category(name: "TestCategory")
        viewModel.selectedCategory = nil
        
        // Act
        viewModel.toggleSelection(category, selectedItem: &viewModel.selectedCategory)
        
        // Assert
        XCTAssertEqual(viewModel.selectedCategory?.name, "TestCategory")
        
        // Act
        viewModel.toggleSelection(category, selectedItem: &viewModel.selectedCategory)
        
        // Assert
        XCTAssertNil(viewModel.selectedCategory)
    }
    
    @MainActor
    func testSetRating() {
        // Arrange
        let type = ReviewMetricRatingType.headaches
        let value = 3
        
        // Act
        viewModel.setRating(for: type, with: value)
        
        // Assert
        XCTAssertEqual(viewModel.ratings.first(where: { $0.type == type })?.value, value)
        
        // Act
        viewModel.setRating(for: type, with: value)
        
        // Assert
        XCTAssertNil(viewModel.ratings.first(where: { $0.type == type })?.value)
    }
    
    @MainActor
    func testSaveReviewSuccess() {
        // Arrange
        mockCreateReviewUseCase.executeResult = .success(iOS.Review())
        
        // Act
        viewModel.saveReview()
        
        // Assert
        XCTAssertNil(viewModel.alertItem)
    }
    
    @MainActor
    func testSaveReviewFailure() {
        // Arrange
        mockCreateReviewUseCase.executeResult = .failure(NSError(domain: "Test", code: 1, userInfo: nil))
        
        // Act
        viewModel.saveReview()
        
        // Assert
        XCTAssertEqual(viewModel.alertItem, AlertContext.unableToSaveReview)
    }
}
