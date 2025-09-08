//
//  DeviceModeSettingsView.swift
//  iOS
//
//  Created by Grigor Dochev on 04.09.2025.
//

import SwiftUI

extension SettingsView {
    struct DeviceModeSettingsView: View {

        @Bindable var viewModel: SettingsViewModel
        @AppStorage(DeviceMode.appStorageKey) private var deviceMode: DeviceMode = .iPhoneOnly

        var body: some View {
            ScrollView {
                IconLabelGroupBox(
                    label:
                        IconLabel(
                            icon: "iphone.motion",
                            title: "Device Selection",
                            labelColor: Color("BrandPrimary"),
                            background: true
                        ),
                    description:
                        Text(String(localized: "Please select which devices you want to use MindfulPacer on."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                ) {
                    VStack(spacing: 16) {
                        ForEach(DeviceMode.allCases) { mode in
                            let isSelectable = (mode == .iPhoneOnly) || viewModel.isWatchAppInstalled
                            
                            SelectableButton(
                                shape: .roundedRectangle(cornerRadius: 16),
                                backgroundColor: Color(.tertiarySystemGroupedBackground),
                                isSelected: viewModel.deviceMode == mode
                            ) {
                                if isSelectable {
                                    viewModel.deviceMode = mode
                                    deviceMode = mode
                                }
                            } label: {
                                IconLabel(
                                    icon: mode.icon,
                                    title: mode.localized,
                                    description: mode.description,
                                    titleColor: viewModel.deviceMode == mode ? Color("BrandPrimary")
                                    : (isSelectable ? .primary : .secondary),
                                    iconColor: viewModel.deviceMode == mode ? Color("BrandPrimary")
                                    : (isSelectable ? .primary : .secondary),
                                    descriptionTextColor: viewModel.deviceMode == mode ? Color("BrandPrimary").opacity(0.7)
                                    : (isSelectable ? .secondary : .secondary.opacity(0.7)),
                                    background: true
                                )
                                .redacted(reason: (mode == .iPhoneAndWatch && !viewModel.isWatchAppInstalled) ? .placeholder : .init())
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .overlay(alignment: .bottomTrailing) {
                                    if mode == .iPhoneAndWatch && !viewModel.isWatchAppInstalled {
                                        Label(
                                            String(localized: "Requires Watch App"),
                                            systemImage: "exclamationmark.triangle.fill"
                                        )
                                        .font(.caption2.weight(.semibold))
                                        .padding(6)
                                        .background(.thinMaterial, in: Capsule())
                                    }
                                }
                                .opacity(isSelectable ? 1.0 : 0.6)
                            }
                            .disabled(!isSelectable)
                        }
                    }
                } footer: {
                    if !viewModel.isWatchAppInstalled {
                        VStack(alignment: .leading, spacing: 4) {
                            IconLabel(
                                icon: "applewatch",
                                title: String(localized: "To use “iPhone + Apple Watch”, install and set up the MindfulPacer Watch app first."),
                                labelColor: .secondary
                            )
                            .font(.footnote)

                            Button {
                                viewModel.navigationPath.append(.appleWatch)
                            } label: {
                                IconLabel(
                                    icon: "arrow.right.circle.fill",
                                    title: String(localized: "Open Apple Watch Setup"),
                                    labelColor: .brandPrimary
                                )
                                .font(.footnote.weight(.semibold))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .iconLabelGroupBoxStyle(.divider)
                .padding(.horizontal)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(String(localized: "Device Mode"))
            .onAppear {
                if viewModel.deviceMode == .iPhoneAndWatch && !viewModel.isWatchAppInstalled {
                    viewModel.deviceMode = .iPhoneOnly
                    deviceMode = .iPhoneOnly
                }
            }
            .onChange(of: viewModel.deviceMode) { _, newValue in
                deviceMode = newValue
            }
        }
    }
}

#Preview {
    let viewModel: SettingsViewModel = ScenesContainer.shared.settingsViewModel()
    return NavigationStack {
        SettingsView.DeviceModeSettingsView(viewModel: viewModel)
    }
}
