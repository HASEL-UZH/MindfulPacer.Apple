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
    
    let article: BlogArticle
    
    // MARK: Body
    
    var body: some View {
        IconLabelGroupBox(
            label:
                IconLabel(title: article.title),
            description:
                Text(article.excerpt)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        ) {
            VStack(spacing: 16) {
                if let imageURL = article.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        case .failure:
                            placeholderImage()
                        case .empty:
                            ProgressView()
                        @unknown default:
                            placeholderImage()
                        }
                    }
                    .frame(width: 80, height: 80)
                }
                
                HStack(spacing: 16) {
                    IconLabel(
                        icon: article.category.icon,
                        title: article.category.rawValue,
                        labelColor: article.category.color
                    )
                    
                    IconLabel(
                        icon: "calendar",
                        title: article.publicationDate.formatted(.dateTime.month().year().day()),
                        labelColor: .brandPrimary
                    )
                }
                .font(.subheadline.weight(.semibold))
                .iconLabelStyle(.pill)
            }
        }
        .iconLabelGroupBoxStyle(.divider)
    }
    
    // MARK: Placeholder Image
    
    @ViewBuilder
    private func placeholderImage() -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.gray.opacity(0.3))
            .frame(width: 80, height: 80)
            .overlay {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.gray)
            }
    }
}

// MARK: - Preview

#Preview {
    BlogArticleCell(article: BlogArticle(
        title: "The Power of Mindfulness",
        imageURL: URL(string: "https://example.com/image.jpg"),
        excerpt: "Mindfulness can improve your overall well-being by reducing stress and increasing focus...",
        publicationDate: Date(),
        category: .mindfulPacer
    ))
    .padding()
}
