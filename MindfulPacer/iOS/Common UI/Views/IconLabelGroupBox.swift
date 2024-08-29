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
    let button: AnyView?
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
                
                if let button = configuration.button {
                    button
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
                    
                    if let button = configuration.button {
                        button
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
    var IconLabelGroupBoxStyle: AnyIconLabelGroupBoxStyle {
        get { self[IconLabelGroupBoxStyleKey.self] }
        set { self[IconLabelGroupBoxStyleKey.self] = newValue }
    }
}

// MARK: - IconLabelGroupBox

struct IconLabelGroupBox<Content: View, Button: View, Footer: View>: View {
    let label: IconLabel
    let description: Text?
    let content: Content
    let button: Button?
    let footer: Footer?
    @Environment(\.IconLabelGroupBoxStyle) private var style
    
    init(
        label: IconLabel,
        description: Text? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder button: () -> Button? = { nil },
        @ViewBuilder footer: () -> Footer? = { nil }
    ) {
        self.label = label
        self.description = description
        self.content = content()
        self.button = button()
        self.footer = footer()
    }
    
    var body: some View {
        style.makeBody(configuration: .init(
            label: label,
            description: description,
            content: AnyView(content),
            button: button.map { AnyView($0) },
            footer: footer.map { AnyView($0) }
        ))
    }
}

// MARK: - Custom Style Modifiers

struct IconLabelGroupBoxStyleModifier: ViewModifier {
    let style: AnyIconLabelGroupBoxStyle
    
    func body(content: Content) -> some View {
        content.environment(\.IconLabelGroupBoxStyle, style)
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

// MARK: - Convenience Initializer for No Button or Footer

extension IconLabelGroupBox where Button == EmptyView, Footer == EmptyView {
    init(
        label: IconLabel,
        description: Text? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder button: () -> Button? = { nil },
        @ViewBuilder footer: () -> Footer? = { nil }
    ) {
        self.label = label
        self.description = description
        self.content = content()
        self.button = button()
        self.footer = footer()
    }
}

// MARK: - Convenience Initializer for Footer, No Button

extension IconLabelGroupBox where Button == EmptyView {
    init(
        label: IconLabel,
        description: Text? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder button: () -> Button? = { nil },
        @ViewBuilder footer: () -> Footer
    ) {
        self.label = label
        self.description = description
        self.content = content()
        self.button = button()
        self.footer = footer()
    }
}

// MARK: - Convenience Initializer for Button, No Footer

extension IconLabelGroupBox where Footer == EmptyView {
    init(
        label: IconLabel,
        description: Text? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder button: () -> Button,
        @ViewBuilder footer: () -> Footer? = { nil }
    ) {
        self.label = label
        self.description = description
        self.content = content()
        self.button = button()
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
            } button: {
                Button(action: {
                    isExpanded.toggle()
                }) {
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
