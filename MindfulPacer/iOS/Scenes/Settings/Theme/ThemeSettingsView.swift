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
            List {
                Section {
                    ForEach(Theme.allCases) { theme in
                        Button {
                            self.theme = theme
                        } label: {
                            HStack {
                                SettingsRowLabel(
                                    title: theme.localized,
                                    subtitle: theme.description,
                                    systemImage: theme.settingsIcon
                                )

                                Spacer()

                                if self.theme == theme {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } footer: {
                    Text("System follows your device appearance. Light and Dark override it for MindfulPacer only.")
                }
            }
            .navigationTitle("Theme")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private extension Theme {
    var settingsIcon: String {
        switch self {
        case .system:
            "circle.lefthalf.filled.righthalf.striped.horizontal.inverse"
        case .light:
            "sun.max.fill"
        case .dark:
            "moon.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView.ThemeSettingsView()
    }
}
