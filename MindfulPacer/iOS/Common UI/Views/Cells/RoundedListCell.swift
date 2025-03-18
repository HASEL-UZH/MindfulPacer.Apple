//
//  RoundedListCell.swift
//  iOS
//
//  Created by Grigor Dochev on 03.02.2025.
//

import SwiftUI

// MARK: - RoundedListCell

struct RoundedListCell: View {
    var icon: String?
    var image: String?
    var title: String
    var description: String?
    var accessoryIndicatorText: String?
    var accessoryIndicatorIcon: String?
    
    var body: some View {
        HStack {
            IconLabel(
                icon: icon,
                image: image,
                title: title,
                description: description,
                labelColor: Color("BrandPrimary"),
                background: true
            )
            .font(.subheadline.weight(.semibold))
            
            Spacer()
            
            HStack(spacing: 4) {
                if let accessoryIndicatorText {
                    Text(accessoryIndicatorText)
                        .foregroundStyle(Color(.systemGray2))
                        .fixedSize(horizontal: true, vertical: false)
                }
                
                if let accessoryIndicatorIcon {
                    Icon(name: accessoryIndicatorIcon, color: Color(.systemGray2))
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
    }
}

// MARK: - Preview

#Preview {
    RoundedList {
        Section {
            RoundedListCell(
                icon: "map",
                title: "Roadmap"
            )
            
            RoundedListCell(
                image: "MindfulPacer Icon",
                title: "MinfdulPacer",
                description: "Here is a description"
            )
        }
    }
}
