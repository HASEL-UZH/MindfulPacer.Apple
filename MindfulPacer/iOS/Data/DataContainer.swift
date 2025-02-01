//
//  DataContainer.swift
//  iOS
//
//  Created by Grigor Dochev on 18.12.2024.
//

import Factory
import Foundation

// MARK: - DataContainer

final class DataContainer: SharedContainer, @unchecked Sendable {
    static let shared = DataContainer()
    var manager = ContainerManager()
}

extension DataContainer {
    
    // MARK: - Blog Repository
    
    @MainActor
    var blogRepository: Factory<BlogRepository> {
        self { DefaultBlogRepository(blogService: BlogService.shared) }
    }
    
    // MARK: - Roadmap Repository
    
    @MainActor
    var roadmapRepository: Factory<RoadmapRepository> {
        self { DefaultRoadmapRepository(roadmapAPI: RoadmapAPIService.shared) }
    }
}
