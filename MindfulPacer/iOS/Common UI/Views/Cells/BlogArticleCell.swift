import SwiftUI
import Kingfisher

/// Owns its actions so callers never need to nest a menu or link inside a button.
struct BlogArticleCell: View {
    let article: BlogArticle
    var cardColor: Color = Color(.secondarySystemGroupedBackground)
    var isPreview: Bool = false

    var body: some View {
        Card(backgroundColor: cardColor, contentPadding: 12) {
            VStack(alignment: .leading, spacing: 12) {
                Link(destination: article.link) {
                    VStack(alignment: .leading, spacing: 12) {
                        if let imageURL = article.imageURL {
                            KFImage(imageURL)
                                .placeholder {
                                    Rectangle().fill(.quaternary)
                                        .overlay { Image(systemName: "newspaper").foregroundStyle(Color.secondary) }
                                }
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity, maxHeight: isPreview ? 180 : 240)
                                .clipShape(.rect(cornerRadius: 16))
                                .accessibilityHidden(true)
                        }

                        Text(article.title)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(article.publicationDate, format: .dateTime.day().month(.abbreviated).year())
                            .font(.caption)
                            .foregroundStyle(Color.secondary)

                        if !isPreview {
                            Text(article.excerpt)
                                .font(.subheadline)
                                .foregroundStyle(Color.secondary)
                                .lineLimit(3)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
                    .multilineTextAlignment(.leading)
                }
                .accessibilityHint("Read Full Article")

                if !article.categories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(article.categories, id: \.rawValue) { category in
                                Label(category.rawValue, systemImage: category.icon)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(category.color)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(category.color.opacity(0.1), in: .capsule)
                            }
                        }
                    }
                }

                VStack(spacing: 0) {
                    Divider()
                    HStack {
                        Link(destination: article.link) {
                            Label("Read Full Article", systemImage: "arrow.up.right")
                                .font(.subheadline.weight(.semibold))
                                .frame(minHeight: 32)
                        }
                        Spacer()
                        ShareLink(item: article.link) {
                            Label("Share Article", systemImage: "square.and.arrow.up")
                                .labelStyle(.iconOnly)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                    }
                    .tint(.brandPrimary)
                }
            }
        }
    }
}

#Preview {
    BlogArticleCell(article: .mockArticle)
        .padding()
        .background(Color(.systemGroupedBackground))
}
