import SwiftUI

struct ArticlesListView: View {
    @Bindable var viewModel: OutreachViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.isFetchingArticles {
                    ForEach(0..<3) { _ in
                        BlogArticleCell(article: .mockArticle)
                            .redacted(reason: .placeholder)
                            .disabled(true)
                            .accessibilityHidden(true)
                    }
                } else if viewModel.blogArticles.isEmpty {
                    EmptyStateView(
                        image: "newspaper",
                        title: viewModel.fetchErrorMessage == nil
                            ? String(localized: "No Articles Yet") : String(localized: "Unable to Load Articles"),
                        description: String(localized: "Check back for news and research from MindfulPacer."),
                        buttonTitle: String(localized: "Try Again"),
                        buttonAction: viewModel.onViewFirstAppear
                    )
                } else {
                    ForEach(viewModel.blogArticles) { article in
                        BlogArticleCell(article: article)
                    }
                }
            }
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
            .padding()
        }
        .navigationTitle("Articles")
        .background(Color(.systemGroupedBackground))
    }
}
