//
//  SelectableButton.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 13.08.2024.
//

import SwiftUI

// MARK: - SelectableButton

struct SelectableButton<Label: View>: View {
    // MARK: ButtonShape Enum

    enum ButtonShape {
        case roundedRectangle(cornerRadius: CGFloat)
        case circle
    }

    // MARK: Properties

    var shape: ButtonShape
    var backgroundColor: Color
    var foregroundColor: Color
    var selectionColor: Color
    var isSelected: Bool
    let action: () -> Void
    let label: () -> Label

    // MARK: Initializer

    init(
        shape: ButtonShape,
        backgroundColor: Color = Color(.secondarySystemGroupedBackground),
        foregroundColor: Color = Color.secondary,
        selectionColor: Color = Color("BrandPrimary"),
        isSelected: Bool,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.shape = shape
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.selectionColor = selectionColor
        self.isSelected = isSelected
        self.action = action
        self.label = label
    }

    // MARK: Body

    var body: some View {
        Button(action: action) {
            label()
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
                isSelected: isRoundedRectangleButtonSelected
            ) {
                isRoundedRectangleButtonSelected.toggle()
            } label: {
                Label("Save", systemImage: "square.and.arrow.down.fill")
                    .fontWeight(.semibold)
            }

            SelectableButton(
                shape: .circle,
                selectionColor: .yellow,
                isSelected: isCircleButtonSelected
            ) {
                isCircleButtonSelected.toggle()
            } label: {
                Image(systemName: "star.fill")
            }
        }
        .padding(.horizontal)
    }
}
