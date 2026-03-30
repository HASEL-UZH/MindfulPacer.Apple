//
//  WhatsNewView.swift
//  iOS
//
//  Created by Grigor Dochev on 26.08.2025.
//

import SwiftUI

// MARK: - WhatsNewView

struct WhatsNewView: View {

    // MARK: Properties

    @Environment(\.dismiss) private var dismiss
    @State var viewModel: WhatsNewViewModel = ScenesContainer.shared.whatsNewViewModel()

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(viewModel.releaseNotes) { release in
                        releaseSection(release)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(String(localized: "Release Notes"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Done")) {
                        viewModel.markWhatsNewSeen()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func releaseSection(_ release: ReleaseNote) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Version \(release.version)")
                .font(.title3.bold())
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(release.notes.enumerated()), id: \.offset) { _, note in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Color.brandPrimary)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)

                        Text(note)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        }
    }
}

// MARK: - Preview

#Preview {
    WhatsNewView()
}
