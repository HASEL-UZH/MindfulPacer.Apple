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
                showSkipButton: false
            ) {
                IconLabelGroupBox(
                    label: IconLabel(
                        icon: "power",
                        title: String(localized: "MindfulPacer Modes"),
                        labelColor: Color("BrandPrimary"),
                        background: true
                    ),
                    description: Text(String(localized: "Please select which mode you want to use MindfulPacer with. You can switch between the mode anytime in the settings."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                ) {
                    VStack(spacing: 16) {
                        ForEach(ModeOfUse.allCases) { mode in
                            SelectableButton(
                                shape: .roundedRectangle(cornerRadius: 16),
                                backgroundColor: Color(.tertiarySystemGroupedBackground),
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
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                } footer:  {
                    IconLabel(
                        icon: "info.circle.fill",
                        title: String(localized: "You can always change this later on in the app settings."),
                        labelColor: .secondary
                    )
                    .font(.footnote)
                }
                .iconLabelGroupBoxStyle(.divider)
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
