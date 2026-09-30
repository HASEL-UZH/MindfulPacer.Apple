import SwiftUI

struct ReleaseNotesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ReleaseNotesViewModel = ScenesContainer.shared.releaseNotesViewModel()

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.releaseNotes) { release in
                    Section {
                        ForEach(Array(release.notes.enumerated()), id: \.offset) { _, note in
                            Text(note)
                                .foregroundStyle(Color.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    } header: {
                        Text("Version \(release.version)")
                    }
                }
            }
            .navigationTitle("Release Notes")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.markWhatsNewSeen()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview { ReleaseNotesView() }
