//
//  SelectableButton.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 13.08.2024.
//

import SwiftUI

struct SelectableButton<Content: View>: View {
    let isSelected: Bool
    let action: () -> Void
    let content: () -> Content
    
    var body: some View {
        Button(action: action) {
            content()
                .padding()
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundStyle(isSelected ? Color("PrimaryGreen").opacity(0.1) : Color(.secondarySystemGroupedBackground))
                }
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color("PrimaryGreen"), lineWidth: 2)
                    }
                }
        }
        .foregroundStyle(isSelected ? Color("PrimaryGreen") : Color.primary)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var isIconButtonSelected = false
    @Previewable @State var isLabelButtonSelected = false

    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
        
        VStack(spacing: 32) {
            SelectableButton(isSelected: isIconButtonSelected) {
                isIconButtonSelected.toggle()
            } content: {
                Image(systemName: "heart.fill")
            }
            .frame(width: 64)
            
            SelectableButton(isSelected: isLabelButtonSelected) {
                isLabelButtonSelected.toggle()
            } content: {
                Label("Steps", systemImage: "figure.walk")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal)
    }
}
