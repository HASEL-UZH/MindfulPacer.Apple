//
//  SettingsViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 13.09.2024.
//

import Foundation
import MessageUI

// MARK: - Theme

enum Theme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: Self { self }
    
    var icon: String {
        switch self {
        case .system:
            "circle.lefthalf.filled.righthalf.striped.horizontal.inverse"
        case .light:
            "sun.min"
        case .dark:
            "moon"
        }
    }
    
    var description: String {
        switch self {
        case .system:
            "Use the same setting as your device"
        case .light:
            "Always use light mode"
        case .dark:
            "Always use dark mode"
        }
    }
}

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

// MARK: - SettingsViewModel

@MainActor
@Observable
class SettingsViewModel {
    
    // MARK: - Dependencies
    
    private let checkInternetConnectivityUseCase: CheckInternetConnectivityUseCase
    private let fetchModeOfUseUseCase: FetchModeOfUseUseCase
    private let fetchRoadmapUseCase: FetchRoadmapUseCase
    private let fetchThemeUseCase: FetchThemeUseCase
    private let setModeOfUseUseCase: SetModeOfUseUseCase
    private let setThemeUseCase: SetThemeUseCase
    
    // MARK: - Published Properties
    
    var navigationPath: [SettingsNavigationDestination] = []
    var activeSheet: SettingsSheet?
    
    var mailResult: Result<MFMailComposeResult, Error>?
    
    var isFetchingRoadmap: Bool = false
    var roadmapItems: [RoadmapItem] = []
    var isInternetConnected: Bool = true
    var fetchErrorMessage: String?
    
    var selectedTheme: Theme = .system
    var isExpandedModeOfUseOn: Bool = false {
        didSet { updateModeOfUse() }
    }
    
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version).\(build)"
    }
    
    var systemVersion: String {
        "iOS \(UIDevice.current.systemVersion)"
    }
    
    var screenSize: String {
        let size = UIScreen.main.bounds.size
        return "\(Int(size.width)) x \(Int(size.height))"
    }
    
    var modelName: String {
        return iPhoneModelMap[modelIdentifier] ?? "Unknown"
    }
    
    // MARK: Private Properties
    
    private var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let identifier = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingCString: $0)
            }
        }
        return identifier ?? "Unknown"
    }
    
    private let iPhoneModelMap: [String: String] = [
        "iPhone11,8": "iPhone XR",
        "iPhone12,1": "iPhone 11",
        "iPhone12,3": "iPhone 11 Pro",
        "iPhone12,5": "iPhone 11 Pro Max",
        "iPhone12,8": "iPhone SE 2nd Gen",
        "iPhone13,1": "iPhone 12 Mini",
        "iPhone13,2": "iPhone 12",
        "iPhone13,3": "iPhone 12 Pro",
        "iPhone13,4": "iPhone 12 Pro Max",
        "iPhone14,2": "iPhone 13 Pro",
        "iPhone14,3": "iPhone 13 Pro Max",
        "iPhone14,4": "iPhone 13 Mini",
        "iPhone14,5": "iPhone 13",
        "iPhone14,6": "iPhone SE 3rd Gen",
        "iPhone14,7": "iPhone 14",
        "iPhone14,8": "iPhone 14 Plus",
        "iPhone15,2": "iPhone 14 Pro",
        "iPhone15,3": "iPhone 14 Pro Max",
        "iPhone15,4": "iPhone 15",
        "iPhone15,5": "iPhone 15 Plus",
        "iPhone16,1": "iPhone 15 Pro",
        "iPhone16,2": "iPhone 15 Pro Max",
        "iPhone17,1": "iPhone 16 Pro",
        "iPhone17,2": "iPhone 16 Pro Max",
        "iPhone17,3": "iPhone 16",
        "iPhone17,4": "iPhone 16 Plus"
    ]
    
    // MARK: - Initialization
    
    init(
        checkInternetConnectivityUseCase: CheckInternetConnectivityUseCase,
        fetchModeOfUseUseCase: FetchModeOfUseUseCase,
        fetchRoadmapUseCase: FetchRoadmapUseCase,
        fetchThemeUseCase: FetchThemeUseCase,
        setModeOfUseUseCase: SetModeOfUseUseCase,
        setThemeUseCase: SetThemeUseCase
    ) {
        self.checkInternetConnectivityUseCase = checkInternetConnectivityUseCase
        self.fetchModeOfUseUseCase = fetchModeOfUseUseCase
        self.fetchRoadmapUseCase = fetchRoadmapUseCase
        self.fetchThemeUseCase = fetchThemeUseCase
        self.setModeOfUseUseCase = setModeOfUseUseCase
        self.setThemeUseCase = setThemeUseCase
    }
    
    // MARK: - View Events
    
    func onViewAppear() {
        fetchCurrentSettings()
        fetchRoadmap()
    }
    
    // MARK: - Presentation
    
    func presentSheet(_ sheet: SettingsSheet) {
        activeSheet = sheet
    }
    
    // MARK: - User Actions
    
    func generateSystemReport() -> String {
        return """
        App Version: \(appVersion)
        System Version: \(systemVersion)
        Screen Size: \(screenSize)
        Model Name: \(modelName)
        Model Identifier: \(modelIdentifier)
        """
    }
    
    func setTheme(to theme: Theme) {
        setThemeUseCase.execute(theme: theme)
        selectedTheme = theme
    }
    
    // MARK: - Private Methods
    
    private func fetchCurrentSettings() {
        selectedTheme = fetchThemeUseCase.execute()
        isExpandedModeOfUseOn = fetchModeOfUseUseCase.execute() == .expanded
    }
    
    private func updateModeOfUse() {
        setModeOfUseUseCase.execute(modeOfUse: isExpandedModeOfUseOn ? .expanded : .essentials)
    }
    
    private func fetchRoadmap() {
        let fetchRoadmapUseCase = self.fetchRoadmapUseCase // TODO: Temporary fix, find the root cause of the error
        let checkInternetConnectivityUseCase = self.checkInternetConnectivityUseCase // TODO: Temporary fix, find the root cause of the error
        
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
