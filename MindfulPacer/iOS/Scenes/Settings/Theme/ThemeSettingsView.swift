//
//  ThemeSettingsView.swift
//  iOS
//
//  Created by Grigor Dochev on 15.10.2024.
//

import SwiftUI

// MARK: - ThemeSettingsView

extension SettingsView {
    struct ThemeSettingsView: View {
        
        // MARK: Properties
        
        @Bindable var viewModel: SettingsViewModel
        
        // MARK: Body
        
        var body: some View {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Theme.allCases) { theme in
                        SelectableButton(
                            shape: .roundedRectangle(cornerRadius: 16),
                            isSelected: viewModel.selectedTheme == theme
                        ) {
                            viewModel.setTheme(to: theme)
                        } label: {
                            HStack {
                                IconLabel(
                                    icon: theme.icon,
                                    title: theme.rawValue,
                                    description: theme.description,
                                    textColor: viewModel.selectedTheme == theme ? Color("BrandPrimary") : Color.primary,
                                    iconColor: viewModel.selectedTheme == theme ? Color("BrandPrimary") : Color.primary,
                                    descriptionTextColor: viewModel.selectedTheme == theme ? Color("BrandPrimary").opacity(0.7) : Color.secondary
                                )
                                Spacer()
                                if viewModel.selectedTheme == theme {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Theme")
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: SettingsViewModel = ScenesContainer.shared.settingsViewModel()
    
    NavigationStack {
        SettingsView.ThemeSettingsView(viewModel: viewModel)
    }
}
