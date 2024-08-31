//
//  AlarmTypeWidget.swift
//  iOS
//
//  Created by Grigor Dochev on 31.08.2024.
//

import SwiftUI

// MARK: - AlarmTypeWidget

extension HomeView {
    struct AlarmTypeWidget: View {
        var body: some View {
            IconLabelGroupBox(
                label:
                    IconLabel(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Threshold Exceeded",
                        labelColor: Color("BrandPrimary"),
                        background: true
                    ),
                description:
                    Text("Summary of number of review reminders triggered, by alarm type.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            ) {
                HStack(spacing: 16) {
                    ForEach(ReviewReminder.AlarmType.allCases, id: \.self) { alarmType in
                        HStack(spacing: 16) {
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text("0")
                                    .font(.title.weight(.semibold))
                                
                                Text(alarmType.rawValue.lowercased())
                                    .foregroundStyle(alarmType.color)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
        
        HomeView.AlarmTypeWidget()
            .padding()
    }
}
