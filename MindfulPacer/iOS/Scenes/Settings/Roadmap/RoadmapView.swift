//
//  RoadmapView.swift
//  iOS
//
//  Created by Grigor Dochev on 18.12.2024.
//

import SwiftUI

// MARK: - RoadmapView

extension SettingsView {
    struct RoadmapView: View {
        
        // MARK: Properties
        
        @Bindable var viewModel: SettingsViewModel
        
        // MARK: Body
        
        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 16) {                        
                        ForEach(viewModel.roadmapItems) { roadmapItem in
                            roadmapItemCell(roadmapItem: roadmapItem)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Roadmap")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        CloseButton()
                    }
                }
                .overlay {
                    if viewModel.isFetchingRoadmap {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Color("BrandPrimary"))
                    }
                }
            }
        }
        
        // MARK: Roadmap Item Cell
        
        @ViewBuilder
        func roadmapItemCell(roadmapItem: RoadmapItem) -> some View {
            IconLabelGroupBox(
                label: IconLabel(
                    icon: roadmapItem.platform.icon,
                    image: roadmapItem.platform.image,
                    title: roadmapItem.platform.rawValue,
                    labelColor: roadmapItem.platform.color,
                    background: true
                ),
                description:
                    Text(roadmapItem.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(roadmapItem.comment)
                    IconLabel(title: roadmapItem.status.rawValue.capitalized, labelColor: roadmapItem.status.color)
                        .font(.footnote).fontWeight(.semibold)
                        .iconLabelStyle(.pill)
                }
            }
            .iconLabelGroupBoxStyle(.divider)
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: SettingsViewModel = ScenesContainer.shared.settingsViewModel()
    
    SettingsView.RoadmapView(viewModel: viewModel)
        .onAppear {
//            viewModel.onViewAppear()
        }
}
