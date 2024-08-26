//
//  InfoSheetView.swift
//  iOS
//
//  Created by Grigor Dochev on 18.08.2024.
//

import SwiftUI

struct InfoSheetView<Content: View>: View {
    var title: String
    var info: String? = nil
    var content: () -> Content

    init(
        title: String,
        info: String?,
        @ViewBuilder content: @escaping () -> Content
    ) {
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
                    if let info {
                        InfoBox(text: info)
                            .padding(.horizontal)
                    }
                    
                    ViewThatFits {
                        content()
                            .padding(.horizontal)
                        ScrollView {
                            content()
                                .padding(.horizontal)
                        }
                    }

                    Spacer()
                }
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
    init(title: String, info: String? = nil) {
        self.title = title
        self.info = info
        self.content = { EmptyView() }
    }
}

// MARK: - Preview

#Preview {
    InfoSheetView(title: "Information", info: "This is some information.") {
        Text("This is some text.")
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
