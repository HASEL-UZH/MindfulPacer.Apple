//
//  BlogRepository.swift
//  iOS
//
//  Created by Grigor Dochev on 01.02.2025.
//

import Foundation

// MARK: - BlogRepository

protocol BlogRepository {
    func getBlogArticles() async throws -> [BlogArticle]
}

// MARK: - DefaultBlogRepository

class DefaultBlogRepository: BlogRepository {
    private let blogService: BlogServiceProtocol

    init(blogService: BlogServiceProtocol) {
        self.blogService = blogService
    }

    func getBlogArticles() async throws -> [BlogArticle] {
        return try await blogService.fetchBlogArticles()
    }
}
