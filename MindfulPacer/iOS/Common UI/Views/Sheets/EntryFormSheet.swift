//
//  EntryFormSheet.swift
//  iOS
//
//  Created by Grigor Dochev on 03.07.2026.
//

import SwiftUI

// MARK: - Entry Form Sheet

enum EntryFormSheetHeaderMedia {
    case systemImage(String)
    case image(Image)
}

struct EntryFormSheet<PrimaryContent: View, Content: View, AdditionalToolbarContent: ToolbarContent>: View {

    let title: String
    let headerTitle: String
    let headerMedia: EntryFormSheetHeaderMedia
    let headerTint: Color
    let canSave: Bool
    let onCancel: () -> Void
    let onSave: () -> Void
    @ViewBuilder let primaryContent: () -> PrimaryContent
    @ViewBuilder let content: () -> Content
    @ToolbarContentBuilder let additionalToolbarContent: () -> AdditionalToolbarContent

    init(
        title: String,
        headerTitle: String,
        headerSystemImage: String,
        headerTint: Color = .accentColor,
        canSave: Bool = true,
        onCancel: @escaping () -> Void,
        onSave: @escaping () -> Void,
        @ViewBuilder primaryContent: @escaping () -> PrimaryContent,
        @ViewBuilder content: @escaping () -> Content,
        @ToolbarContentBuilder additionalToolbarContent: @escaping () -> AdditionalToolbarContent
    ) {
        self.init(
            title: title,
            headerTitle: headerTitle,
            headerMedia: .systemImage(headerSystemImage),
            headerTint: headerTint,
            canSave: canSave,
            onCancel: onCancel,
            onSave: onSave,
            primaryContent: primaryContent,
            content: content,
            additionalToolbarContent: additionalToolbarContent
        )
    }

    init(
        title: String,
        headerTitle: String,
        headerImage: Image,
        headerTint: Color = .accentColor,
        canSave: Bool = true,
        onCancel: @escaping () -> Void,
        onSave: @escaping () -> Void,
        @ViewBuilder primaryContent: @escaping () -> PrimaryContent,
        @ViewBuilder content: @escaping () -> Content,
        @ToolbarContentBuilder additionalToolbarContent: @escaping () -> AdditionalToolbarContent
    ) {
        self.init(
            title: title,
            headerTitle: headerTitle,
            headerMedia: .image(headerImage),
            headerTint: headerTint,
            canSave: canSave,
            onCancel: onCancel,
            onSave: onSave,
            primaryContent: primaryContent,
            content: content,
            additionalToolbarContent: additionalToolbarContent
        )
    }

    init(
        title: String,
        headerTitle: String,
        headerMedia: EntryFormSheetHeaderMedia,
        headerTint: Color = .accentColor,
        canSave: Bool = true,
        onCancel: @escaping () -> Void,
        onSave: @escaping () -> Void,
        @ViewBuilder primaryContent: @escaping () -> PrimaryContent,
        @ViewBuilder content: @escaping () -> Content,
        @ToolbarContentBuilder additionalToolbarContent: @escaping () -> AdditionalToolbarContent
    ) {
        self.title = title
        self.headerTitle = headerTitle
        self.headerMedia = headerMedia
        self.headerTint = headerTint
        self.canSave = canSave
        self.onCancel = onCancel
        self.onSave = onSave
        self.primaryContent = primaryContent
        self.content = content
        self.additionalToolbarContent = additionalToolbarContent
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    primaryContent()
                } header: {
                    header
                        .textCase(nil)
                }

                content()
            }
            .listStyle(.insetGrouped)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
    }
}

private extension EntryFormSheet {
    var header: some View {
        VStack(spacing: 24) {
            headerGraphic

            Text(headerTitle)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Color.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical)
        .padding(.top)
    }

    @ViewBuilder
    var headerGraphic: some View {
        switch headerMedia {
        case .systemImage(let systemImage):
            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .padding(24)
                .background(Color(.secondarySystemGroupedBackground), in: Circle())
                .foregroundStyle(headerTint)

        case .image(let image):
            image
                .resizable()
                .scaledToFill()
                .frame(width: 96, height: 96)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(Color(.separator).opacity(0.2), lineWidth: 1)
                }
        }
    }

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel", role: .cancel) {
                onCancel()
            }
        }

        ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
                onSave()
            }
            .disabled(!canSave)
        }

        additionalToolbarContent()
    }
}
