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
                RoundedList {
                    Section {
                        IconLabelGroupBox(
                            label: IconLabel(
                                icon: "antenna.radiowaves.left.and.right",
                                title: String(localized: "Connection"),
                                labelColor: Color("BrandPrimary"),
                                background: true
                            ),
                            description: Text(String(localized: "Live status of the connection to your Apple Watch."))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        ) {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Connection Status")
                                    Spacer()
                                    IconLabel(
                                        icon: viewModel.watchConnectionStatus.symbolName,
                                        title: viewModel.watchConnectionStatus.description,
                                        labelColor: viewModel.watchConnectionStatus.color
                                    )
                                    .font(.subheadline.weight(.semibold))
                                }
                                
                                HStack {
                                    Text("Connection Speed")
                                    Spacer()
                                    IconLabel(
                                        icon: viewModel.watchConnectionSpeed.symbolName,
                                        title: viewModel.watchConnectionSpeed.description,
                                        labelColor: viewModel.watchConnectionSpeed.color
                                    )
                                    .font(.subheadline.weight(.semibold))
                                }
                            }
                        }
                        .iconLabelGroupBoxStyle(.divider)
                    }
                    .frame(maxWidth: .infinity)
                }
                .navigationTitle("Apple Watch")
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
