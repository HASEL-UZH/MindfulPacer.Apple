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
            List {
                if viewModel.isWatchAppInstalled {
                    Section {
                        LabeledContent("Connection Status") {
                            Label(viewModel.watchConnectionStatus.description,
                                  systemImage: viewModel.watchConnectionStatus.symbolName)
                                .foregroundStyle(viewModel.watchConnectionStatus.color)
                        }
                        LabeledContent("Connection Speed") {
                            Label(viewModel.watchConnectionSpeed.description,
                                  systemImage: viewModel.watchConnectionSpeed.symbolName)
                                .foregroundStyle(viewModel.watchConnectionSpeed.color)
                        }
                    } header: {
                        Text("Connection")
                    } footer: {
                        Text("Live status of the connection to your Apple Watch.")
                    }
                } else {
                    Section {
                        Label("App Not Installed", systemImage: "exclamationmark.applewatch")
                            .foregroundStyle(Color.primary)
                        Button("How to Install") {
                            openURL(viewModel.appleWatchInstallationHelp)
                        }
                    } footer: {
                        Text("The Apple Watch app needs to be installed. Please install it from the Watch app on your iPhone.")
                    }
                }
            }
            .navigationTitle("Apple Watch")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if viewModel.isWatchAppInstalled { ConnectivityService.shared.startPinging() }
            }
            .onDisappear {
                ConnectivityService.shared.stopPinging()
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
