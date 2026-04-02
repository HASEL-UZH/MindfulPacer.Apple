//
//  OutreachViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 01.02.2025.
//

import Foundation
import MessageUI

// MARK: - OutreachViewModel

@MainActor
@Observable
class OutreachViewModel {
    
    // MARK: - Dependencies
    
    nonisolated(unsafe) private let fetchBlogArticlesUseCase: FetchBlogArticlesUseCase
    
    // MARK: - Published Properties
    
    var activeSheet: OutreachSheet?

    var blogArticles: [BlogArticle] = []
    var recentArticles: [BlogArticle] = []
    var isFetchingArticles: Bool = false
    var fetchErrorMessage: String?
    var mailResult: Result<MFMailComposeResult, Error>?

    var contactSupportRecipient: String = "support@mindfulpacer.ch"
    var contactSupportSubject: String = "MindfulPacer - Feedback"
    
    var isGermanLanguage: Bool {
        Locale.current.language.languageCode?.identifier == "de"
    }
    
    // MARK: - Initialization
    
    init(fetchBlogArticlesUseCase: FetchBlogArticlesUseCase) {
        self.fetchBlogArticlesUseCase = fetchBlogArticlesUseCase
    }
    
    // MARK: - View Lifecycle
    
    func onViewFirstAppear() {
        fetchBlogArticles()
    }
    
    // MARK: - Presentation
    
    func presentSheet(_ sheet: OutreachSheet) {
        activeSheet = sheet
    }
    
    // MARK: - Private Methods
    
    private func fetchBlogArticles() {
        isFetchingArticles = true
        fetchErrorMessage = nil

        Task {
            do {
                let articles = try await fetchBlogArticlesUseCase.execute(category: nil)
                blogArticles = articles
                recentArticles = Array(blogArticles.prefix(2))
            } catch {
                fetchErrorMessage = "DEBUG: Failed to fetch articles. Please try again."
            }
            isFetchingArticles = false
        }
    }
}
