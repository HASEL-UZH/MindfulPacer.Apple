//
//  RoundedList.swift
//  iOS
//
//  Created by Grigor Dochev on 07.09.2024.
//

import SwiftUI

// MARK: - RoundedList

struct RoundedList<Content: View>: View {
    // MARK: Properties

    @ViewBuilder var content: Content

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Group(sections: content) { sections in
                    ForEach(sections) { section in
                        VStack(spacing: 8) {
                            if !section.header.isEmpty {
                                section.header
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading)
                            }

                            VStack(spacing: 0) {
                                ForEach(section.content) { subview in
                                    subview
                                        .overlay(alignment: .bottom) {
                                            if subview.id != section.content.last!.id {
                                                Divider()
                                                    .padding(.leading)
                                            }
                                        }
                                }
                            }
                            .cornerRadius(16)

                            if !section.footer.isEmpty {
                                section.footer
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading)
                            }
                        }
                    }
                }
            }
            .padding([.horizontal, .bottom])
        }
        .background {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RoundedList {
            Section {
                ForEach(0..<5) { index in
                    NavigationLink {
                        Text("View \(index)")
                    } label: {
                        HStack {
                            Text("Row \(index)")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Color(.systemGray2))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                    }
                }
            } footer: {
                Text("This is my section footer.")
                    .font(.subheadline)
            }
        }
        .navigationTitle("Rounded List")
    }
}
