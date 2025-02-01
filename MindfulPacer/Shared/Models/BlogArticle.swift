//
//  BlogArticle.swift
//  iOS
//
//  Created by Grigor Dochev on 01.02.2025.
//

import Foundation
import SwiftUI

// MARK: - BlogArticle

struct BlogArticle: Identifiable, Codable {
    let id = UUID()
    let title: String
    let imageURL: URL?
    let excerpt: String
    let publicationDate: Date
    let category: BlogCategory
}

// MARK: - BlogCategory

enum BlogCategory: String, CaseIterable, Codable {
    case mindfulPacer = "MindfulPacer"
    case forschung = "Forschung"
    case other = "Other"
    
    static func from(_ rawValue: String) -> BlogCategory {
        return BlogCategory.allCases.first { rawValue.localizedCaseInsensitiveContains($0.rawValue) } ?? .other
    }
    
    var icon: String {
        switch self {
        case .mindfulPacer: "app"
        case .forschung: "text.page.badge.magnifyingglass"
        case .other: "info"
        }
    }
    
    var color: Color {
        switch self {
        case .mindfulPacer: Color.brandPrimary
        case .forschung: Color.purple
        case .other: Color.secondary
        }
    }
}
