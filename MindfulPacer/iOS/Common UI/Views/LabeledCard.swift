//
//  LabeledCard.swift
//  iOS
//
//  Created by Grigor Dochev on 03.07.2026.
//

import SwiftUI

// MARK: - LabeledCard

struct LabeledCard<Label: View, Accessory: View, Content: View>: View {
    private let label: Label
    private let accessory: Accessory
    private let content: Content
    private let contentSpacing: CGFloat
    private let contentPadding: CGFloat
    private let cornerRadius: CGFloat
    private let action: (() -> Void)?
    private let actionAccessibilityIdentifier: String

    @Environment(\.backgroundStyle) private var backgroundStyle
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        contentSpacing: CGFloat = 32,
        contentPadding: CGFloat = 16,
        cornerRadius: CGFloat = 24,
        action: (() -> Void)? = nil,
        actionAccessibilityIdentifier: String = "",
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.content = content()
        self.label = label()
        self.accessory = accessory()
        self.contentSpacing = contentSpacing
        self.contentPadding = contentPadding
        self.cornerRadius = cornerRadius
        self.action = action
        self.actionAccessibilityIdentifier = actionAccessibilityIdentifier
    }

    init(
        contentSpacing: CGFloat = 32,
        contentPadding: CGFloat = 16,
        cornerRadius: CGFloat = 24,
        action: (() -> Void)? = nil,
        actionAccessibilityIdentifier: String = "",
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label
    ) where Accessory == EmptyView {
        self.content = content()
        self.label = label()
        self.accessory = EmptyView()
        self.contentSpacing = contentSpacing
        self.contentPadding = contentPadding
        self.cornerRadius = cornerRadius
        self.action = action
        self.actionAccessibilityIdentifier = actionAccessibilityIdentifier
    }

    private var headerLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 12))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: contentSpacing) {
            if let action {
                Button(action: action) {
                    header.contentShape(.rect)
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier(actionAccessibilityIdentifier)
            } else {
                header
            }

            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(contentPadding)
        .background {
            if let action {
                // Keep the card action behind, rather than around, its content controls.
                Button(action: action) {
                    surface.contentShape(.rect(cornerRadius: cornerRadius))
                }
                .buttonStyle(.borderless)
                .accessibilityHidden(true)
            } else {
                surface
            }
        }
        .containerShape(.rect(cornerRadius: cornerRadius, style: .continuous))
    }

    private var header: some View {
        headerLayout {
            label
                .frame(maxWidth: .infinity, alignment: .leading)
                .labelIconToTitleSpacing(4)
                .font(.subheadline.weight(.semibold))
            accessory
        }
    }

    private var surface: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(backgroundStyle ?? AnyShapeStyle(Color(.secondarySystemGroupedBackground)))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        LabeledCard {
            Text("Content")
        } label: {
            Label {
                Text("Apple Health")
            } icon: {
                Image(systemName: "heart.fill")
            }
            .foregroundStyle(.pink)
        } accessory: {
            Image(systemName: "chevron.right")
                .foregroundStyle(Color(.systemGray2))
        }
        .padding()
    }
}
