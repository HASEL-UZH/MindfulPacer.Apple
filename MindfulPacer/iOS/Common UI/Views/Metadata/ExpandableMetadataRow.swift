//
//  ExpandableMetadataRow.swift
//  iOS
//
//  Created by Grigor Dochev on 03.07.2026.
//

import SwiftUI

// MARK: - Expandable Metadata Row

struct ExpandableMetadataRowStyle {
    var rowVerticalPadding: CGFloat = 6
    var activeBoxHorizontalOutset: CGFloat = 12
    var activeBoxVerticalOutset: CGFloat = 4
    var activeBoxCornerRadius: CGFloat = 24
    var expandedContentSpacing: CGFloat = 10
    var animation: Animation = .snappy(duration: 0.28)
    var activeBackground: Color = Color(.secondarySystemGroupedBackground)
    var activeShadow: Color = .black.opacity(0.08)

    static let reflections = ExpandableMetadataRowStyle()
}

struct ExpandableMetadataRow<ID: Hashable, RowContent: View, RowAccessory: View, ExpandedContent: View>: View {
    @Binding private var activeID: ID?

    private let id: ID
    private let style: ExpandableMetadataRowStyle
    private let expandedContentLeadingInset: CGFloat
    private let rowContent: (Bool) -> RowContent
    private let rowAccessory: (Bool) -> RowAccessory
    private let expandedContent: () -> ExpandedContent

    private var isActive: Bool {
        activeID == id
    }

    init(
        id: ID,
        activeID: Binding<ID?>,
        style: ExpandableMetadataRowStyle = .reflections,
        expandedContentLeadingInset: CGFloat = 0,
        @ViewBuilder rowContent: @escaping (Bool) -> RowContent,
        @ViewBuilder rowAccessory: @escaping (Bool) -> RowAccessory,
        @ViewBuilder expandedContent: @escaping () -> ExpandedContent
    ) {
        self.id = id
        self._activeID = activeID
        self.style = style
        self.expandedContentLeadingInset = expandedContentLeadingInset
        self.rowContent = rowContent
        self.rowAccessory = rowAccessory
        self.expandedContent = expandedContent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isActive ? style.expandedContentSpacing : 0) {
            HStack(alignment: .top, spacing: 8) {
                Button {
                    activateIfNeeded()
                } label: {
                    rowContent(isActive)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)

                rowAccessory(isActive)
            }

            if isActive {
                expandedContent()
                    .padding(.leading, expandedContentLeadingInset)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }
        }
        .padding(.vertical, style.rowVerticalPadding)
        .background {
            if isActive {
                RoundedRectangle(cornerRadius: style.activeBoxCornerRadius, style: .continuous)
                    .fill(style.activeBackground)
                    .shadow(color: style.activeShadow, radius: 18, y: 8)
                    .padding(.horizontal, -style.activeBoxHorizontalOutset)
                    .padding(.vertical, -style.activeBoxVerticalOutset)
            }
        }
        .animation(style.animation, value: isActive)
    }

    private func activateIfNeeded() {
        guard !isActive else { return }
        withAnimation(style.animation) {
            activeID = id
        }
    }
}

extension ExpandableMetadataRow where RowAccessory == EmptyView {
    init(
        id: ID,
        activeID: Binding<ID?>,
        style: ExpandableMetadataRowStyle = .reflections,
        expandedContentLeadingInset: CGFloat = 0,
        @ViewBuilder rowContent: @escaping (Bool) -> RowContent,
        @ViewBuilder expandedContent: @escaping () -> ExpandedContent
    ) {
        self.init(
            id: id,
            activeID: activeID,
            style: style,
            expandedContentLeadingInset: expandedContentLeadingInset,
            rowContent: rowContent
        ) { _ in
            EmptyView()
        } expandedContent: {
            expandedContent()
        }
    }
}

struct ExpandableMetadataScroll<Content: View>: View {
    private let spacing: CGFloat
    private let content: () -> Content

    init(
        spacing: CGFloat = 8,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: spacing) {
                content()
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 1)
        }
        .scrollIndicators(.hidden)
        .safeAreaPadding(.trailing, 10)
        .transaction { transaction in
            transaction.animation = nil
        }
    }
}

struct ExpandableMetadataChip: View {
    let title: String
    let systemImage: String
    let isActive: Bool
    var tint: Color = Color("BrandPrimary")

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))

            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(isActive ? tint : .secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            Capsule(style: .continuous)
                .fill(Color(.tertiarySystemGroupedBackground))
        }
        .contentShape(.rect)
    }
}

struct ExpandableMetadataChipButton: View {
    let title: String
    let systemImage: String
    let isActive: Bool
    var tint: Color = Color("BrandPrimary")
    var role: ButtonRole?
    let action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            ExpandableMetadataChip(
                title: title,
                systemImage: systemImage,
                isActive: isActive,
                tint: tint
            )
        }
        .buttonStyle(.plain)
    }
}

struct ExpandableMetadataMenuChip<MenuContent: View>: View {
    let title: String
    let systemImage: String
    let isActive: Bool
    var tint: Color = Color("BrandPrimary")
    private let menuContent: () -> MenuContent

    init(
        title: String,
        systemImage: String,
        isActive: Bool,
        tint: Color = Color("BrandPrimary"),
        @ViewBuilder menuContent: @escaping () -> MenuContent
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isActive = isActive
        self.tint = tint
        self.menuContent = menuContent
    }

    var body: some View {
        Menu {
            menuContent()
        } label: {
            ExpandableMetadataChip(
                title: title,
                systemImage: systemImage,
                isActive: isActive,
                tint: tint
            )
        }
    }
}
