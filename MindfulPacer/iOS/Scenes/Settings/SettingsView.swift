//
//  SettingsView.swift
//  iOS
//
//  Created by Grigor Dochev on 13.09.2024.
//

import SwiftUI

// MARK: - Presentation Enums

enum SettingsSheet: Identifiable {
    case onboardingView
    case mailView

    var id: Int {
        hashValue
    }
}

// MARK: - SettingsView

struct SettingsView: View {
    // MARK: Properties
    
    @Environment(\.openURL) private var openURL
    @State private var viewModel: SettingsViewModel = ScenesContainer.shared.settingsViewModel()
    
    // MARK: Body
    
    var body: some View {
        NavigationStack {
            RoundedList {
                Section {
                    viewOnboarding
                } header: {
                    sectionHeader(title: "General")
                }
                
                Section {
                    support
                    moreInfo
                    privacyPolicy
                } header: {
                    sectionHeader(title: "About")
                }

                version
            }
            .navigationTitle("Settings")
            .sheet(item: $viewModel.activeSheet) { sheet in
                sheetContent(for: sheet)
            }
        }
    }
    
    // MARK: Sheets

    @ViewBuilder
    private func sheetContent(for sheet: SettingsSheet) -> some View {
        switch sheet {
        case .onboardingView:
            OnboardingView()
                .presentationCornerRadius(16)
                .presentationDragIndicator(.visible)
        case .mailView:
            MailView(result: $viewModel.mailResult)
        }
    }
    
    // MARK: Section Header
    
    @ViewBuilder
    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }
    
    // MARK: Support
    
    private var support: some View {
        Button {
            viewModel.presentSheet(.mailView)
        } label: {
            settingsCell(
                icon: "envelope",
                title: "Contact Us",
                accessoryIndicatorIcon: "arrow.up.forward.square"
            )
        }
    }
    
    // MARK: - More Info
    
    private var moreInfo: some View {
        Button {
            openURL(URL(string: "https://mindfulpacer.ch")!)
        } label: {
            settingsCell(
                icon: "info",
                title: "More Info",
                accessoryIndicatorIcon: "link"
            )
        }
    }
    
    // MARK: - Privacy Policy
    
    private var privacyPolicy: some View {
        Button {
            openURL(URL(string: "https://mindfulpacer.ch/privacy-policy/")!)
        } label: {
            settingsCell(
                icon: "hand.raised",
                title: "Privacy Policy",
                accessoryIndicatorIcon: "link"
            )
        }
    }
    
    // MARK: View Onboarding
    
    private var viewOnboarding: some View {
        Button {
            viewModel.presentSheet(.onboardingView)
        } label: {
            settingsCell(
                icon: "square.stack",
                title: "Onboarding",
                description: "View the onboarding again",
                accessoryIndicatorIcon: "arrow.up.forward.square"
            )
        }
    }

    // MARK: Version
    
    private var version: some View {
        VStack(spacing: 8) {
            Image("MindfulPacer Icon")
                .resizable()
                .scaledToFit()
                .frame(height: 32)
            
            Text("MindfulPacer Version 1.0.0")
                .font(.subheadline.weight(.thin))
                .foregroundStyle(.secondary)
        }
        .padding()
    }
    
    // MARK: Settings Cell
    
    @ViewBuilder func settingsCell(
        icon: String,
        title: String,
        description: String? = nil,
        accessoryIndicatorIcon: String? = nil
    ) -> some View {
        HStack {
            IconLabel(
                icon: icon,
                title: title,
                description: description,
                labelColor: Color("BrandPrimary"),
                background: true
            )
            .font(.subheadline.weight(.semibold))
            
            Spacer()
            
            if let accessoryIndicatorIcon {
                Icon(name: accessoryIndicatorIcon, color: Color(.systemGray2))
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
