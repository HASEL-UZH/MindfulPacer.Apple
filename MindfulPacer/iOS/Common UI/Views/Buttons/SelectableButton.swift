//
//  SelectableButton.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 13.08.2024.
//

import SwiftUI

struct SelectableButton<Content: View>: View {
    enum ButtonShape {
        case roundedRectangle(cornerRadius: CGFloat)
        case circle
    }
    
    var shape: ButtonShape
    var color: Color = Color(.secondarySystemGroupedBackground)
    var selectionColor: Color = Color("BrandPrimary")
    var isSelected: Bool
    var action: () -> Void
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        Button(action: action) {
            content()
                .padding()
                .frame(maxWidth: .infinity)
                .background {
                    backgroundShape()
                        .foregroundStyle(
                            isSelected ? selectionColor
                                .opacity(0.1) : color
                        )
                }
                .overlay {
                    if isSelected {
                        overlayShape()
                    }
                }
        }
        .foregroundStyle(isSelected ? selectionColor : Color.primary)
    }
    
    @ViewBuilder
    private func backgroundShape() -> some View {
        switch shape {
        case .roundedRectangle(let cornerRadius):
            RoundedRectangle(cornerRadius: cornerRadius)
        case .circle:
            Circle()
        }
    }
    
    @ViewBuilder
    private func overlayShape() -> some View {
        switch shape {
        case .roundedRectangle(let cornerRadius):
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(selectionColor, lineWidth: 2)
        case .circle:
            Circle()
                .stroke(selectionColor, lineWidth: 2)
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var isRoundedRectangleButtonSelected = false
    @Previewable @State var isCircleButtonSelected = false
    
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
        
        VStack(spacing: 32) {
            SelectableButton(
                shape: .roundedRectangle(cornerRadius: 16),
                isSelected: isRoundedRectangleButtonSelected,
                action: {
                    isRoundedRectangleButtonSelected.toggle()
                }) {
                    Label("Save", systemImage: "square.and.arrow.down.fill")
                        .fontWeight(.semibold)
                }
            
            SelectableButton(
                shape: .circle,
                selectionColor: .yellow,
                isSelected: isCircleButtonSelected,
                action: {
                    isCircleButtonSelected.toggle()
                }) {
                    Image(systemName: "star.fill")
                }
        }
        .padding(.horizontal)
    }
}
