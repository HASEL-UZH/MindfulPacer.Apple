//
//  FetchRoadmapUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 18.12.2024.
//

import Foundation

// MARK: - FetchRoadmapUseCase

protocol FetchRoadmapUseCase: Sendable {
    func execute() async throws -> [RoadmapItem]
}

// MARK: - DefaultFetchRoadmapUseCase

final class DefaultFetchRoadmapUseCase: FetchRoadmapUseCase {
    private let roadmapRepository: RoadmapRepository

    init(roadmapRepository: RoadmapRepository) {
        self.roadmapRepository = roadmapRepository
    }

    func execute() async throws -> [RoadmapItem] {
        return try await roadmapRepository.fetchRoadmap()
    }
}
