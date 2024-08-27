//
//  SFSymbolGroupBox.swift
//  iOS
//
//  Created by Grigor Dochev on 22.08.2024.
//

import SwiftUI

// MARK: - SFSymbolGroupBoxStyle Protocol

protocol SFSymbolGroupBoxStyle {
    associatedtype Body: View
    func makeBody(configuration: SFSymbolGroupBoxStyleConfiguration) -> Body
}

struct SFSymbolGroupBoxStyleConfiguration {
    let label: SFSymbolLabel
    let description: Text?
    let content: AnyView
    let button: AnyView?
}

// MARK: - Type-Erased Style Wrapper

struct AnySFSymbolGroupBoxStyle: SFSymbolGroupBoxStyle {
    private let _makeBody: (SFSymbolGroupBoxStyleConfiguration) -> AnyView
    
    init<Style: SFSymbolGroupBoxStyle>(_ style: Style) {
        _makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }
    
    func makeBody(configuration: SFSymbolGroupBoxStyleConfiguration) -> some View {
        _makeBody(configuration)
    }
}

// MARK: - Styles Enum

enum SFSymbolGroupBoxStyleType {
    case plain
    case divider
}

// MARK: - Plain Style

struct PlainSFSymbolGroupBoxStyle: SFSymbolGroupBoxStyle {
    func makeBody(configuration: SFSymbolGroupBoxStyleConfiguration) -> some View {
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

struct DividerSFSymbolGroupBoxStyle: SFSymbolGroupBoxStyle {
    func makeBody(configuration: SFSymbolGroupBoxStyleConfiguration) -> some View {
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .foregroundStyle(Color(.secondarySystemGroupedBackground))
        }
    }
}

// MARK: - Environment Key for Style

private struct SFSymbolGroupBoxStyleKey: EnvironmentKey {
    static var defaultValue: AnySFSymbolGroupBoxStyle {
        AnySFSymbolGroupBoxStyle(PlainSFSymbolGroupBoxStyle())
    }
}

extension EnvironmentValues {
    var sfSymbolGroupBoxStyle: AnySFSymbolGroupBoxStyle {
        get { self[SFSymbolGroupBoxStyleKey.self] }
        set { self[SFSymbolGroupBoxStyleKey.self] = newValue }
    }
}

// MARK: - SFSymbolGroupBox

struct SFSymbolGroupBox<Content: View, Button: View>: View {
    let label: SFSymbolLabel
    let description: Text?
    let content: Content
    let button: Button?
    @Environment(\.sfSymbolGroupBoxStyle) private var style
    
    init(
        label: SFSymbolLabel,
        description: Text? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder button: () -> Button? = { nil }
    ) {
        self.label = label
        self.description = description
        self.content = content()
        self.button = button()
    }
    
    var body: some View {
        style.makeBody(configuration: .init(
            label: label,
            description: description,
            content: AnyView(content),
            button: button.map { AnyView($0) }
        ))
    }
}

// MARK: - Custom Style Modifiers

struct SFSymbolGroupBoxStyleModifier: ViewModifier {
    let style: AnySFSymbolGroupBoxStyle
    
    func body(content: Content) -> some View {
        content.environment(\.sfSymbolGroupBoxStyle, style)
    }
}

extension View {
    func symbolGroupBoxStyle(_ style: SFSymbolGroupBoxStyleType) -> some View {
        switch style {
        case .plain:
            return self.modifier(SFSymbolGroupBoxStyleModifier(style: AnySFSymbolGroupBoxStyle(PlainSFSymbolGroupBoxStyle())))
        case .divider:
            return self.modifier(SFSymbolGroupBoxStyleModifier(style: AnySFSymbolGroupBoxStyle(DividerSFSymbolGroupBoxStyle())))
        }
    }
}

// MARK: - Convenience Initializer for No Button

extension SFSymbolGroupBox where Button == EmptyView {
    init(
        label: SFSymbolLabel,
        description: Text? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            label: label,
            description: description,
            content: content,
            button: { EmptyView() }
        )
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var isExpanded = false
    @Previewable @Namespace var namespace
    
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
        
        SFSymbolGroupBox(
            label: SFSymbolLabel(icon: "figure.walk", title: "Steps", labelColor: Color("BrandPrimary")),
            description: Text("This is my description.").font(.subheadline.weight(.semibold))
        ) {
            Text("Content with a default style")
        } button: {
            Button(action: {
                isExpanded.toggle()
            }) {
                SFSymbolIcon(name: "chevron.down", color: Color("BrandPrimary"), variant: .circle)
            }
        }
        .symbolGroupBoxStyle(.divider)
        .padding()
    }
}
