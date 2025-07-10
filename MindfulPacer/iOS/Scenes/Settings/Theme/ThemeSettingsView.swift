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
        
        @AppStorage(Theme.appStorageKey) private var theme: Theme = .system
        
        // MARK: Body
        
        var body: some View {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Theme.allCases) { theme in
                        SelectableButton(
                            shape: .roundedRectangle(cornerRadius: 16),
                            isSelected: self.theme == theme
                        ) {
                            self.theme = theme
                        } label: {
                            HStack {
                                IconLabel(
                                    icon: theme.icon,
                                    title: theme.localized,
                                    description: theme.description,
                                    labelColor: self.theme == theme ? .brandPrimary : theme.labelColor,
                                    descriptionTextColor: self.theme == theme ? .brandPrimary : theme.labelColor.opacity(0.7),
                                    background: true
                                )
                                .font(.subheadline.weight(.semibold))
                                Spacer()
                                if self.theme == theme {
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
    NavigationStack {
        SettingsView.ThemeSettingsView()
    }
}
