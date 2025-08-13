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
    case missedReflectionsListView

    var id: Int {
        switch self {
        case .onboardingView: 0
        case .mailView: 1
        case .roadmap: 2
        case .systemReportView: 3
        case .missedReflectionsListView: 4
        }
    }
}

enum SettingsNavigationDestination: Hashable {
    case algorithms
    case theme
    case export
    case appleWatch
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
                    appleWatch
                } header: {
                    sectionHeader(title: String(localized: "General"))
                }
                
                Section {
                    themeSettings
                } header: {
                    sectionHeader(title: String(localized: "Appearance"))
                }
                
                Section {
                    exportData
                    if modeOfUse == .expanded {
                        algorithms
                    }
                } header: {
                    sectionHeader(title: String(localized: "Data"))
                }
                
                Section {
                    contactUs
                    roadmap
                    moreInfo
                    privacyPolicy
                    disclaimer
                } header: {
                    sectionHeader(title: String(localized: "About"))
                }
                
                Section {
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
        case .algorithms:
            AlgorithmsView()
        case .theme:
            ThemeSettingsView()
        case .export:
            ExportView(viewModel: viewModel)
        case .appleWatch:
            AppleWatchView(viewModel: viewModel)
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
        case .missedReflectionsListView:
            MissedReflectionsListView(viewModel: viewModel)
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
                label: IconLabel(
                    icon: "circle.lefthalf.striped.horizontal.inverse",
                    title: String(localized: "Theme"),
                    description: String(localized: "Change the app theme"),
                    labelColor: Color("BrandPrimary"),
                    background: true
                ),
                accessoryIndicatorText: theme.rawValue,
                accessoryIndicatorIcon: "chevron.right"
            )
        }
    }
    
    // MARK: MindulPacer Expanded
    
    private var mindfulPacerExpanded: some View {
        DisclosureGroup {
            Text(String(localized: "Access all app features, ability to provide fine-grained self-reports on Fatigue, Shortness of Breath, Pains, and other factors"))
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top)
        } label: {
            Toggle(isOn: $viewModel.isExpandedModeOfUseOn) {
                IconLabel(
                    image: "MindfulPacer Expanded Icon",
                    title: String(localized: "MindfulPacer Expanded"),
                    labelColor: Color("BrandPrimary"),
                    background: true
                )
                .font(.subheadline.weight(.semibold))
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .tint(Color.brandPrimary)
    }
    
    // MARK: Algorithms
    
    private var algorithms: some View {
        NavigationLink(value: SettingsNavigationDestination.algorithms) {
            RoundedListCell(
                label: IconLabel(
                    icon: "curlybraces",
                    title: String(localized: "Algorithms"),
                    labelColor: Color("BrandPrimary"),
                    background: true
                ),
                accessoryIndicatorIcon: "chevron.right"
            )
        }
    }
    
    // MARK: Export Data
    
    private var exportData: some View {
        NavigationLink(value: SettingsNavigationDestination.export) {
            RoundedListCell(
                label: IconLabel(
                    icon: "tray.and.arrow.up.fill",
                    title: String(localized: "Export Data"),
                    labelColor: Color("BrandPrimary"),
                    background: true
                ),
                accessoryIndicatorIcon: "chevron.right"
            )
        }
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
                label: IconLabel(
                    icon: "envelope",
                    title: String(localized: "Contact Us"),
                    labelColor: Color("BrandPrimary"),
                    background: true
                ),
                accessoryIndicatorIcon: "arrow.up.forward.square"
            )
        }
    }
    
    // MARK: - More Info
    
    private var moreInfo: some View {
        Button {
            openURL(viewModel.landingPageURL)
        } label: {
            RoundedListCell(
                label: IconLabel(
                    icon: "info",
                    title: String(localized: "More Info"),
                    labelColor: Color("BrandPrimary"),
                    background: true
                ),
                accessoryIndicatorIcon: "link"
            )
        }
    }
    
    // MARK: - Privacy Policy
    
    private var privacyPolicy: some View {
        Button {
            openURL(viewModel.privacyPolicyURL)
        } label: {
            RoundedListCell(
                label: IconLabel(
                    icon: "hand.raised",
                    title: String(localized: "Privacy Policy"),
                    labelColor: Color("BrandPrimary"),
                    background: true
                ),
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
                label: IconLabel(
                    icon: "square.stack",
                    title: String(localized: "Onboarding"),
                    description: String(localized: "View the onboarding again"),
                    labelColor: Color("BrandPrimary"),
                    background: true
                ),
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
                label: IconLabel(
                    icon: "map",
                    title: String(localized: "Roadmap"),
                    description: String(localized: "View upcoming features"),
                    labelColor: Color("BrandPrimary"),
                    background: true
                ),
                accessoryIndicatorIcon: "arrow.up.forward.square"
            )
        }
    }
    
    // MARK: Disclaimer
    
    private var disclaimer: some View {
        RoundedListCell(
            label: IconLabel(
                icon: "exclamationmark.triangle",
                title: String(localized: "Disclaimer"),
                description:  String(localized: """
                    MindfulPacer is a spin-off project from the University of Zurich, developed by the Human Aspects of Software Engineering Lab.
                    
                    MindfulPacer is not a medical product and does not offer medical services such as diagnosis, cure, relief, prevention, or treatment of any disease or medical condition. MindfulPacer is not a substitute for treatment by medical professionals. You should always consult a doctor before making medical decisions.
                    """),
                labelColor: .yellow,
                background: true
            )
        )
    }
    
    // MARK: Logos
    
    private var logos: some View {
        VStack(spacing: 16) {
            HStack {
                IconLabel(
                    icon: "building.columns",
                    title: String(localized: "Supported By"),
                    labelColor: Color("BrandPrimary"),
                    background: true
                )
                .font(.subheadline.weight(.semibold))
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    Group {
                        ForEach(SupportingInstitute.allCases) { institute in
                            Button {
                                openURL(institute.url)
                            } label: {
                                Card(backgroundColor: Color(.tertiarySystemGroupedBackground)) {
                                    institute.logo
                                        .resizable()
                                        .scaledToFill()
                                }
                            }
                        }
                    }
                    .frame(maxWidth: 256)
                }
                .scrollTargetLayout()
                .frame(maxHeight: 128)
            }
            .scrollTargetBehavior(.viewAligned)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
    }
    
    // MARK: Apple Watch
    
    private var appleWatch: some View {
        NavigationLink(value: SettingsNavigationDestination.appleWatch) {
            RoundedListCell(
                label: IconLabel(
                    icon: "applewatch",
                    title: String(localized: "Apple Watch"),
                    labelColor: Color("BrandPrimary"),
                    background: true
                ),
                accessoryIndicatorIcon: "chevron.right"
            )
        }
    }
    
    // MARK: App Version
    
    private var appVersion: some View {
        Label("MindfulPacer Version \(viewModel.appVersion)", systemImage: "iphone.gen3")
            .font(.footnote)
            .foregroundStyle(Color.secondary)
            .onTapGesture(count: 1) {
                viewModel.presentSheet(.systemReportView)
            }
            .onTapGesture(count: 2) {
                viewModel.presentSheet(.missedReflectionsListView)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
