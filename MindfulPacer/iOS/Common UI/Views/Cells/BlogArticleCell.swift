//
//  BlogArticleCell.swift
//  iOS
//
//  Created by Grigor Dochev on 01.02.2025.
//

import SwiftUI

// MARK: - BlogArticleCell

struct BlogArticleCell: View {
    
    // MARK: Properties
    
    @Environment(\.openURL) private var openURL
    
    let article: BlogArticle
    var cardColor: Color = Color(.tertiarySystemGroupedBackground)
    var showImage: Bool = true
    
    // MARK: Body
    
    var body: some View {
        Card(backgroundColor: cardColor) {
            VStack(spacing: 16) {
                Group {
                    HStack {
                        IconLabel(title: article.title)
                            .font(.title3.weight(.semibold))
                            .lineLimit(2)
                        
                        Spacer(minLength: 16)
                        
                        Menu {
                            Button {
                                openURL(article.link)
                            } label: {
                                Label("Read Full Article", systemImage: "link")
                            }
                            
                            ShareLink(item: article.link) {
                                Label("Share Article", systemImage: "square.and.arrow.up")
                            }
                        } label: {
                            Icon(name: "ellipsis")
                        }
                    }
                    
                    Text("Published on \(article.publicationDate.formatted(.dateTime.month().year().day()))")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.secondary)
                    
                    Text(article.excerpt)
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                                
                if showImage {
                    if let imageURL = article.imageURL {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 256)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .shadow(radius: 3)
                            case .failure:
                                EmptyView()
                            case .empty:
                                ProgressView()
                                    .frame(width: 80, height: 80)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .transition(.opacity)
                    }
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(article.categories, id: \.rawValue) { category in
                            IconLabel(
                                icon: category.icon,
                                title: category.rawValue,
                                labelColor: category.color
                            )
                        }
                       
                        Spacer()
                    }
                    .font(.footnote.weight(.semibold))
                    .iconLabelStyle(.pill)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BlogArticleCell(article: BlogArticle(
        title: "MindfulPacer Projekt-Statusupdate Q1'2025",
        link: URL(string: "https://mindfulpacer.ch/mindfulpacer-projekt-statusupdate-q12025/")!,
        author: "André Meyer",
        imageURL: URL(string: "https://mindfulpacer.ch/wp-content/uploads/2025/01/Home-Dark-472x1024.png"),
        excerpt: "Hallo zusammen! Gerne möchte ich die Gelegenheit nutzen, um (endlich) ein Statusupdate zum MindfulPacer-Projekt zu geben...",
        body: "<p>Hallo zusammen!</p><p>Gerne möchte ich...</p>",
        publicationDate: Date(),
        categories: [.mindfulPacer, .forschung],
        guid: "https://mindfulpacer.ch/?p=11825"
    ))
    .padding()
}
