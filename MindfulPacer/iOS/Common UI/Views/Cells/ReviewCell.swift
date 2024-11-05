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

    var review: Review
    var withBackground: Bool = true
    var onTap: () -> Void

    // MARK: Body

    var body: some View {
        Button {
            onTap()
        } label: {
            if withBackground {
                cellContent
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
            } else {
                cellContent
            }
        }
    }

    // MARK: Cell Content

    private var cellContent: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                if let subcategory = review.subcategory {
                    IconLabel(icon: subcategory.icon, title: subcategory.name, labelColor: Color.primary)
                        .font(.subheadline.weight(.semibold))
                } else if let category = review.category {
                    IconLabel(icon: category.icon, title: category.name, labelColor: Color.primary)
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
            }
        }
    }
}

// MARK: - Preview

//#Preview {
//    ReviewCell(review: Review()) {
//
//    }
//}
