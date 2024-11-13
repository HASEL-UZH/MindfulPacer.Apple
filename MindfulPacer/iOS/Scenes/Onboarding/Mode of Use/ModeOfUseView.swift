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
        
        // MARK: Body
        
        var body: some View {
            OnboardingPage(
                viewModel: viewModel,
                title: "Mode of Use",
                showSkipButton: false
            ) {
                VStack(spacing: 16) {
                    InfoBox(text: "Please select which mode you want to use MindfulPacer with. You can switch between the mode anytime in the settings.")
                    
                    ForEach(ModeOfUse.allCases) { mode in
                        SelectableButton(
                            shape: .roundedRectangle(cornerRadius: 16),
                            isSelected: viewModel.selectedModeOfUse == mode
                        ) {
                            viewModel.selectedModeOfUse = mode
                        } label: {
                            IconLabel(
                                image: Image(mode.icon),
                                title: mode.name,
                                description: mode.description,
                                textColor: viewModel.selectedModeOfUse == mode ? Color("BrandPrimary") : Color.primary,
                                iconColor: viewModel.selectedModeOfUse == mode ? Color("BrandPrimary") : Color.primary,
                                descriptionTextColor: viewModel.selectedModeOfUse == mode ? Color("BrandPrimary").opacity(0.7) : Color.secondary,
                                background: true
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
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
