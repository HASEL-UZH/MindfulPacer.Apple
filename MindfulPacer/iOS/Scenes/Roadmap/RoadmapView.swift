import SwiftUI

struct RoadmapView: View {
    @State private var viewModel: RoadmapViewModel = ScenesContainer.shared.roadMapViewModel()

    var body: some View {
        NavigationStack {
            List {
                if viewModel.roadmapItems.isEmpty {
                    Section {
                        if viewModel.isFetchingRoadmap {
                            ProgressView("Loading Roadmap")
                        } else {
                            Text(viewModel.fetchErrorMessage == nil
                                 ? String(localized: "No Updates Yet") : String(localized: "Unable to Load Roadmap"))
                            Text(viewModel.fetchErrorMessage == nil
                                 ? String(localized: "Check back soon for upcoming features.")
                                 : String(localized: "Check your connection and try again."))
                                .foregroundStyle(Color.secondary)
                            Button("Try Again", action: viewModel.onViewAppear)
                        }
                    }
                }
                Section {
                    ForEach(viewModel.roadmapItems) { item in
                        roadmapItemCell(item)
                    }
                } header: {
                    Text("Follow what’s next for MindfulPacer.")
                }
            }
            .navigationTitle("Roadmap")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { CloseButton() }
            }
            .onViewFirstAppear { viewModel.onViewAppear() }
        }
    }

    private func roadmapItemCell(_ item: RoadmapItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            IconLabel(
                icon: item.platform.icon,
                image: item.platform.image,
                title: item.platform.rawValue,
                labelColor: item.platform.color
            )
            .font(.subheadline)

            Text(item.description)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)

            if !item.comment.isEmpty {
                Text(item.comment)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(item.status.rawValue.capitalized)
                .font(.caption.weight(.semibold))
                .foregroundStyle(item.status.color)
        }
    }
}

#Preview { RoadmapView() }
