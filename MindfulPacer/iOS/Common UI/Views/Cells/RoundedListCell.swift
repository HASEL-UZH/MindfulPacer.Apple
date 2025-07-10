//
//  RoundedListCell.swift
//  iOS
//
//  Created by Grigor Dochev on 03.02.2025.
//

import SwiftUI

// MARK: - RoundedListCell

struct RoundedListCell: View {
    var label: IconLabel
    var accessoryIndicatorText: String?
    var accessoryIndicatorIcon: String?
    
    var body: some View {
        HStack {
            label
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
                label: IconLabel(
                    icon: "map",
                    title: "Roadmap",
                    labelColor: Color("BrandPrimary"),
                    background: true
                )
            )
            
            RoundedListCell(
                label: IconLabel(
                    image: "MindfulPacer Icon",
                    title: "MindfulPacer",
                    description: "Here is a description",
                    labelColor: Color("BrandPrimary"),
                    background: true
                )
            )
        }
    }
}
