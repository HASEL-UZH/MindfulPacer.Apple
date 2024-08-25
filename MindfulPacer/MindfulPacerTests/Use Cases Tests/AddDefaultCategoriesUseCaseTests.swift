//
//  AddDefaultCategoriesUseCaseTests.swift
//  MindfulPacerTests
//
//  Created by Grigor Dochev on 25.08.2024.
//

import Foundation
import SwiftData
import XCTest

@testable import iOS
class AddDefaultCategoriesUseCaseTests: XCTestCase {
    var useCase: DefaultAddDefaultCategoriesUseCase!
    var mockModelContext: ModelContext!
    
    @MainActor
    override func setUp() {
        super.setUp()
        mockModelContext = ModelContainer.testing.mainContext
        useCase = DefaultAddDefaultCategoriesUseCase(modelContext: mockModelContext)
    }
    
    override func tearDown() {
        useCase = nil
        mockModelContext = nil
        super.tearDown()
    }
    
    @MainActor
    func testExecute_addsDefaultCategoriesWhenNoneExist() async {
        await useCase.execute()
        
        var categories: [iOS.Category] = []
        let descriptor = FetchDescriptor<iOS.Category>()
        do {
            categories = try mockModelContext.fetch(descriptor)
        } catch {
            
        }
        
        XCTAssertEqual(categories.count, DefaultCategoryData.categories.count)
    }
    
//    func testExecute_doesNotAddCategoriesIfTheyAlreadyExist() async {
//        // Assume categories already exist
//        mockModelContext.insertedObjects = DefaultCategoryData.categories
//        await useCase.execute()
//        XCTAssertEqual(mockModelContext.insertedObjects.count, DefaultCategoryData.categories.count) // Should not increase
//    }
}
