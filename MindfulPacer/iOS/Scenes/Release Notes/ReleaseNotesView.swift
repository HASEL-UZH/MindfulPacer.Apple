//
//  ReleaseNotesView.swift
//  iOS
//
//  Created by Grigor Dochev on 26.08.2025.
//

import SwiftUI

// MARK: - ReleaseNotesView

struct ReleaseNotesView: View {

    // MARK: Properties

    @Environment(\.dismiss) private var dismiss
    @State var viewModel: ReleaseNotesViewModel = ScenesContainer.shared.releaseNotesViewModel()

    // MARK: Body

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.releaseNotes) { release in
                    Section {
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
                    } header: {
                        Text("Version \(release.version)")
                            .font(.title3.bold())
                            .foregroundStyle(Color.primary)
                            .textCase(nil)
                    }
                }
            }
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
}

// MARK: - Preview

#Preview {
    ReleaseNotesView()
}
