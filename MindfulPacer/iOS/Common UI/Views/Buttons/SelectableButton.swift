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
        case capsule
        case circle
    }

    // MARK: Properties

    private var buttonBorderShape: ButtonBorderShape
    private var shape: SelectableButtonShape
    var backgroundColor: Color
    var selectionFillColor: Color
    var selectionTextColor: Color
    var unselectedTextColor: Color
    var padding: CGFloat
    var isSelected: Bool
    var hasOutline: Bool
    var outlineWidth: CGFloat
    let action: () -> Void
    let label: () -> Label

    // MARK: Initializer

    init(
        shape: ButtonBorderShape = .roundedRectangle(radius: 20),
        backgroundColor: Color = Color(.secondarySystemGroupedBackground),
        selectionFillColor: Color = Color("BrandPrimary"),
        selectionTextColor: Color = Color("BrandPrimary"),
        padding: CGFloat = 16.0,
        isSelected: Bool,
        hasOutline: Bool = false,
        outlineWidth: CGFloat = 1,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.buttonBorderShape = shape
        self.shape = SelectableButtonShape(shape)
        self.backgroundColor = backgroundColor
        self.selectionFillColor = selectionFillColor
        self.selectionTextColor = selectionTextColor
        self.unselectedTextColor = .primary
        self.padding = padding
        self.isSelected = isSelected
        self.hasOutline = hasOutline
        self.outlineWidth = outlineWidth
        self.action = action
        self.label = label
    }

    init(
        shape: ButtonShape,
        backgroundColor: Color = Color(.secondarySystemGroupedBackground),
        foregroundColor: Color = Color.secondary,
        selectionColor: Color = Color("BrandPrimary"),
        isSelected: Bool,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.buttonBorderShape = shape.buttonBorderShape
        self.shape = shape.selectableButtonShape
        self.backgroundColor = backgroundColor
        self.selectionFillColor = selectionColor
        self.selectionTextColor = selectionColor
        self.unselectedTextColor = foregroundColor
        self.padding = 16.0
        self.isSelected = isSelected
        self.hasOutline = true
        self.outlineWidth = 2
        self.action = action
        self.label = label
    }

    // MARK: Body

    var body: some View {
        Button(action: action) {
            label()
        }
        .buttonStyle(
            SelectableBorderedButtonStyle(
                shape: shape,
                backgroundColor: backgroundColor,
                selectionFillColor: selectionFillColor,
                selectionTextColor: selectionTextColor,
                unselectedTextColor: unselectedTextColor,
                padding: padding,
                isSelected: isSelected,
                hasOutline: hasOutline,
                outlineWidth: outlineWidth
            )
        )
        .buttonBorderShape(buttonBorderShape)
    }
}

// MARK: - Button Shape

private enum SelectableButtonShape {
    case roundedRectangle(cornerRadius: CGFloat)
    case capsule
    case circle

    init(_ shape: ButtonBorderShape) {
        if shape == .circle {
            self = .circle
        } else if shape == .capsule {
            self = .capsule
        } else {
            self = .roundedRectangle(cornerRadius: 20)
        }
    }
}

private extension SelectableButton.ButtonShape {
    var buttonBorderShape: ButtonBorderShape {
        switch self {
        case .roundedRectangle(let cornerRadius):
            .roundedRectangle(radius: cornerRadius)
        case .capsule:
            .capsule
        case .circle:
            .circle
        }
    }

    var selectableButtonShape: SelectableButtonShape {
        switch self {
        case .roundedRectangle(let cornerRadius):
            .roundedRectangle(cornerRadius: cornerRadius)
        case .capsule:
            .capsule
        case .circle:
            .circle
        }
    }
}

// MARK: - SelectableBorderedButtonStyle

private struct SelectableBorderedButtonStyle: ButtonStyle {
    var shape: SelectableButtonShape
    var backgroundColor: Color
    var selectionFillColor: Color
    var selectionTextColor: Color
    var unselectedTextColor: Color
    var padding: CGFloat
    var isSelected: Bool
    var hasOutline: Bool
    var outlineWidth: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let fillColor = isSelected
            ? selectionFillColor.opacity(isPressed ? 0.22 : 0.14)
            : backgroundColor.opacity(isPressed ? 0.90 : 1.0)
        let strokeColor = isSelected
            ? selectionFillColor.opacity(0.95)
            : Color(.separator).opacity(0.75)

        configuration.label
            .foregroundStyle(isSelected ? selectionTextColor : unselectedTextColor)
            .padding(padding)
            .frame(maxWidth: .infinity)
            .background {
                ZStack {
                    shapeBackground(fillColor)
                    if hasOutline {
                        shapeStroke(strokeColor, lineWidth: outlineWidth)
                    }
                }
            }
            .contentShape(.rect)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isPressed)
    }

    // MARK: Shape Background

    @ViewBuilder
    private func shapeBackground(_ color: Color) -> some View {
        switch shape {
        case .roundedRectangle(let cornerRadius):
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(color)
        case .capsule:
            Capsule()
                .fill(color)
        case .circle:
            Circle()
                .fill(color)
        }
    }

    // MARK: Shape Stroke

    @ViewBuilder
    private func shapeStroke(_ color: Color, lineWidth: CGFloat) -> some View {
        switch shape {
        case .roundedRectangle(let cornerRadius):
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(color, lineWidth: lineWidth)
        case .capsule:
            Capsule()
                .strokeBorder(color, lineWidth: lineWidth)
        case .circle:
            Circle()
                .strokeBorder(color, lineWidth: lineWidth)
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
                shape: .roundedRectangle(radius: 20),
                isSelected: isRoundedRectangleButtonSelected,
                hasOutline: true
            ) {
                isRoundedRectangleButtonSelected.toggle()
            } label: {
                Label("Save", systemImage: "square.and.arrow.down.fill")
                    .fontWeight(.semibold)
            }

            SelectableButton(
                shape: .circle,
                selectionFillColor: .yellow,
                selectionTextColor: .yellow,
                padding: 16,
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
