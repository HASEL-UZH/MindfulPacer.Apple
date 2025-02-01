//
//  OutreachViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 01.02.2025.
//

import Foundation

// MARK: - OutreachViewModel

@MainActor
@Observable
class OutreachViewModel {
    
    // MARK: - Dependencies
    
    private let fetchBlogArticlesUseCase: FetchBlogArticlesUseCase
    
    // MARK: - Published Properties
    
    var blogArticles: [BlogArticle] = []
    var isFetchingArticles: Bool = false
    var fetchErrorMessage: String?

    // MARK: - Initialization
    
    init(fetchBlogArticlesUseCase: FetchBlogArticlesUseCase) {
        self.fetchBlogArticlesUseCase = fetchBlogArticlesUseCase
    }
    
    // MARK: - View Lifecycle
    
    func onViewFirstAppear() {
        fetchBlogArticles()
    }
    
    // MARK: - Private Methods
    
    private func fetchBlogArticles() {
        let fetchBlogArticlesUseCase = self.fetchBlogArticlesUseCase
        
        Task { [weak self] in
            guard let self = self else { return }
            
            self.isFetchingArticles = true
            self.fetchErrorMessage = nil
            
            do {
                let articles = try await fetchBlogArticlesUseCase.execute(category: nil)
                self.blogArticles = articles
            } catch {
                self.fetchErrorMessage = "DEBUG: Failed to fetch articles. Please try again."
            }
            
            self.isFetchingArticles = false
        }
    }
}
