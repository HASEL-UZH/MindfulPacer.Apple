//
//  ModeOfUseView.swift
//  iOS
//
//  Created by Grigor Dochev on 07.11.2024.
//

import SwiftUI

// MARK: - ModeOfUseView

extension OnboardingView {
    struct ModeOfUseView: View {
        
        @Bindable var viewModel: OnboardingViewModel
        
        @AppStorage(ModeOfUse.appStorageKey, store: DefaultsStore.shared)
        private var modeOfUseRaw: String = ModeOfUse.essentials.rawValue
        
        private var modeOfUseBinding: Binding<ModeOfUse> {
            Binding(
                get: { ModeOfUse(rawValue: modeOfUseRaw) ?? .essentials },
                set: { modeOfUseRaw = $0.rawValue }
            )
        }
        
        var body: some View {
            OnboardingPage(
                viewModel: viewModel,
                title: String(localized: "Mode of Use"),
                systemImage: "slider.horizontal.3",
                showSkipButton: false
            ) {
                Text("Please select which mode you want to use MindfulPacer with. You can switch between the mode anytime in the settings.")
                    .foregroundStyle(Color.secondary)
                VStack(spacing: 12) {
                    ForEach(ModeOfUse.allCases) { mode in
                        ChoiceRow(title: mode.localized, description: mode.description,
                                  isSelected: viewModel.selectedModeOfUse == mode) {
                            viewModel.selectedModeOfUse = mode
                        }
                    }
                }
                Text("You can always change this later on in the app settings.")
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
            }
            .onAppear {
                if viewModel.selectedModeOfUse == nil {
                    viewModel.selectedModeOfUse = ModeOfUse(rawValue: modeOfUseRaw) ?? .essentials
                }
            }
            .onChange(of: viewModel.selectedModeOfUse) { _, newValue in
                if let newValue {
                    modeOfUseBinding.wrappedValue = newValue
                }
            }
        }
    }
}
// MARK: - Preview

#Preview {
    let viewModel: OnboardingViewModel = ScenesContainer.shared.onboardingViewModel()
    
    OnboardingView.ModeOfUseView(viewModel: viewModel)
}
