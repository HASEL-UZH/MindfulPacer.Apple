//
//  FilterCapsuleButton.swift
//  iOS
//
//  Created by Grigor Dochev on 03.07.2026.
//

import SwiftUI

// MARK: - FilterCapsuleButton

struct FilterCapsuleButton: View {
    let title: String
    var systemImage: String?
    var emoji: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        SelectableButton(
            shape: .capsule,
            backgroundColor: Color(.secondarySystemGroupedBackground),
            selectionFillColor: Color("BrandPrimary"),
            selectionTextColor: Color("BrandPrimary"),
            padding: 10,
            isSelected: isSelected,
            hasOutline: false,
            action: action
        ) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .symbolVariant(.fill)
                }

                if let emoji {
                    Text(emoji)
                }

                Text(title)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        FilterCapsuleButton(
            title: "Movement",
            systemImage: "figure.walk",
            isSelected: true
        ) { }

        FilterCapsuleButton(
            title: "Happy",
            emoji: "😊",
            isSelected: false
        ) { }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
