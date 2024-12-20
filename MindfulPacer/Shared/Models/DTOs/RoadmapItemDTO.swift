//
//  RoadmapItemDTO.swift
//  iOS
//
//  Created by Grigor Dochev on 18.12.2024.
//

import Foundation

// MARK: - RoadmapItemDTO

import Foundation

struct RoadmapItemDTO: Codable {
    let platform: String
    let description: String
    let status: String
    let comment: String

    enum CodingKeys: String, CodingKey {
        case platform = "Platform"
        case description = "Description"
        case status = "Status"
        case comment = "Comment"
    }
}
