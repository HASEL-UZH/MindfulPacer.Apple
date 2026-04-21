//
//  BlogRepository.swift
//  iOS
//
//  Created by Grigor Dochev on 01.02.2025.
//

import Foundation

// MARK: - BlogRepository

protocol BlogRepository: Sendable {
    func getBlogArticles() async throws -> [BlogArticle]
}

// MARK: - DefaultBlogRepository

final class DefaultBlogRepository: BlogRepository, Sendable {
    private let blogService: any BlogServiceProtocol

    init(blogService: any BlogServiceProtocol) {
        self.blogService = blogService
    }

    func getBlogArticles() async throws -> [BlogArticle] {
        return try await blogService.fetchBlogArticles()
    }
}
