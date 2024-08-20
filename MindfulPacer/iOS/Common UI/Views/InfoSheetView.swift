//
//  InfoSheetView.swift
//  iOS
//
//  Created by Grigor Dochev on 18.08.2024.
//

import SwiftUI

struct InfoSheetView<Content: View>: View {
    let title: String
    let info: String
    let content: () -> Content

    init(title: String, info: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.info = info
        self.content = content
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    InfoBox(text: info)

                    // Display content if provided
                    content()

                    Spacer()
                }
                .padding(.horizontal)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CloseButton()
                }
            }
        }
    }
}

extension InfoSheetView where Content == EmptyView {
    init(title: String, info: String) {
        self.title = title
        self.info = info
        self.content = { EmptyView() }
    }
}

// MARK: - Preview

#Preview {
    InfoSheetView(title: "Information", info: "This is some info.")
}
