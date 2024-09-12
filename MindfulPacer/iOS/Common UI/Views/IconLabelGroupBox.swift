//
//  IconLabelGroupBox.swift
//  iOS
//
//  Created by Grigor Dochev on 22.08.2024.
//

import SwiftUI

// MARK: - IconLabelGroupBoxStyle Protocol

protocol IconLabelGroupBoxStyle {
    associatedtype Body: View
    func makeBody(configuration: IconLabelGroupBoxStyleConfiguration) -> Body
}

struct IconLabelGroupBoxStyleConfiguration {
    let label: IconLabel
    let description: Text?
    let content: AnyView
    let accessoryIndicator: AnyView?
    let footer: AnyView?
}

// MARK: - Type-Erased Style Wrapper

struct AnyIconLabelGroupBoxStyle: IconLabelGroupBoxStyle {
    private let _makeBody: (IconLabelGroupBoxStyleConfiguration) -> AnyView

    init<Style: IconLabelGroupBoxStyle>(_ style: Style) {
        _makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    func makeBody(configuration: IconLabelGroupBoxStyleConfiguration) -> some View {
        _makeBody(configuration)
    }
}

// MARK: - Styles Enum

enum IconLabelGroupBoxStyleType {
    case plain
    case divider
}

// MARK: - Plain Style

struct PlainIconLabelGroupBoxStyle: IconLabelGroupBoxStyle {
    func makeBody(configuration: IconLabelGroupBoxStyleConfiguration) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                configuration.label
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
                    .layoutPriority(1)

                if let accessoryIndicator = configuration.accessoryIndicator {
                    accessoryIndicator
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }

            if let description = configuration.description {
                description
            }

            configuration.content

            if let footer = configuration.footer {
                footer
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .foregroundStyle(Color(.secondarySystemGroupedBackground))
        }
    }
}

// MARK: - Divider Style

struct DividerIconLabelGroupBoxStyle: IconLabelGroupBoxStyle {
    func makeBody(configuration: IconLabelGroupBoxStyleConfiguration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    configuration.label
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .layoutPriority(1)

                    if let accessoryIndicator = configuration.accessoryIndicator {
                        accessoryIndicator
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }

                if let description = configuration.description {
                    description
                }
            }
            .padding()

            Divider()

            configuration.content
                .padding()

            if let footer = configuration.footer {
                Divider()

                footer
                    .padding()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .foregroundStyle(Color(.secondarySystemGroupedBackground))
        }
    }
}

// MARK: - Environment Key for Style

private struct IconLabelGroupBoxStyleKey: EnvironmentKey {
    static var defaultValue: AnyIconLabelGroupBoxStyle {
        AnyIconLabelGroupBoxStyle(PlainIconLabelGroupBoxStyle())
    }
}

extension EnvironmentValues {
    var iconLabelGroupBoxStyle: AnyIconLabelGroupBoxStyle {
        get { self[IconLabelGroupBoxStyleKey.self] }
        set { self[IconLabelGroupBoxStyleKey.self] = newValue }
    }
}

// MARK: - IconLabelGroupBox

struct IconLabelGroupBox<Content: View, AccessoryIndicator: View, Footer: View>: View {
    let label: IconLabel
    let description: Text?
    let content: Content
    let accessoryIndicator: AccessoryIndicator?
    let footer: Footer?
    @Environment(\.iconLabelGroupBoxStyle) private var style

    init(
        label: IconLabel,
        description: Text? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder accessoryIndicator: () -> AccessoryIndicator? = { nil },
        @ViewBuilder footer: () -> Footer? = { nil }
    ) {
        self.label = label
        self.description = description
        self.content = content()
        self.accessoryIndicator = accessoryIndicator()
        self.footer = footer()
    }

    var body: some View {
        style.makeBody(configuration: .init(
            label: label,
            description: description,
            content: AnyView(content),
            accessoryIndicator: accessoryIndicator.map { AnyView($0) },
            footer: footer.map { AnyView($0) }
        ))
    }
}

// MARK: - Custom Style Modifiers

struct IconLabelGroupBoxStyleModifier: ViewModifier {
    let style: AnyIconLabelGroupBoxStyle

    func body(content: Content) -> some View {
        content.environment(\.iconLabelGroupBoxStyle, style)
    }
}

extension View {
    func iconLabelGroupBoxStyle(_ style: IconLabelGroupBoxStyleType) -> some View {
        switch style {
        case .plain:
            return self.modifier(IconLabelGroupBoxStyleModifier(style: AnyIconLabelGroupBoxStyle(PlainIconLabelGroupBoxStyle())))
        case .divider:
            return self.modifier(IconLabelGroupBoxStyleModifier(style: AnyIconLabelGroupBoxStyle(DividerIconLabelGroupBoxStyle())))
        }
    }
}

// MARK: - Convenience Initializer for No Accessory Indicator or Footer

extension IconLabelGroupBox where AccessoryIndicator == EmptyView, Footer == EmptyView {
    init(
        label: IconLabel,
        description: Text? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder accessoryIndicator: () -> AccessoryIndicator? = { nil },
        @ViewBuilder footer: () -> Footer? = { nil }
    ) {
        self.label = label
        self.description = description
        self.content = content()
        self.accessoryIndicator = accessoryIndicator()
        self.footer = footer()
    }
}

// MARK: - Convenience Initializer for Footer, No Accessory Indicator

extension IconLabelGroupBox where AccessoryIndicator == EmptyView {
    init(
        label: IconLabel,
        description: Text? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder accessoryIndicator: () -> AccessoryIndicator? = { nil },
        @ViewBuilder footer: () -> Footer
    ) {
        self.label = label
        self.description = description
        self.content = content()
        self.accessoryIndicator = accessoryIndicator()
        self.footer = footer()
    }
}

// MARK: - Convenience Initializer for Accessory Indicator, No Footer

extension IconLabelGroupBox where Footer == EmptyView {
    init(
        label: IconLabel,
        description: Text? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder accessoryIndicator: () -> AccessoryIndicator,
        @ViewBuilder footer: () -> Footer? = { nil }
    ) {
        self.label = label
        self.description = description
        self.content = content()
        self.accessoryIndicator = accessoryIndicator()
        self.footer = footer()
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var isExpanded = false
    @Previewable @Namespace var namespace

    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        VStack(spacing: 32) {
            IconLabelGroupBox(
                label: IconLabel(icon: "figure.walk", title: "Steps", labelColor: .teal),
                description: Text("This is my description.").font(.subheadline.weight(.semibold))
            ) {
                Text("Content with a default style")
            } accessoryIndicator: {
                Button {
                    isExpanded.toggle()
                } label: {
                    Icon(name: "chevron.down", color: Color("BrandPrimary"), variant: .circle)
                }
            }
            .iconLabelGroupBoxStyle(.divider)
            .padding()

            IconLabelGroupBox(
                label: IconLabel(icon: "heart", title: "Heart Rate", labelColor: .pink),
                description: Text("This is my description.").font(.subheadline.weight(.semibold))
            ) {
                Text("Content with a default style")
            } footer: {
                Text("This is my footer.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .iconLabelGroupBoxStyle(.divider)
            .padding()
        }
    }
}
