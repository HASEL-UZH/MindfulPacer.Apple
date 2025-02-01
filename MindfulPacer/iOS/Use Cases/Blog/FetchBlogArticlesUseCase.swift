//
//  FetchBlogArticlesUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 01.02.2025.
//

import Foundation

// MARK: - FetchBlogArticlesUseCase Protocol

protocol FetchBlogArticlesUseCase {
    func execute(category: BlogCategory?) async throws -> [BlogArticle]
}

// MARK: - Use Case Implementation

class DefaultFetchBlogArticlesUseCase: FetchBlogArticlesUseCase {
    private let repository: BlogRepository

    init(repository: BlogRepository) {
        self.repository = repository
    }

    func execute(category: BlogCategory? = nil) async throws -> [BlogArticle] {
        let articles = try await repository.getBlogArticles()
        
        if let category = category {
            return articles.filter { $0.category == category }
        }
        
        return articles
    }
}
