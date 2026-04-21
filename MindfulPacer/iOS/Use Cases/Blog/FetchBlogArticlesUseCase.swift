//
//  FetchBlogArticlesUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 01.02.2025.
//

import Foundation

// MARK: - FetchBlogArticlesUseCase Protocol

protocol FetchBlogArticlesUseCase: Sendable {
    func execute(category: BlogCategory?) async throws -> [BlogArticle]
}

// MARK: - Use Case Implementation

final class DefaultFetchBlogArticlesUseCase: FetchBlogArticlesUseCase, Sendable {
    private let repository: BlogRepository

    init(repository: BlogRepository) {
        self.repository = repository
    }

    func execute(category: BlogCategory? = nil) async throws -> [BlogArticle] {
        let articles = try await repository.getBlogArticles()

        let filteredArticles: [BlogArticle]
        
        if let category = category {
            filteredArticles = articles.filter { $0.categories.contains(category) }
        } else {
            filteredArticles = articles
        }

        print("DEBUGY:", filteredArticles.map { $0.imageURL?.absoluteString })
        return filteredArticles.sorted { $0.publicationDate > $1.publicationDate }
    }
}
