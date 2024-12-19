//
//  RoadmapRepository.swift
//  iOS
//
//  Created by Grigor Dochev on 18.12.2024.
//

import Foundation

// MARK: - RoadmapRepository

protocol RoadmapRepository {
    func fetchRoadmap() async throws -> [RoadmapItem]
}

// MARK: - DefaultRoadmapRepository

class DefaultRoadmapRepository: RoadmapRepository {
    private let roadmapAPI: RoadmapAPI

    init(roadmapAPI: RoadmapAPI = RoadmapAPIService()) {
        self.roadmapAPI = roadmapAPI
    }
    
    func fetchRoadmap() async throws -> [RoadmapItem] {
        let roadmapDTOs = try await roadmapAPI.fetchRoadmap()
        return roadmapDTOs.map { RoadmapItem(dto: $0) }
    }
}
