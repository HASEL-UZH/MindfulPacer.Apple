//
//  DeviceModeView.swift
//  iOS
//
//  Created by Grigor Dochev on 04.09.2025.
//

import SwiftUI

// MARK: - DeviceModeView

extension OnboardingView {
    struct DeviceModeView: View {
        @Bindable var viewModel: OnboardingViewModel

        @AppStorage(DeviceMode.appStorageKey, store: DefaultsStore.shared)
        private var deviceModeRaw: String = DeviceMode.iPhoneAndWatch.rawValue

        private var deviceModeBinding: Binding<DeviceMode> {
            Binding(
                get: { DeviceMode(rawValue: deviceModeRaw) ?? .iPhoneAndWatch },
                set: { deviceModeRaw = $0.rawValue }
            )
        }

        var body: some View {
            OnboardingPage(
                viewModel: viewModel,
                title: String(localized: "Device Mode"),
                showSkipButton: false
            ) {
                IconLabelGroupBox(
                    label: IconLabel(
                        icon: "iphone.motion",
                        title: String(localized: "Device Selection"),
                        labelColor: Color("BrandPrimary"),
                        background: true
                    ),
                    description: Text(String(localized: "Please select which devices you want to use MindfulPacer on."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                ) {
                    VStack(spacing: 16) {
                        ForEach(DeviceMode.allCases) { mode in
                            SelectableButton(
                                shape: .roundedRectangle(cornerRadius: 16),
                                backgroundColor: Color(.tertiarySystemGroupedBackground),
                                isSelected: viewModel.selectedDeviceMode == mode
                            ) {
                                viewModel.selectedDeviceMode = mode
                            } label: {
                                IconLabel(
                                    icon: mode.icon,
                                    title: mode.localized,
                                    description: mode.description,
                                    titleColor: viewModel.selectedDeviceMode == mode ? Color("BrandPrimary") : Color.primary,
                                    iconColor: viewModel.selectedDeviceMode == mode ? Color("BrandPrimary") : Color.primary,
                                    descriptionTextColor: viewModel.selectedDeviceMode == mode ? Color("BrandPrimary").opacity(0.7) : Color.secondary,
                                    background: true
                                )
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                } footer: {
                    IconLabel(
                        icon: "info.circle.fill",
                        title: String(localized: "You can always change this later on in the app settings."),
                        labelColor: .secondary
                    )
                    .font(.footnote)
                }
                .iconLabelGroupBoxStyle(.divider)
                .iconLabelGroupBoxStyle(.divider)
            }
            .onAppear {
                if viewModel.selectedDeviceMode == nil {
                    viewModel.selectedDeviceMode = DeviceMode(rawValue: deviceModeRaw) ?? .iPhoneAndWatch
                }
            }
            .onChange(of: viewModel.selectedDeviceMode) { _, newValue in
                if let newValue {
                    deviceModeBinding.wrappedValue = newValue
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: OnboardingViewModel = ScenesContainer.shared.onboardingViewModel()
    
    OnboardingView.DeviceModeView(viewModel: viewModel)
}
