//
//  BlogService.swift
//  iOS
//
//  Created by Grigor Dochev on 01.02.2025.
//

import Foundation
import SwiftUI
import SwiftSoup

// MARK: - BlogServiceProtocol

protocol BlogServiceProtocol {
    func fetchBlogArticles() async throws -> [BlogArticle]
}

// MARK: - BlogService

class BlogService: NSObject, BlogServiceProtocol, XMLParserDelegate, @unchecked Sendable {
    
    static let shared = BlogService()
    
    private let feedURL = URL(string: "https://mindfulpacer.ch/feed/gn")!
    private var parsedItems: [RSSItem] = []
    private var currentItem: RSSItem?
    private var currentElementName = ""
    private var accumulatedString = ""

    func fetchBlogArticles() async throws -> [BlogArticle] {
        let (fetchedData, _) = try await URLSession.shared.data(from: feedURL)
        let rssEntries = try parseRSS(fetchedData)
        return rssEntries.compactMap { mapToBlogArticle($0) }
    }

    private func parseRSS(_ data: Data) throws -> [RSSItem] {
        parsedItems.removeAll()
        currentItem = nil
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = self
        if !xmlParser.parse() {
            throw xmlParser.parserError ?? NSError(domain: "BlogServiceError", code: -1)
        }
        return parsedItems
    }

    private struct RSSItem {
        var title = ""
        var link = ""
        var description = ""
        var pubDate = ""
        var guid: String?
        var author = ""
        var contentEncoded = ""
        var categories: [String] = []
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        currentElementName = elementName
        if elementName == "item" {
            currentItem = RSSItem()
        }
        accumulatedString = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        accumulatedString += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        guard let unwrappedCurrentItem = currentItem else { return }
        let trimmedString = accumulatedString.trimmingCharacters(in: .whitespacesAndNewlines)
        switch elementName {
        case "title": currentItem?.title += trimmedString
        case "link": currentItem?.link += trimmedString
        case "description": currentItem?.description += trimmedString
        case "pubDate": currentItem?.pubDate += trimmedString
        case "guid": currentItem?.guid = trimmedString
        case "dc:creator": currentItem?.author += trimmedString
        case "content:encoded": currentItem?.contentEncoded += trimmedString
        case "category":
            if !trimmedString.isEmpty {
                currentItem?.categories.append(trimmedString)
            }
        case "item":
            parsedItems.append(unwrappedCurrentItem)
            currentItem = nil
        default:
            break
        }
        accumulatedString = ""
        currentElementName = ""
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {}

    private func mapToBlogArticle(_ rssItem: RSSItem) -> BlogArticle? {
        let convertedDate = convertDate(rssItem.pubDate) ?? Date()
        guard let articleURL = URL(string: rssItem.link),
              let articleGuid = rssItem.guid,
              !articleGuid.isEmpty
        else {
            return nil
        }
        let mappedCategories = rssItem.categories.map { BlogCategory.from($0) }
        return BlogArticle(
            title: rssItem.title,
            link: articleURL,
            author: rssItem.author,
            imageURL: extractFirstImageURL(html: rssItem.contentEncoded),
            excerpt: rssItem.description,
            body: rssItem.contentEncoded,
            publicationDate: convertedDate,
            categories: mappedCategories,
            guid: articleGuid
        )
    }

    private func convertDate(_ rawDate: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: rawDate)
    }

    private func extractFirstImageURL(html: String) -> URL? {
        do {
            let document = try SwiftSoup.parse(html)
            if let imageElement = try document.select("img").first() {
                if let dataSrcAttribute = try? imageElement.attr("data-src"), !dataSrcAttribute.isEmpty {
                    return URL(string: dataSrcAttribute)
                }
                if let srcAttribute = try? imageElement.attr("src"), !srcAttribute.isEmpty {
                    return URL(string: srcAttribute)
                }
            }
        } catch {}
        return nil
    }
}
