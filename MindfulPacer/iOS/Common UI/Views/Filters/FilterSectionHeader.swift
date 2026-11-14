//
//  FilterSectionHeader.swift
//  iOS
//
//  Created by Grigor Dochev on 03.07.2026.
//

import SwiftUI

// MARK: - FilterSectionHeader

struct FilterSectionHeader: View {
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            if let subtitle {
                Text(subtitle)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        FilterSectionHeader(title: "Activities", subtitle: "2 selected")
        FilterSectionHeader(title: "Mood", subtitle: "All")
    }
    .padding(.vertical)
    .background(Color(.systemGroupedBackground))
}
