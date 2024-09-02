//
//  ReviewCell.swift
//  iOS
//
//  Created by Grigor Dochev on 01.09.2024.
//

import SwiftUI

// MARK: - ReviewCell

struct ReviewCell: View {
    var review: Review
    var withBackground: Bool = true
    var onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    if let subcategory = review.subcategory {
                        IconLabel(icon: subcategory.icon, title: subcategory.name)
                            .font(.subheadline.weight(.semibold))
                    } else if let category = review.category {
                        IconLabel(icon: category.icon, title: category.name)
                            .font(.subheadline.weight(.semibold))
                    }
                    
                    Text(review.date.formatted(.dateTime.day().month().hour().minute()))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if review.didTriggerCrash {
                    Icon(name: "bandage", color: .red, background: true)
                }
                
                if let mood = review.mood {
                    Text(mood)
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
            .padding(withBackground ? .all : [])
            .foregroundStyle(Color.primary)
            .background {
                if withBackground {
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundStyle(Color(.secondarySystemGroupedBackground))
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ReviewCell(review: Review()) {
        
    }
}
