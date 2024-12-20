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
    case roadmap
    case systemReportView

    var id: Int {
        hashValue
    }
}

enum SettingsNavigationDestination: Hashable {
    case theme
}

// MARK: - SettingsView

struct SettingsView: View {
    
    // MARK: Properties
    
    @Environment(\.openURL) private var openURL
    @State private var viewModel: SettingsViewModel = ScenesContainer.shared.settingsViewModel()
    
    // MARK: Body
    
    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            RoundedList {
                Section {
                    modeOfUse
                    viewOnboarding
                } header: {
                    sectionHeader(title: "General")
                }
                
                Section {
                    theme
                } header: {
                    sectionHeader(title: "Appearance")
                }
                
                Section {
                    support
                    roadmap
                    moreInfo
                    privacyPolicy
                } header: {
                    sectionHeader(title: "About")
                }
                
                appVersion
            }
            .navigationTitle("Settings")
            .navigationDestination(for: SettingsNavigationDestination.self) { destination in
                navigationDestination(for: destination)
            }
            .sheet(item: $viewModel.activeSheet) { sheet in
                sheetContent(for: sheet)
            }
            .onAppear {
                viewModel.onViewAppear()
            }
        }
    }
    
    // MARK: Navigation Destination

    @ViewBuilder
    private func navigationDestination(for destination: SettingsNavigationDestination) -> some View {
        switch destination {
        case .theme:
            ThemeSettingsView(viewModel: viewModel)
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
                .presentationCornerRadius(16)
        case .roadmap:
            RoadmapView(viewModel: viewModel)
                .presentationCornerRadius(16)
                .presentationDragIndicator(.visible)
        case .systemReportView:
            SystemReportView(viewModel: viewModel)
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(16)
        }
    }
    
    // MARK: Section Header
    
    @ViewBuilder
    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }
    
    // MARK: Theme
    
    private var theme: some View {
        NavigationLink(value: SettingsNavigationDestination.theme) {
            settingsCell(
                icon: "circle.lefthalf.striped.horizontal.inverse",
                title: "Theme",
                description: "Change the app theme",
                accessoryIndicatorText: viewModel.selectedTheme.rawValue,
                accessoryIndicatorIcon: "chevron.right"
            )
        }
    }
    
    // MARK: Mode of Use
    
    private var modeOfUse: some View {
        Toggle(isOn: $viewModel.isExpandedModeOfUseOn) {
            IconLabel(
                image: "MindfulPacer Expanded Icon",
                title: "MindfulPacer Expanded",
                description: "Access all app features, ability to provide fine-grained self-reports on Fatigue, Shortness of Breath, Pains, and other factors",
                labelColor: Color("BrandPrimary"),
                background: true
            )
            .font(.subheadline.weight(.semibold))
        }
        .tint(.brandPrimary)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
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
    
    // MARK: Roadmap
    
    private var roadmap: some View {
        Button {
            viewModel.presentSheet(.roadmap)
        } label: {
            settingsCell(
                icon: "map",
                title: "Roadmap",
                description: "View upcoming features",
                accessoryIndicatorIcon: "arrow.up.forward.square"
            )
        }
    }

    // MARK: App Version
    
    private var appVersion: some View {
        Button {
            viewModel.presentSheet(.systemReportView)
        } label: {
            Label("MindfulPacer Version \(viewModel.appVersion)", systemImage: "info.circle")
                .font(.footnote)
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
    
    // MARK: Settings Cell
    
    @ViewBuilder
    func settingsCell(
        icon: String,
        title: String,
        description: String? = nil,
        accessoryIndicatorText: String? = nil,
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
            
            HStack(spacing: 4) {
                if let accessoryIndicatorText {
                    Text(accessoryIndicatorText)
                        .foregroundStyle(Color(.systemGray2))
                        .fixedSize(horizontal: true, vertical: false)
                }
                
                if let accessoryIndicatorIcon {
                    Icon(name: accessoryIndicatorIcon, color: Color(.systemGray2))
                        .font(.subheadline.weight(.semibold))
                }
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
