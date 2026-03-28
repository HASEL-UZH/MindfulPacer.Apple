//
//  RoadmapRepository.swift
//  iOS
//
//  Created by Grigor Dochev on 18.12.2024.
//

import Foundation

// MARK: - RoadmapRepository

protocol RoadmapRepository: Sendable {
    func fetchRoadmap() async throws -> [RoadmapItem]
}

// MARK: - DefaultRoadmapRepository

final class DefaultRoadmapRepository: RoadmapRepository {
    private let roadmapAPI: RoadmapAPIServiceProtocol

    init(roadmapAPI: RoadmapAPIServiceProtocol) {
        self.roadmapAPI = roadmapAPI
    }
    
    func fetchRoadmap() async throws -> [RoadmapItem] {
        let roadmapDTOs = try await roadmapAPI.fetchRoadmap()
        return roadmapDTOs.map { RoadmapItem(dto: $0) }
    }
}
