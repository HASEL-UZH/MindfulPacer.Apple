import SwiftUI
import Kingfisher

enum OutreachSheet: Identifiable {
    case mailView(recipient: String, subject: String, body: String?)
    case roadmap

    var id: Int {
        switch self {
        case .mailView: 0
        case .roadmap: 1
        }
    }
}

enum OutreachViewNavigationDestination: Hashable {
    case articlesList
}

struct OutreachView: View {
    @State private var viewModel: OutreachViewModel = ScenesContainer.shared.outreachViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    articles
                    community
                    learnMore
                }
                .frame(maxWidth: 680)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Outreach")
            .navigationDestination(for: OutreachViewNavigationDestination.self) { _ in
                ArticlesListView(viewModel: viewModel)
            }
            .sheet(item: $viewModel.activeSheet, content: sheetContent)
        }
        .onViewFirstAppear { viewModel.onViewFirstAppear() }
    }

    private var articles: some View {
        LabeledCard(contentSpacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                if viewModel.isFetchingArticles {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 180)
                } else if let article = viewModel.recentArticles.first {
                    featuredArticle(article)
                    ForEach(viewModel.recentArticles.dropFirst()) { article in
                        Divider()
                        Link(destination: article.link) {
                            HStack(alignment: .top, spacing: 16) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(article.title)
                                        .font(.headline)
                                        .foregroundStyle(Color.primary)
                                    Text(article.publicationDate, format: .dateTime.day().month(.abbreviated).year())
                                        .font(.caption).foregroundStyle(Color.secondary)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "arrow.up.right")
                                    .font(.subheadline).foregroundStyle(Color.secondary)
                                    .accessibilityHidden(true)
                            }
                            .padding(.top, 4)
                            .contentShape(.rect)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(viewModel.fetchErrorMessage == nil
                             ? String(localized: "No Articles Yet") : String(localized: "Unable to Load Articles"))
                            .font(.headline)
                        Text("Check back for news and research from MindfulPacer.")
                            .foregroundStyle(Color.secondary)
                        Button("Try Again", systemImage: "arrow.clockwise", action: viewModel.onViewFirstAppear)
                            .buttonStyle(.glass)
                            .buttonBorderShape(.capsule)
                            .controlSize(.regular)
                    }
                    .font(.subheadline)
                    .padding(.top, 8)
                }
            }
        } label: {
            Label("Articles", systemImage: "newspaper")
                .foregroundStyle(Color.accentColor)
        } accessory: {
            NavigationLink(value: OutreachViewNavigationDestination.articlesList) {
                HStack(spacing: 4) {
                    Text("Show All")
                    Image(systemName: "chevron.right").accessibilityHidden(true)
                }
                .font(.subheadline)
            }
        }
    }

    private func featuredArticle(_ article: BlogArticle) -> some View {
        Link(destination: article.link) {
            VStack(alignment: .leading, spacing: 8) {
                if let imageURL = article.imageURL {
                    Rectangle()
                        .fill(Color.brandPrimary.opacity(0.08))
                        .frame(height: 190)
                        .overlay {
                            KFImage(imageURL)
                                .placeholder {
                                    Image(systemName: "newspaper")
                                        .font(.largeTitle).foregroundStyle(Color.brandPrimary)
                                }
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                        .clipShape(.rect(cornerRadius: 24))
                        .accessibilityHidden(true)
                }
                Text(article.publicationDate, format: .dateTime.day().month(.wide).year())
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.secondary)
                Text(article.title)
                    .font(.title2.bold())
                    .foregroundStyle(Color.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(article.excerpt)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(3)
                Label("Read Full Article", systemImage: "arrow.up.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
    }

    private var community: some View {
        LabeledCard(contentSpacing: 8) {
            Text("Discuss pacing strategies and insights with the community.")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)

            VStack(spacing: 0) {
                Link(destination: URL(string: "https://www.mindfulpacer.ch/lcs-de")!) {
                    resourceRow("Long Covid Schweiz", systemImage: "person.2", accessory: "arrow.up.right")
                }
                Divider().padding(.leading, 32)
                Link(destination: URL(string: "https://www.mindfulpacer.ch/lcs-kids-de")!) {
                    resourceRow("Long Covid Kids Schweiz", systemImage: "figure.2.and.child.holdinghands", accessory: "arrow.up.right")
                }
            }
            // The rows already provide a 44-point touch target, including bottom space.
            .padding(.bottom, -8)
        } label: {
            Label("Community", systemImage: "person.2")
                .foregroundStyle(Color.accentColor)
        }
    }

    private var learnMore: some View {
        LabeledCard(contentSpacing: 8) {
            VStack(spacing: 0) {
                Link(destination: URL(string: "https://mindfulpacer.ch")!) {
                    resourceRow("Our Website", systemImage: "globe", accessory: "arrow.up.right")
                }
                Divider().padding(.leading, 32)
                Button { viewModel.presentSheet(.roadmap) } label: {
                    resourceRow("Roadmap", systemImage: "map", accessory: "chevron.right")
                }
                Divider().padding(.leading, 32)
                Button {
                    viewModel.presentSheet(.mailView(
                        recipient: viewModel.contactSupportRecipient,
                        subject: viewModel.contactSupportSubject,
                        body: nil
                    ))
                } label: {
                    resourceRow("Contact Us", systemImage: "envelope", accessory: "chevron.right")
                }
            }
            // The rows already provide a 44-point touch target, including bottom space.
            .padding(.bottom, -8)
        } label: {
            Label("Learn More", systemImage: "info.circle")
                .foregroundStyle(Color.accentColor)
        }
    }

    private func resourceRow(_ title: LocalizedStringKey, systemImage: String, accessory: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(Color.accentColor)
                .frame(width: 20)
                .accessibilityHidden(true)
            Text(title)
                .font(.body)
                .foregroundStyle(Color.accentColor)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: accessory)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary)
                .accessibilityHidden(true)
        }
        .frame(minHeight: 44)
        .contentShape(.rect)
    }

    @ViewBuilder
    private func sheetContent(for sheet: OutreachSheet) -> some View {
        switch sheet {
        case .mailView(let recipient, let subject, let body):
            MailView(result: $viewModel.mailResult, recipient: recipient, subject: subject, body: body)
        case .roadmap:
            RoadmapView()
                .presentationDragIndicator(.visible)
        }
    }
}

#Preview { OutreachView() }
