//
//  DeviceModeSettingsView.swift
//  iOS
//
//  Created by Grigor Dochev on 04.09.2025.
//

import SwiftUI

// MARK: - DeviceModeSettingsView

extension SettingsView {
    struct DeviceModeSettingsView: View {

        @Bindable var viewModel: SettingsViewModel
        
        @AppStorage(DeviceMode.appStorageKey, store: DefaultsStore.shared)
        private var deviceModeRaw: String = DeviceMode.iPhoneAndWatch.rawValue
        
        private var deviceModeBinding: Binding<DeviceMode> {
            Binding<DeviceMode>(
                get: { DeviceMode(rawValue: deviceModeRaw) ?? .iPhoneAndWatch },
                set: { deviceModeRaw = $0.rawValue }
            )
        }
        
        var body: some View {
            List {
                Section {
                    ForEach(DeviceMode.allCases) { mode in
                        let isSelectable = (mode == .iPhoneOnly) || viewModel.isWatchAppInstalled

                        Button {
                            guard isSelectable else { return }
                            deviceModeBinding.wrappedValue = mode
                            viewModel.deviceMode = mode
                            viewModel.presentAlert(.restartApp)
                        } label: {
                            HStack(alignment: .center) {
                                SettingsRowLabel(
                                    title: mode.localized,
                                    subtitle: mode.description,
                                    systemImage: mode.settingsIcon
                                )
                                .opacity(isSelectable ? 1.0 : 0.55)

                                Spacer()

                                if viewModel.deviceMode == mode {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                } else if !isSelectable {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(!isSelectable)
                    }
                } header: {
                    Text("Device Selection")
                } footer: {
                    if !viewModel.isWatchAppInstalled {
                        Text("To use “iPhone + Apple Watch”, install and set up the MindfulPacer Watch app first.")
                    } else {
                        Text("Choose which devices MindfulPacer should use for reminders and activity tracking.")
                    }
                }

                if !viewModel.isWatchAppInstalled {
                    Section {
                        Button {
                            viewModel.navigationPath.append(.appleWatch)
                        } label: {
                            Label("Open Apple Watch Setup", systemImage: "applewatch")
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle(String(localized: "Device Mode"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if !viewModel.isWatchAppInstalled && deviceModeBinding.wrappedValue == .iPhoneAndWatch {
                    deviceModeBinding.wrappedValue = .iPhoneOnly
                    viewModel.deviceMode = .iPhoneOnly
                } else {
                    if viewModel.deviceMode != deviceModeBinding.wrappedValue {
                        viewModel.deviceMode = deviceModeBinding.wrappedValue
                    }
                }
            }
            .onChange(of: deviceModeRaw) { _, _ in
                let mode = deviceModeBinding.wrappedValue
                if viewModel.deviceMode != mode {
                    viewModel.deviceMode = mode
                }
                Task { await MissedReflectionsMonitorService.shared.onDeviceModeChanged(mode) }
            }
        }
    }
}

private extension DeviceMode {
    var settingsIcon: String {
        switch self {
        case .iPhoneAndWatch:
            "applewatch.radiowaves.left.and.right"
        case .iPhoneOnly:
            "iphone.circle.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: SettingsViewModel = ScenesContainer.shared.settingsViewModel()
    return NavigationStack {
        SettingsView.DeviceModeSettingsView(viewModel: viewModel)
    }
}
