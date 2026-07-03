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

    @Environment(\.backgroundStyle) private var backgroundStyle

    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.content = content()
        self.label = label()
        self.accessory = accessory()
    }

    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label
    ) where Accessory == EmptyView {
        self.content = content()
        self.label = label()
        self.accessory = EmptyView()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
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
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    backgroundStyle
                    ?? AnyShapeStyle(Color(.secondarySystemGroupedBackground))
                )
        }
        .containerShape(.rect(cornerRadius: 24, style: .continuous))
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
