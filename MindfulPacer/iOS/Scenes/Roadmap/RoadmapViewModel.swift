//
//  RoadmapViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 05.02.2025.
//

import Foundation

// MARK: - RoadmapFetchError

enum RoadmapFetchError: LocalizedError {
    case noInternetConnection
    case serverError
    case decodingError
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .noInternetConnection:
            return "No internet connection. Please check your Wi-Fi or cellular network."
        case .serverError:
            return "Unable to fetch the roadmap. Please try again later."
        case .decodingError:
            return "Failed to decode the roadmap data."
        case .unknownError:
            return "An unknown error occurred. Please try again."
        }
    }
}

// MARK: - RoadmapViewModel

@Observable
@MainActor
class RoadmapViewModel {
    
    // MARK: - Dependencies
    
    nonisolated(unsafe) private let checkInternetConnectivityUseCase: CheckInternetConnectivityUseCase
    nonisolated(unsafe) private let fetchRoadmapUseCase: FetchRoadmapUseCase
    
    // MARK: - Published Properties
    
    var isFetchingRoadmap: Bool = false
    var roadmapItems: [RoadmapItem] = []
    var isInternetConnected: Bool = true
    var fetchErrorMessage: String?
    
    // MARK: - Initialization
    
    init(
        checkInternetConnectivityUseCase: CheckInternetConnectivityUseCase,
        fetchRoadmapUseCase: FetchRoadmapUseCase
    ) {
        self.checkInternetConnectivityUseCase = checkInternetConnectivityUseCase
        self.fetchRoadmapUseCase = fetchRoadmapUseCase
    }
    
    // MARK: - View Events
    
    func onViewAppear() {
        fetchRoadmap()
    }
    
    // MARK: - Private Methods
    
    private func fetchRoadmap() {
        Task {
            isInternetConnected = await checkInternetConnectivityUseCase.execute()
            isFetchingRoadmap = true

            guard isInternetConnected else {
                fetchErrorMessage = RoadmapFetchError.noInternetConnection.localizedDescription
                isFetchingRoadmap = false
                return
            }

            fetchErrorMessage = nil

            do {
                let items = try await fetchRoadmapUseCase.execute()
                roadmapItems = items
            } catch let error as RoadmapFetchError {
                fetchErrorMessage = error.localizedDescription
            } catch {
                fetchErrorMessage = RoadmapFetchError.unknownError.localizedDescription
            }

            isFetchingRoadmap = false
        }
    }
}
