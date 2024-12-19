//
//  RoadmapItem.swift
//  iOS
//
//  Created by Grigor Dochev on 18.12.2024.
//

import Foundation
import SwiftUI

// MARK: - RoadmapItem

struct RoadmapItem: Identifiable {
    let platform: Platform
    let description: String
    let status: Status
    let comment: String
    
    enum Platform: String, CaseIterable {
        case apple = "Apple"
        case android = "Android"
        case all = "All"

        init(rawValue: String) {
            switch rawValue.lowercased() {
            case "apple":
                self = .apple
            case "android":
                self = .android
            case "all":
                self = .all
            default:
                self = .all
            }
        }
        
        var color: Color {
            switch self {
            case .apple:
                Color.gray
            case .android:
                Color(.androidGreen)
            case .all:
                Color.brandPrimary
            }
        }
        
        var icon: String? {
            switch self {
            case .apple:
                "apple.logo"
            case .android:
                nil
            case .all:
                "iphone.gen1"
            }
        }
        
        var image: String? {
            switch self {
            case .android:
                "android-logo"
            default:
                nil
            }
        }
    }
    
    enum Status: String, CaseIterable {
        case paused
        case inProgress = "in progress"
        case tbd
        case ready
        
        var color: Color {
            switch self {
            case .inProgress:
                Color.green
            case .ready:
                Color.yellow
            case .paused:
                Color.orange
            case .tbd:
                Color.red
            }
        }
    }
    
    init(dto: RoadmapItemDTO) {
        self.platform = Platform(rawValue: dto.platform)
        self.description = dto.description
        self.status = Status(rawValue: dto.status) ?? .tbd
        self.comment = dto.comment
    }
    
    var id: String { description }
}
