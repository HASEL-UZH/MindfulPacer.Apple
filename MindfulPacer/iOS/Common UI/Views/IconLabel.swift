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
    let icon: String
    let title: String
    let textColor: Color?
    let iconColor: Color?
    let labelColor: Color?
    let symbolVariant: SymbolVariants
    let symbolRenderingMode: SymbolRenderingMode
    let background: Bool
    let axis: Axis
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
                    Text(configuration.title)
                        .foregroundStyle(configuration.labelColor ?? configuration.textColor ?? .primary)
                        .truncationMode(.middle)
                } icon: {
                    Icon(
                        name: configuration.icon,
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
                        color: configuration.labelColor ?? configuration.iconColor ?? .primary,
                        variant: configuration.symbolVariant,
                        renderingMode: configuration.symbolRenderingMode,
                        background: configuration.background
                    )

                    Text(configuration.title)
                        .foregroundStyle(configuration.labelColor ?? configuration.textColor ?? .primary)
                        .truncationMode(.middle)
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
                        .truncationMode(.middle)
                } icon: {
                    Icon(
                        name: configuration.icon,
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
                        color: configuration.labelColor ?? configuration.iconColor ?? .primary,
                        variant: configuration.symbolVariant,
                        renderingMode: configuration.symbolRenderingMode,
                        background: configuration.background
                    )

                    Text(configuration.title)
                        .foregroundStyle(configuration.labelColor ?? configuration.textColor ?? .primary)
                        .truncationMode(.middle)
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
    var icon: String
    var title: String
    var textColor: Color?
    var iconColor: Color?
    var labelColor: Color?
    var symbolVariant: SymbolVariants = .fill
    var symbolRenderingMode: SymbolRenderingMode = .monochrome
    var background: Bool = false
    var axis: Axis = .horizontal

    @Environment(\.iconLabelStyle) private var style

    var body: some View {
        style.makeBody(configuration: .init(
            icon: icon,
            title: title,
            textColor: textColor,
            iconColor: iconColor,
            labelColor: labelColor,
            symbolVariant: symbolVariant,
            symbolRenderingMode: symbolRenderingMode,
            background: background,
            axis: axis
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
        IconLabel(icon: "figure.walk", title: "Walking", textColor: .blue, iconColor: .pink, background: true)

        IconLabel(icon: "heart.fill", title: "Heart Rate", labelColor: .pink, background: false)
            .iconLabelStyle(.pill)
    }
}
