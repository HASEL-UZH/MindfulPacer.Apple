//
//  RoadmapAPIService.swift
//  iOS
//
//  Created by Grigor Dochev on 18.12.2024.
//

import Foundation

// MARK: - RoadmapAPI

protocol RoadmapAPIServiceProtocol: Sendable {
    func fetchRoadmap() async throws -> [RoadmapItemDTO]
}

// MARK: - RoadmapAPIService

class RoadmapAPIService: RoadmapAPIServiceProtocol, @unchecked Sendable {
    static let shared = RoadmapAPIService()

    private let url = "https://www.mindfulpacer.ch/DATA/MP_Roadmap_EN.json"
    
    func fetchRoadmap() async throws -> [RoadmapItemDTO] {
        return try await fetchGenericJSONData(urlString: url)
    }
    
    private func fetchGenericJSONData<T: Decodable>(urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else { throw NetworkError.invalidData }
        let request = URLRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw NetworkError.invalidResponse }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }
}
