//
//  InfoSheet.swift
//  iOS
//
//  Created by Grigor Dochev on 18.08.2024.
//

import SwiftUI

// MARK: - InfoSheet

struct InfoSheet<Content: View>: View {
    
    // MARK: Properties

    var title: String
    var info: String?
    @ViewBuilder var content: Content

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let info {
                        Text(info)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    content
                }
                .frame(maxWidth: 680, alignment: .leading)
                .frame(maxWidth: .infinity)
                .padding()
            }
            .background(Color(.systemGroupedBackground))
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

// MARK: - EmptyView Extension

extension InfoSheet where Content == EmptyView {
    init(title: String, info: String? = nil) {
        self.title = title
        self.info = info
        self.content = { EmptyView() }()
    }
}

// MARK: - Preview

#Preview {
    InfoSheet(title: "Information", info: "This is some information.") {
        Text("This is some text.")
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
