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
                systemImage: "iphone.gen3",
                showSkipButton: false
            ) {
                Text("Please select which devices you want to use MindfulPacer on.")
                    .foregroundStyle(Color.secondary)
                VStack(spacing: 12) {
                    ForEach(DeviceMode.allCases) { mode in
                        ChoiceRow(title: mode.localized, description: mode.description,
                                  isSelected: viewModel.selectedDeviceMode == mode) {
                            viewModel.selectedDeviceMode = mode
                        }
                    }
                }
                Text("You can always change this later on in the app settings.")
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
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
