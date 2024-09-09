//
//  ReviewReminderCell.swift
//  iOS
//
//  Created by Grigor Dochev on 01.09.2024.
//

import SwiftUI

// MARK: - ReviewReminderCell

struct TopRightCornerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Start at the top-leading corner
        path.move(to: CGPoint(x: 0, y: 0))
        
        // Draw a line to the top-right corner
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        
        // Draw a line to the bottom-trailing corner
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        
        // Draw a line along the diagonal from bottom-trailing to top-leading
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        
        // Close the path
        path.closeSubpath()
        
        return path
    }
}

struct ReviewReminderCell: View {
    // MARK: Properties
    
    var reviewReminder: ReviewReminder
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
                IconLabel(
                    icon: reviewReminder.measurementType.icon,
                    title: reviewReminder.measurementType.rawValue,
                    labelColor: reviewReminder.measurementType == .heartRate ? .pink : .teal
                )
                .font(.subheadline.weight(.semibold))
                
                Text("Above \(reviewReminder.threshold) \(reviewReminder.measurementType == .heartRate ? "bpm" : "steps") for \(reviewReminder.interval.rawValue.lowercased())")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Icon(
                name: "alarm",
                color: reviewReminder.reviewReminderType.color,
                background: true
            )
        }
        .foregroundStyle(Color.primary)
    }
}

// MARK: - Preview

#Preview {
    RoundedList {
        ReviewReminderCell(reviewReminder: ReviewReminder()) {}
    }
}
