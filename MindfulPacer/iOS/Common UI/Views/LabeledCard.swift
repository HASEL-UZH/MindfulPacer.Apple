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

    @Environment(\.backgroundStyle) private var backgroundStyle

    init(
        contentSpacing: CGFloat = 24,
        contentPadding: CGFloat = 16,
        cornerRadius: CGFloat = 24,
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
    }

    init(
        contentSpacing: CGFloat = 24,
        contentPadding: CGFloat = 16,
        cornerRadius: CGFloat = 24,
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label
    ) where Accessory == EmptyView {
        self.content = content()
        self.label = label()
        self.accessory = EmptyView()
        self.contentSpacing = contentSpacing
        self.contentPadding = contentPadding
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        VStack(alignment: .leading, spacing: contentSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                label
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .labelIconToTitleSpacing(4)
                    .font(.subheadline.weight(.semibold))

                accessory
            }

            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(contentPadding)
        .background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    backgroundStyle
                    ?? AnyShapeStyle(Color(.secondarySystemGroupedBackground))
                )
        }
        .containerShape(.rect(cornerRadius: cornerRadius, style: .continuous))
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
