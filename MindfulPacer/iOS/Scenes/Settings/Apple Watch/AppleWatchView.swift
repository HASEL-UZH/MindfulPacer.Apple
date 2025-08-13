//
//  AppleWatchView.swift
//  iOS
//
//  Created by Grigor Dochev on 12.08.2025.
//

import SwiftUI

// MARK: - AppleWatchView

extension SettingsView {
    struct AppleWatchView: View {
        
        // MARK: Properties
        
        @Bindable var viewModel: SettingsViewModel
        
        // MARK: Body
        
        var body: some View {
            RoundedList {
                Section {
                    IconLabelGroupBox(
                        label:
                            IconLabel(
                                icon: "applewatch",
                                title: "MindfulPacer Screen",
                                labelColor: Color("BrandPrimary"),
                                background: true
                            ),
                        description:
                            Text("Ideally, the MindfulPacer home screen can always be displayed on your watch.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    ) {
                        Image(.appleWatchReturnToClock)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 350, alignment: .top)
                            .clipped()
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(
                                [
                                    "Open the Watch app on your iPhone",
                                    "Go to General > Return to Clock > MindfulPacer",
                                    "Toggle 'Return to App' to on."
                                ], id: \.self) { point in
                                    HStack(alignment: .top) {
                                        Text("•")
                                        Text(point)
                                            .multilineTextAlignment(.leading)
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                        }
                    }
                    .iconLabelGroupBoxStyle(.divider)
                }
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Apple Watch")
        }
    }
}

// MARK: - Previewo

#Preview {
    let viewModel: SettingsViewModel = ScenesContainer.shared.settingsViewModel()
    
    NavigationStack {
        SettingsView.AppleWatchView(viewModel: viewModel)
    }
}
