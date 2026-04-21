//
//  BlogArticleTests.swift
//  iOSTests
//
//  Tests for `BlogArticle` and `BlogCategory`. Blog articles are fetched from
//  the MindfulPacer WordPress site and displayed in the Outreach section of the
//  iOS app. Each article is tagged with categories like "Forschung" (Research)
//  or "Long Covid". The `BlogCategory.from(_:)` factory method performs fuzzy
//  matching using `localizedCaseInsensitiveContains` to handle slight variations
//  in category strings from the WordPress API.
//

import Testing
import Foundation
@testable import iOS

// MARK: - BlogCategory Parsing

/// Validates `BlogCategory.from(_:)` which converts a raw category string
/// from the WordPress API into a typed `BlogCategory` enum case.
/// The matching is fuzzy (case-insensitive substring match), so "mindfulpacer"
/// matches the "MindfulPacer" case. Unknown categories fall back to `.other`.
struct BlogCategoryParsingTests {

    /// An exact match of the raw value should resolve to the correct case.
    @Test func from_exactMatch_mindfulPacer() {
        #expect(BlogCategory.from("MindfulPacer") == .mindfulPacer)
    }

    /// Case-insensitive match: all lowercase should still match.
    @Test func from_caseInsensitive() {
        #expect(BlogCategory.from("forschung") == .forschung)
    }

    /// Substring match: a longer string containing the category name should
    /// still match, because `localizedCaseInsensitiveContains` is used.
    @Test func from_substringMatch() {
        #expect(BlogCategory.from("Learn about Activity Pacing techniques") == .activityPacing)
    }

    /// When no category matches, `.other` should be returned as the fallback.
    @Test func from_unknownCategory_returnsOther() {
        #expect(BlogCategory.from("Completely Unknown Topic") == .other)
    }

    /// An empty string should also fall back to `.other`.
    @Test func from_emptyString_returnsOther() {
        #expect(BlogCategory.from("") == .other)
    }

    /// Verify that all known categories can be matched by their own raw value.
    @Test func from_allKnownCategories_matchByRawValue() {
        for category in BlogCategory.allCases where category != .other {
            #expect(BlogCategory.from(category.rawValue) == category)
        }
    }
}

// MARK: - BlogCategory Properties

/// Verifies that each `BlogCategory` provides a non-empty SF Symbol icon name,
/// used to render category badges in the article list.
struct BlogCategoryPropertiesTests {

    /// Every category should have a non-empty icon string for UI rendering.
    @Test func icon_allCasesNonEmpty() {
        for category in BlogCategory.allCases {
            #expect(!category.icon.isEmpty, "Category \(category) has empty icon")
        }
    }

    /// All icon names should be unique to avoid visual confusion.
    @Test func icon_allCasesUnique() {
        let icons = BlogCategory.allCases.map(\.icon)
        #expect(Set(icons).count == icons.count)
    }
}

// MARK: - BlogCategory Codable

/// Validates that `BlogCategory` correctly round-trips through JSON encoding
/// and decoding, since categories are stored in the `BlogArticle` model.
struct BlogCategoryCodableTests {

    /// Encoding and decoding a category should produce the same value.
    @Test func codable_roundTrip() throws {
        for category in BlogCategory.allCases {
            let data = try JSONEncoder().encode(category)
            let decoded = try JSONDecoder().decode(BlogCategory.self, from: data)
            #expect(decoded == category)
        }
    }
}
