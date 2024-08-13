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
    @Previewable @State var isSelected = false
    
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
        
        SelectableButton(isSelected: isSelected) {
            isSelected.toggle()
        } content: {
            Image(systemName: "heart.fill")
        }
        .frame(width: 64)
    }
}
