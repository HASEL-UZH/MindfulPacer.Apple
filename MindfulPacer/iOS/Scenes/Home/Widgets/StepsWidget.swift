//
//  StepsWidgetView.swift
//  iOS
//
//  Created by Grigor Dochev on 31.08.2024.
//

import SwiftUI

// MARK: - StepsWidget

extension HomeView {
    struct StepsWidget: View {
        var body: some View {
            NavigationLink(value: Int()) {
                IconLabelGroupBox(
                    label: IconLabel(
                        icon: "figure.walk",
                        title: "Steps",
                        labelColor: Color("BrandPrimary"),
                        background: true
                    )
                ) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("9,870")
                            .font(.title.weight(.semibold))
                        Text("steps")
                            .foregroundStyle(.secondary)
                    }
                } accessoryIndicator: {
                    Icon(name: "chevron.right", color: Color(.systemGray2))
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(.primary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView.StepsWidget()
}
