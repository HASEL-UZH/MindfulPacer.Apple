//
//  ArticlesListView.swift
//  iOS
//
//  Created by Grigor Dochev on 03.02.2025.
//

import SwiftUI

// MARK: - ArticlesListView

struct ArticlesListView: View {
    
    // MARK: Properties
    
    @Environment(\.openURL) private var openURL
    @Bindable var viewModel: OutreachViewModel
    
    // MARK: Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.isFetchingArticles {
                    ForEach(0 ..< 5) { _ in
                        BlogArticleCell(article: BlogArticle.mockArticle, cardColor: Color(.secondarySystemGroupedBackground))
                            .redacted(reason: .placeholder)
                    }
                } else {
                    ForEach(viewModel.blogArticles) { article in
                        Button {
                            openURL(article.link)
                        } label: {
                            BlogArticleCell(
                                article: article,
                                cardColor: Color(.secondarySystemGroupedBackground)
                            )
                        }
                    }
                }
            }
            .padding([.horizontal, .bottom])
        }
        .navigationTitle("Articles")
        .background {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: OutreachViewModel = ScenesContainer.shared.outreachViewModel()
    
    ArticlesListView(viewModel: viewModel)
}
