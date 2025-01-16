//
//  IconLabel.swift
//  iOS
//
//  Created by Grigor Dochev on 15.08.2024.
//

import SwiftUI

// MARK: - IconLabelStyle Protocol

protocol IconLabelStyle {
    associatedtype Body: View
    func makeBody(configuration: IconLabelStyleConfiguration) -> Body
}

struct IconLabelStyleConfiguration {
    let icon: String?
    let image: String?
    let title: String
    let description: String?
    let textColor: Color?
    let iconColor: Color?
    let labelColor: Color?
    let descriptionTextColor: Color?
    let symbolVariant: SymbolVariants
    let symbolRenderingMode: SymbolRenderingMode
    let background: Bool
    let axis: Axis
    let truncationMode: Text.TruncationMode
}

// MARK: - Type-Erased Style Wrapper

struct AnyIconLabelStyle: IconLabelStyle {
    private let _makeBody: (IconLabelStyleConfiguration) -> AnyView

    init<Style: IconLabelStyle>(_ style: Style) {
        _makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    func makeBody(configuration: IconLabelStyleConfiguration) -> some View {
        _makeBody(configuration)
    }
}

// MARK: - Styles Enum

enum IconLabelStyleType {
    case plain
    case pill
}

// MARK: - Plain Style

struct PlainIconLabelStyle: IconLabelStyle {
    func makeBody(configuration: IconLabelStyleConfiguration) -> some View {
        Group {
            switch configuration.axis {
            case .horizontal:
                Label {
                    if let description = configuration.description {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(configuration.title)
                                .foregroundStyle(configuration.labelColor ?? configuration.textColor ?? .primary)
                                .truncationMode(configuration.truncationMode) // Apply truncation mode
                            Text(description)
                                .font(.subheadline)
                                .foregroundStyle(configuration.descriptionTextColor ?? Color.secondary)
                        }
                    } else {
                        Text(configuration.title)
                            .foregroundStyle(configuration.labelColor ?? configuration.textColor ?? .primary)
                            .truncationMode(configuration.truncationMode) // Apply truncation mode
                    }
                } icon: {
                    Icon(
                        name: configuration.icon,
                        image: configuration.image,
                        color: configuration.labelColor ?? configuration.iconColor ?? .primary,
                        variant: configuration.symbolVariant,
                        renderingMode: configuration.symbolRenderingMode,
                        background: configuration.background
                    )
                }
            case .vertical:
                VStack(alignment: .leading, spacing: 8) {
                    Icon(
                        name: configuration.icon,
                        image: configuration.image,
                        color: configuration.labelColor ?? configuration.iconColor ?? .primary,
                        variant: configuration.symbolVariant,
                        renderingMode: configuration.symbolRenderingMode,
                        background: configuration.background
                    )
                    
                    if let description = configuration.description {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(configuration.title)
                                .foregroundStyle(configuration.labelColor ?? configuration.textColor ?? .primary)
                                .truncationMode(configuration.truncationMode) // Apply truncation mode
                            Text(description)
                                .font(.subheadline)
                                .foregroundStyle(configuration.descriptionTextColor ?? Color.secondary)
                        }
                    } else {
                        Text(configuration.title)
                            .foregroundStyle(configuration.labelColor ?? configuration.textColor ?? .primary)
                            .truncationMode(configuration.truncationMode)
                    }
                }
            }
        }
    }
}

// MARK: - Pill Style

struct PillIconLabelStyle: IconLabelStyle {
    func makeBody(configuration: IconLabelStyleConfiguration) -> some View {
        Group {
            switch configuration.axis {
            case .horizontal:
                Label {
                    Text(configuration.title)
                        .foregroundStyle(configuration.labelColor ?? configuration.textColor ?? .primary)
                        .truncationMode(configuration.truncationMode) // Apply truncation mode
                } icon: {
                    Icon(
                        name: configuration.icon,
                        image: configuration.image,
                        color: configuration.labelColor ?? configuration.iconColor ?? .primary,
                        variant: configuration.symbolVariant,
                        renderingMode: configuration.symbolRenderingMode,
                        background: configuration.background
                    )
                }
            case .vertical:
                VStack(alignment: .leading, spacing: 8) {
                    Icon(
                        name: configuration.icon,
                        image: configuration.image,
                        color: configuration.labelColor ?? configuration.iconColor ?? .primary,
                        variant: configuration.symbolVariant,
                        renderingMode: configuration.symbolRenderingMode,
                        background: configuration.background
                    )

                    Text(configuration.title)
                        .foregroundStyle(configuration.labelColor ?? configuration.textColor ?? .primary)
                        .truncationMode(configuration.truncationMode)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .foregroundStyle(configuration.labelColor?.opacity(0.1) ?? .secondary.opacity(0.1))
        }
    }
}

// MARK: - Environment Key for Style

private struct IconLabelStyleKey: EnvironmentKey {
    static var defaultValue: AnyIconLabelStyle {
        AnyIconLabelStyle(PlainIconLabelStyle())
    }
}

extension EnvironmentValues {
    var iconLabelStyle: AnyIconLabelStyle {
        get { self[IconLabelStyleKey.self] }
        set { self[IconLabelStyleKey.self] = newValue }
    }
}

// MARK: - IconLabel

struct IconLabel: View {
    var icon: String?
    var image: String?
    var title: String
    var description: String?
    var titleColor: Color?
    var iconColor: Color?
    var labelColor: Color?
    var descriptionTextColor: Color?
    var symbolVariant: SymbolVariants = .fill
    var symbolRenderingMode: SymbolRenderingMode = .monochrome
    var background: Bool = false
    var axis: Axis = .horizontal
    var truncationMode: Text.TruncationMode = .middle

    @Environment(\.iconLabelStyle) private var style

    var body: some View {
        style.makeBody(configuration: .init(
            icon: icon,
            image: image,
            title: title,
            description: description,
            textColor: titleColor,
            iconColor: iconColor,
            labelColor: labelColor,
            descriptionTextColor: descriptionTextColor,
            symbolVariant: symbolVariant,
            symbolRenderingMode: symbolRenderingMode,
            background: background,
            axis: axis,
            truncationMode: truncationMode
        ))
    }
}

// MARK: - Custom Style Modifiers

struct IconLabelStyleModifier: ViewModifier {
    let style: AnyIconLabelStyle

    func body(content: Content) -> some View {
        content.environment(\.iconLabelStyle, style)
    }
}

extension View {
    func iconLabelStyle(_ style: IconLabelStyleType) -> some View {
        switch style {
        case .plain:
            return self.modifier(IconLabelStyleModifier(style: AnyIconLabelStyle(PlainIconLabelStyle())))
        case .pill:
            return self.modifier(IconLabelStyleModifier(style: AnyIconLabelStyle(PillIconLabelStyle())))
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        IconLabel(
            icon: "figure.walk",
            title: "Walking",
            description: "Your total step count.",
            titleColor: .blue,
            labelColor: .teal,
            background: true
        )
        
        IconLabel(
            image: "MindfulPacer Icon",
            title: "Custom Icon",
            labelColor: .brandPrimary,
            background: true,
            truncationMode: .tail
        )
    }
}
