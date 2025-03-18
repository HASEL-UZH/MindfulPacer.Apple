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
        
        // MARK: Properties
        
        @Bindable var viewModel: OnboardingViewModel
        @AppStorage(ModeOfUse.appStorageKey) private var modeOfUse: ModeOfUse = .essentials
        
        // MARK: Body
        
        var body: some View {
            OnboardingPage(
                viewModel: viewModel,
                title: String(localized: "Mode of Use"),
                showSkipButton: false
            ) {
                VStack(spacing: 16) {
                    InfoBox(text: String(localized: "Please select which mode you want to use MindfulPacer with. You can switch between the mode anytime in the settings."))
                    
                    ForEach(ModeOfUse.allCases) { mode in
                        SelectableButton(
                            shape: .roundedRectangle(cornerRadius: 16),
                            isSelected: viewModel.selectedModeOfUse == mode
                        ) {
                            viewModel.selectedModeOfUse = mode
                        } label: {
                            IconLabel(
                                image: mode.icon,
                                title: mode.localized,
                                description: mode.description,
                                titleColor: viewModel.selectedModeOfUse == mode ? Color("BrandPrimary") : Color.primary,
                                iconColor: viewModel.selectedModeOfUse == mode ? Color("BrandPrimary") : Color.primary,
                                descriptionTextColor: viewModel.selectedModeOfUse == mode ? Color("BrandPrimary").opacity(0.7) : Color.secondary,
                                background: true
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .onChange(of: viewModel.selectedModeOfUse) { _, newValue in
                if let newValue {
                    modeOfUse = newValue
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
