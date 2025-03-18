//
//  OutreachView.swift
//  iOS
//
//  Created by Grigor Dochev on 01.02.2025.
//

import SwiftUI

// MARK: - Presentation Enums

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

// MARK: - OutreachView

struct OutreachView: View {
    
    // MARK: Properties
    
    @Environment(\.openURL) private var openURL
    @State private var viewModel: OutreachViewModel = ScenesContainer.shared.outreachViewModel()
    
    // MARK: Body
    
    var body: some View {
        NavigationStack {
            RoundedList {
                Section {
                    intro
                }
                
                Section {
                    community
                }
                
                Section {
                    articles
                }
                
                Section {
                    website
                    roadmap
                    contactUs
                } header: {
                    Text("Learn More")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Outreach")
            .navigationDestination(
                for: OutreachViewNavigationDestination.self,
                destination: navigationDestination
            )
            .sheet(item: $viewModel.activeSheet) { sheet in
                sheetContent(for: sheet)
            }
        }
        .onViewFirstAppear {
            viewModel.onViewFirstAppear()
        }
    }
    
    // MARK: Navigation Destination
    
    @ViewBuilder
    private func navigationDestination(for destination: OutreachViewNavigationDestination) -> some View {
        switch destination {
        case .articlesList:
            ArticlesListView(viewModel: viewModel)
        }
    }
    
    // MARK: Sheets

    @ViewBuilder
    private func sheetContent(for sheet: OutreachSheet) -> some View {
        switch sheet {
        case .mailView(let recipient, let subject, let body):
            MailView(
                result: $viewModel.mailResult,
                recipient: recipient,
                subject: subject,
                body: body
            )
            .presentationCornerRadius(16)
        case .roadmap:
            RoadmapView()
                .presentationCornerRadius(16)
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: Intro
    
    private var intro: some View {
        InfoBox(text: String(localized: "Provides opportunities to connect & exchange strategies, learn about scientific discoveries and learn more about MindfulPacer."))
            .foregroundStyle(.secondary)
    }
    
    // MARK: Community
    
    private var community: some View {
        IconLabelGroupBox(
            label:
                IconLabel(
                    icon: "person.3.fill",
                    title: String(localized: "Community"),
                    labelColor: .brandPrimary,
                    background: true
                ),
            description:
                Text("Discuss pacing strategies and insights with the community.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        ) {
            Button {
                openURL(URL(string: "https://www.mindfulpacer.ch/lcs-de")!)
            } label: {
                IconLabel(icon: "link", title: "Long Covid Schweiz", labelColor: .brandPrimary)
                    .font(.subheadline.weight(.semibold))
            }
            
            Button {
                openURL(URL(string: "https://www.mindfulpacer.ch/lcs-kids-de")!)
            } label: {
                IconLabel(
                    icon: "link",
                    title: String(localized: "Long Covid Kids Schweiz"),
                    labelColor: .brandPrimary
                )
                .font(.subheadline.weight(.semibold))
            }
        }
    }
    
    // MARK: Articles
    
    private var articles: some View {
        Section {
            NavigationLink(value: OutreachViewNavigationDestination.articlesList) {
                IconLabelGroupBox(
                    label:
                        IconLabel(
                            icon: "newspaper",
                            title: String(localized: "Articles"),
                            labelColor: .brandPrimary,
                            background: true
                        )
                ) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            if viewModel.isFetchingArticles {
                                ForEach(0 ..< 5) { _ in
                                    BlogArticleCell(
                                        article: BlogArticle.mockArticle,
                                        isPreview: true
                                    )
                                    .frame(width: 300)
                                    .redacted(reason: .placeholder)
                                }
                            } else {
                                ForEach(viewModel.recentArticles) { article in
                                    BlogArticleCell(
                                        article: article,
                                        isPreview: true
                                    )
                                    .frame(width: 300)
                                }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                } accessoryIndicator: {
                    Icon(name: "chevron.right", color: Color(.systemGray2))
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
    }
    
    // MARK: Website
    
    private var website: some View {
        Button {
            openURL(URL(string: "https://mindfulpacer.ch")!)
        } label: {
            RoundedListCell(
                image: "MindfulPacer Icon",
                title: String(localized: "Our Website"),
                accessoryIndicatorIcon: "link"
            )
        }
    }
    
    // MARK: Contact Us
    
    private var contactUs: some View {
        Button {
            viewModel.presentSheet(
                .mailView(
                    recipient: viewModel.contactSupportRecipient,
                    subject: viewModel.contactSupportSubject,
                    body: nil
                )
            )
        } label: {
            RoundedListCell(
                icon: "envelope",
                title: String(localized: "Contact Us"),
                accessoryIndicatorIcon: "arrow.up.forward.square"
            )
        }
    }
    
    // MARK: Roadmap
    
    private var roadmap: some View {
        Button {
            viewModel.presentSheet(.roadmap)
        } label: {
            RoundedListCell(
                icon: "map",
                title: String(localized: "Roadmap"),
                description: String(localized: "View upcoming features"),
                accessoryIndicatorIcon: "arrow.up.forward.square"
            )
        }
    }
}

// MARK: - Preview

#Preview {
    OutreachView()
}
