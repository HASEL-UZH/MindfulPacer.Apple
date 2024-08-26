//
//  MockFetchDefaultCategoriesUseCase.swift
//  MindfulPacerTests
//
//  Created by Grigor Dochev on 25.08.2024.
//

import Foundation
import SwiftData
@testable import iOS

class MockFetchDefaultCategoriesUseCase: FetchDefaultCategoriesUseCase {
    var categoriesToReturn: [iOS.Category]? = []

    func execute() -> [iOS.Category]? {
        return categoriesToReturn
    }
}
