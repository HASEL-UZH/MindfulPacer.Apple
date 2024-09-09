//
//  SelectableButton.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 13.08.2024.
//

import SwiftUI

// MARK: - SelectableButton

struct SelectableButton<Content: View>: View {
    // MARK: ButtonShape Enum
    
    enum ButtonShape {
        case roundedRectangle(cornerRadius: CGFloat)
        case circle
    }

    // MARK: Properties
    
    var shape: ButtonShape
    var backgroundColor: Color = Color(.secondarySystemGroupedBackground)
    var foregroundColor: Color = Color.secondary
    var selectionColor: Color = Color("BrandPrimary")
    var isSelected: Bool
    var action: () -> Void
    @ViewBuilder let content: () -> Content

    // MARK: Body
    
    var body: some View {
        Button(action: action) {
            content()
                .padding()
                .frame(maxWidth: .infinity)
                .background {
                    backgroundShape()
                        .foregroundStyle(
                            isSelected ? selectionColor
                                .opacity(0.1) : backgroundColor
                        )
                }
                .overlay {
                    if isSelected {
                        overlayShape()
                    }
                }
        }
        .foregroundStyle(isSelected ? selectionColor : foregroundColor)
    }

    // MARK: Background Shape
    
    @ViewBuilder
    private func backgroundShape() -> some View {
        switch shape {
        case .roundedRectangle(let cornerRadius):
            RoundedRectangle(cornerRadius: cornerRadius)
        case .circle:
            Circle()
        }
    }

    // MARK: Overlay Shape
    
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
