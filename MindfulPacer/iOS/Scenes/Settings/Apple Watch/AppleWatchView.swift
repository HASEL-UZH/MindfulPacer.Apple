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
        
        @Environment(\.openURL) private var openURL
        @Bindable var viewModel: SettingsViewModel

        // MARK: Body
        
        var body: some View {
            if viewModel.isWatchAppInstalled {
                List {
                    Section {
                        LabeledContent {
                            Label(
                                viewModel.watchConnectionStatus.description,
                                systemImage: viewModel.watchConnectionStatus.symbolName
                            )
                            .foregroundStyle(viewModel.watchConnectionStatus.color)
                        } label: {
                            Text("Connection Status")
                        }

                        LabeledContent {
                            Label(
                                viewModel.watchConnectionSpeed.description,
                                systemImage: viewModel.watchConnectionSpeed.symbolName
                            )
                            .foregroundStyle(viewModel.watchConnectionSpeed.color)
                        } label: {
                            Text("Connection Speed")
                        }
                    } header: {
                        Text("Connection")
                    } footer: {
                        Text("Live status of the connection to your Apple Watch.")
                    }
                }
                .navigationTitle("Apple Watch")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    ConnectivityService.shared.startPinging()
                }
                .onDisappear {
                    ConnectivityService.shared.stopPinging()
                }
            } else {
                ContentUnavailableView {
                    Label("App Not Installed", systemImage: "exclamationmark.applewatch")
                } description: {
                    Text("The Apple Watch app needs to be installed. Please install it from the Watch app on your iPhone.")
                } actions: {
                    Button {
                        openURL(viewModel.appleWatchInstallationHelp)
                    } label: {
                        Text("How to Install")
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                }
                .navigationTitle("Apple Watch")
                .background {
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()
                }
                .navigationBarTitleDisplayMode(.inline)
            }
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
