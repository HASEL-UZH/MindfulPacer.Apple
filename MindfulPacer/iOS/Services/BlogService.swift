//
//  BlogService.swift
//  iOS
//
//  Created by Grigor Dochev on 01.02.2025.
//

import Foundation

// MARK: - BlogServiceProtocol

protocol BlogServiceProtocol {
    func fetchBlogArticles() async throws -> [BlogArticle]
}

// MARK: - BlogService

class BlogService: NSObject, BlogServiceProtocol, @unchecked Sendable {
    static let shared = BlogService()

    private let feedURL = URL(string: "https://mindfulpacer.ch/blog/feed/")!

    // XML Parsing Variables
    private var articles: [BlogArticle] = []
    private var currentElement: String = ""
    private var currentTitle: String = ""
    private var currentImageURL: URL?
    private var currentExcerpt: String = ""
    private var currentPublicationDate: Date?
    private var currentCategory: BlogCategory = .other

    private var tempElementContent: String = ""

    // MARK: - Fetch RSS Feed
    
    func fetchBlogArticles() async throws -> [BlogArticle] {
        let (data, _) = try await URLSession.shared.data(from: feedURL)

        let parser = XMLParser(data: data)
        parser.delegate = self
        
        if parser.parse() {
            return articles
        } else {
            throw URLError(.badServerResponse)
        }
    }
}

// MARK: - XMLParserDelegate

extension BlogService: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes: [String : String] = [:]) {
        currentElement = elementName
        tempElementContent = ""

        if elementName == "item" {
            currentTitle = ""
            currentImageURL = nil
            currentExcerpt = ""
            currentPublicationDate = nil
            currentCategory = .other
        }

        // Look for image URL in `media:content`
        if elementName == "media:content", let urlString = attributes["url"], let url = URL(string: urlString) {
            currentImageURL = url
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        tempElementContent += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        let trimmedContent = tempElementContent.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        case "title":
            currentTitle = trimmedContent
        case "description":
            currentExcerpt = trimmedContent
        case "pubDate":
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
            formatter.locale = Locale(identifier: "en_US")
            if let date = formatter.date(from: trimmedContent) {
                currentPublicationDate = date
            }
        case "category":
            currentCategory = BlogCategory.from(trimmedContent)
        case "item":
            if let publicationDate = currentPublicationDate {
                let article = BlogArticle(
                    title: currentTitle,
                    imageURL: currentImageURL,
                    excerpt: currentExcerpt,
                    publicationDate: publicationDate,
                    category: currentCategory
                )
                articles.append(article)
            }
        default:
            break
        }
    }
}
