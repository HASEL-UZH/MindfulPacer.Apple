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
        @Environment(\.scenePhase) private var scenePhase
        
        @Bindable var viewModel: SettingsViewModel
        
        // MARK: Body
        
        var body: some View {
            if viewModel.isWatchAppInstalled {
                RoundedList {
                    Section {
                        IconLabelGroupBox(
                            label: IconLabel(
                                icon: "antenna.radiowaves.left.and.right",
                                title: "Connection",
                                labelColor: Color("BrandPrimary"),
                                background: true
                            ),
                            description: Text("Live status of the connection to your Apple Watch.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        ) {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Connection Status")
                                    Spacer()
                                    IconLabel(
                                        icon: viewModel.watchConnectionStatus.symbolName,
                                        title: viewModel.watchConnectionStatus.rawValue,
                                        labelColor: viewModel.watchConnectionStatus.color
                                    )
                                    .font(.subheadline.weight(.semibold))
                                }
                                
                                HStack {
                                    Text("Connection Speed")
                                    Spacer()
                                    IconLabel(
                                        icon: viewModel.watchConnectionSpeed.symbolName,
                                        title: viewModel.watchConnectionSpeed.rawValue,
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
                .task(id: viewModel.isWatchAppInstalled) {
                    guard viewModel.isWatchAppInstalled else { return }
                    ConnectivityService.shared.startPinging()
                }
                
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .active:
                        if viewModel.isWatchAppInstalled {
                            ConnectivityService.shared.startPinging()
                        }
                    case .inactive, .background:
                        ConnectivityService.shared.stopPinging()
                    @unknown default:
                        ConnectivityService.shared.stopPinging()
                    }
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
                
                .onAppear {
                    ConnectivityService.shared.stopPinging()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: SettingsViewModel = ScenesContainer.shared.settingsViewModel()
    
    NavigationStack {
        SettingsView.AppleWatchView(viewModel: viewModel)
    }
}
