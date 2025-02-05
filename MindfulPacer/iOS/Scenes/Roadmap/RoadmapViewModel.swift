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
    
    private let checkInternetConnectivityUseCase: CheckInternetConnectivityUseCase
    private let fetchRoadmapUseCase: FetchRoadmapUseCase
    
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
        let fetchRoadmapUseCase = self.fetchRoadmapUseCase
        let checkInternetConnectivityUseCase = self.checkInternetConnectivityUseCase
        
        Task { [weak self] in
            guard let self = self else { return }
            
            self.isInternetConnected = await checkInternetConnectivityUseCase.execute()
            self.isFetchingRoadmap = true
            
            guard self.isInternetConnected else {
                self.fetchErrorMessage = RoadmapFetchError.noInternetConnection.localizedDescription
                self.isFetchingRoadmap = false
                return
            }
            
            self.isFetchingRoadmap = true
            self.fetchErrorMessage = nil
            
            do {
                let roadmapItems = try await fetchRoadmapUseCase.execute()
                self.roadmapItems = roadmapItems
            } catch let error as RoadmapFetchError {
                self.fetchErrorMessage = error.localizedDescription
            } catch {
                self.fetchErrorMessage = RoadmapFetchError.unknownError.localizedDescription
            }
            
            self.isFetchingRoadmap = false
        }
    }
}
