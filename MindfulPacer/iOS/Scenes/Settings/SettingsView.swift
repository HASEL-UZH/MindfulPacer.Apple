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
    case mailView(recipient: String, subject: String, body: String?)
    case roadmap
    case systemReportView

    var id: Int {
        switch self {
        case .onboardingView: 0
        case .mailView: 1
        case .roadmap: 2
        case .systemReportView: 3
        }
    }
}

enum SettingsNavigationDestination: Hashable {
    case theme
}

// MARK: - SettingsView

struct SettingsView: View {
    
    // MARK: Properties
    
    @Environment(\.openURL) private var openURL
    @AppStorage(ModeOfUse.appStorageKey) var modeOfUse: ModeOfUse = .essentials
    @AppStorage(Theme.appStorageKey) private var theme: Theme = .system
    @State private var viewModel: SettingsViewModel = ScenesContainer.shared.settingsViewModel()
    
    // MARK: Body
    
    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            RoundedList {
                Section {
                    mindfulPacerExpanded
                    viewOnboarding
                } header: {
                    sectionHeader(title: "General")
                }
                
                Section {
                    themeSettings
                } header: {
                    sectionHeader(title: "Appearance")
                }
                
                Section {
                    contactUs
                    roadmap
                    moreInfo
                    privacyPolicy
                    disclaimer
                } header: {
                    sectionHeader(title: "About")
                } footer: {
                    logos
                }
             
                appVersion
                    .padding(.bottom)
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
                viewModel.setModeOfUse(modeOfUse)
            }
            .onChange(of: viewModel.isExpandedModeOfUseOn) { _, newValue in
                modeOfUse = (newValue == true ? .expanded : .essentials)
            }
        }
    }
    
    // MARK: Navigation Destination

    @ViewBuilder
    private func navigationDestination(for destination: SettingsNavigationDestination) -> some View {
        switch destination {
        case .theme:
            ThemeSettingsView()
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
        case .mailView(let recipient, let subject, let body):
            MailView(
                result: $viewModel.mailResult,
                recipient: recipient,
                subject: subject,
                body: body
            )
            .presentationCornerRadius(16)
        case .roadmap:
            RoadmapView()
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
    
    private var themeSettings: some View {
        NavigationLink(value: SettingsNavigationDestination.theme) {
            RoundedListCell(
                icon: "circle.lefthalf.striped.horizontal.inverse",
                title: "Theme",
                description: "Change the app theme",
                accessoryIndicatorText: theme.rawValue,
                accessoryIndicatorIcon: "chevron.right"
            )
        }
    }
    
    // MARK: MindulPacer Expanded
    
    private var mindfulPacerExpanded: some View {
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
    
    // MARK: Contact Us
    
    private var contactUs: some View {
        Button {
            viewModel.presentSheet(
                .mailView(
                    recipient: viewModel.contactSupportRecipient,
                    subject: viewModel.contactSupportSubject,
                    body: nil
                )
            )
        } label: {
            RoundedListCell(
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
            RoundedListCell(
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
            RoundedListCell(
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
            RoundedListCell(
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
            RoundedListCell(
                icon: "map",
                title: "Roadmap",
                description: "View upcoming features",
                accessoryIndicatorIcon: "arrow.up.forward.square"
            )
        }
    }
    
    // MARK: Disclaimer
    
    private var disclaimer: some View {
        RoundedListCell(
            icon: "exclamationmark.triangle",
            title: "Disclaimer",
            description:
                """
                MindfulPacer is a spin-off project from the University of Zurich, developed in collaboration between the Human Aspects of Software Engineering Lab and the Clinic for Immunology.
                
                MindfulPacer is not a medical product and does not offer medical services such as diagnosis, cure, relief, prevention, or treatment of any disease or medical condition. MindfulPacer is not a substitute for treatment by medical professionals. You should always consult a doctor before making medical decisions.
                """
        )
    }
    
    // MARK: Logos
    
    private var logos: some View {
        HStack(spacing: 16) {
            Group {
                Image(.dizhLogo)
                    .resizable()
                Image(.uzhLogo)
                    .resizable()
                Image(.longCovidLogo)
                    .resizable()
                Image(.uszLogo)
                    .resizable()
            }
            .scaledToFit()
            .frame(width: 64, height: 64)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    // MARK: App Version
    
    private var appVersion: some View {
        Button {
            viewModel.presentSheet(.systemReportView)
        } label: {
            Label("MindfulPacer Version \(viewModel.appVersion)", systemImage: "iphone.gen3")
                .font(.footnote)
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
