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
    var id = UUID()
    let title: String
    let link: URL
    let author: String
    let imageURL: URL?
    let excerpt: String
    let body: String
    let publicationDate: Date
    let categories: [BlogCategory]
    let guid: String
    
    static let mockArticle = BlogArticle(
        title: "MindfulPacer Projekt-Statusupdate Q1'2025",
        link: URL(string: "https://mindfulpacer.ch/mindfulpacer-projekt-statusupdate-q12025/")!,
        author: "André Meyer",
        imageURL: nil,
        excerpt: "Hallo zusammen! Gerne möchte ich die Gelegenheit nutzen, um (endlich) ein Statusupdate zum MindfulPacer-Projekt zu geben...",
        body: "<p>Hallo zusammen!</p><p>Gerne möchte ich...</p>",
        publicationDate: Date(),
        categories: [.mindfulPacer, .forschung],
        guid: "https://mindfulpacer.ch/?p=11825"
    )
}

// MARK: - BlogCategory

enum BlogCategory: String, CaseIterable, Codable {
    case mindfulPacer = "MindfulPacer"
    case forschung = "Forschung"
    case activityPacing = "Activity Pacing"
    case app = "App"
    case gesundheit = "Gesundheit"
    case innovation = "Innovation"
    case longCovid = "Long Covid"
    case meCfs = "ME/CFS"
    case medizin = "Medizin"
    case selbstReflektion = "Selbst-Reflektion"
    case other = "Other"

    static func from(_ rawValue: String) -> BlogCategory {
        return BlogCategory.allCases.first { rawValue.localizedCaseInsensitiveContains($0.rawValue) } ?? .other
    }

    var icon: String {
        switch self {
        case .mindfulPacer: "app"
        case .forschung: "text.page.badge.magnifyingglass"
        case .activityPacing: "figure.walk"
        case .app: "iphone"
        case .gesundheit: "heart.fill"
        case .innovation: "lightbulb"
        case .longCovid: "cross.case"
        case .meCfs: "waveform.path.ecg"
        case .medizin: "stethoscope"
        case .selbstReflektion: "person.crop.circle"
        case .other: "info"
        }
    }

    var color: Color {
        switch self {
        case .mindfulPacer: Color.brandPrimary
        case .forschung: Color.purple
        case .activityPacing: Color.green
        case .app: Color.blue
        case .gesundheit: Color.red
        case .innovation: Color.orange
        case .longCovid: Color.teal
        case .meCfs: Color.indigo
        case .medizin: Color.yellow
        case .selbstReflektion: Color.gray
        case .other: Color.secondary
        }
    }
}
