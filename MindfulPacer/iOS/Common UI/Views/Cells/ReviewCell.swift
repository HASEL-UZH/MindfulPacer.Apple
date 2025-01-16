//
//  ReviewCell.swift
//  iOS
//
//  Created by Grigor Dochev on 01.09.2024.
//

import SwiftUI

// MARK: - ReviewCell

struct ReviewCell: View {
    
    // MARK: Properties

    @AppStorage(ModeOfUse.appStorageKey) var modeOfUse: ModeOfUse = .essentials
    var review: Review
    var backgroundColor: Color = Color(.secondarySystemGroupedBackground)
    var onTap: () -> Void

    // MARK: Body
    
    var body: some View {
        Button {
            onTap()
        } label: {
            cellContent
                .padding()
                .background(backgroundColor)
        }
    }
    
    // MARK: Cell Content

    private var cellContent: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                if let subactivity = review.subactivity {
                    IconLabel(icon: subactivity.icon, title: subactivity.name, labelColor: Color.primary)
                        .font(.subheadline.weight(.semibold))
                } else if let activity = review.activity {
                    IconLabel(icon: activity.icon, title: activity.name, labelColor: Color.primary)
                        .font(.subheadline.weight(.semibold))
                }

                Text(review.date.formatted(.dateTime.day().month().hour().minute()))
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
            }

            Spacer()

            if review.didTriggerCrash {
                Icon(name: "exclamationmark.triangle.fill", color: .red, background: true)
            }
            
            if modeOfUse == .essentials {
                if let wellBeing = review.wellBeing {
                    Icon(
                        name: "cross.fill",
                        color: Symptom.wellBeing(wellBeing).color,
                        background: true
                    )
                }
            } else {
                if let mood = review.mood {
                    Text(mood.emoji)
                        .frame(width: 24, height: 24)
                        .padding(4)
                        .background {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .foregroundStyle(.yellow.opacity(0.1))
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.yellow.opacity(0.1), lineWidth: 1.5)
                            }
                        }
                } else if let wellBeing = review.wellBeing {
                    Icon(
                        name: "cross.fill",
                        color: Symptom.wellBeing(wellBeing).color,
                        background: true
                    )
                }
            }
        }
    }
}

// MARK: - Preview

// TODO: Add mock review
//#Preview {
//    ReviewCell(review: Review()) {
//
//    }
//}
