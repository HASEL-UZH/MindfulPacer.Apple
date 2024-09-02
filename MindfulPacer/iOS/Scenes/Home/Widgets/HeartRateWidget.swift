//
//  HeartRateWidget.swift
//  iOS
//
//  Created by Grigor Dochev on 31.08.2024.
//

import SwiftUI

// MARK: - HeartRateWidgetView

extension HomeView {
    struct HeartRateWidget: View {
        var body: some View {
            NavigationLink(value: Int()) {
                IconLabelGroupBox(
                    label: IconLabel(
                        icon: "heart.fill",
                        title: "Heart Rate",
                        labelColor: Color("BrandPrimary"),
                        background: true
                    )
                ) {
                    if false { // TODO: Show actual heart rate
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("80")
                                .font(.title.weight(.semibold))
                            Text("bpm")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        HStack(alignment: .center, spacing: 4) {
                            Text("--")
                                .font(.title.weight(.semibold))
                            Text("bpm")
                                .foregroundStyle(.secondary)
                        }
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
    HomeView.HeartRateWidget()
}
