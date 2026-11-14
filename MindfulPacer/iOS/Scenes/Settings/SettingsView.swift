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
    case releaseNotes

    var id: Int {
        switch self {
        case .onboardingView: 0
        case .mailView: 1
        case .roadmap: 2
        case .systemReportView: 3
        case .releaseNotes: 4
        }
    }
}

enum SettingsNavigationDestination: Hashable {
    case algorithms
    case theme
    case dataManagement
    case appleWatch
    case deviceMode
    case backgroundDiagnostics
}

enum SettingsAlert: Identifiable {
    case resetDatabaseConfirmation
    case restartApp

    var id: Int { hashValue }
}

// MARK: - SettingsView

struct SettingsView: View {

    @Environment(\.openURL) private var openURL

    @AppStorage(ModeOfUse.appStorageKey, store: DefaultsStore.shared)
    private var modeOfUseRaw: String = ModeOfUse.essentials.rawValue

    private var modeOfUseBinding: Binding<ModeOfUse> {
        Binding(
            get: { ModeOfUse(rawValue: modeOfUseRaw) ?? .essentials },
            set: { modeOfUseRaw = $0.rawValue }
        )
    }

    @AppStorage(Theme.appStorageKey) private var theme: Theme = .system
    @State private var viewModel: SettingsViewModel = ScenesContainer.shared.settingsViewModel()

    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            List {

                Section {
                    mindfulPacerExpanded
                    deviceModeSetting
//                    appleWatch
                    viewOnboarding
                } header: {
                    Text("General")
                } footer: {
                    Text("Expanded mode unlocks fine-grained self-reports for fatigue, shortness of breath, pains, and other factors.")
                }

                Section {
                    themeSettings
                } header: {
                    Text("Appearance")
                }

                Section {
                    dataManagement
                    if modeOfUseBinding.wrappedValue == .expanded {
                        algorithms
                    }
                } header: {
                    Text("Data")
                }

                Section {
                    releaseNotes
                    contactUs
                    roadmap
                    joinTestFlight
                    moreInfo
                    privacyPolicy
                } header: {
                    Text("About")
                }

                Section {
                    disclaimer
                } footer: {
                    Text(disclaimerDescription)
                }

                Section {
                    logos
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
            .alert(item: $viewModel.activeAlert) { alert in
                alertContent(for: alert)
            }
            .onAppear {
                viewModel.onViewAppear()
                viewModel.configure(modeOfUseBinding.wrappedValue, DeviceMode.current(from: DefaultsStore.shared))
                viewModel.isExpandedModeOfUseOn = (modeOfUseBinding.wrappedValue == .expanded)
            }
            .onChange(of: viewModel.isExpandedModeOfUseOn) { _, newValue in
                modeOfUseBinding.wrappedValue = (newValue ? .expanded : .essentials)
            }
            .onChange(of: modeOfUseRaw) { _, _ in
                viewModel.isExpandedModeOfUseOn = (modeOfUseBinding.wrappedValue == .expanded)
            }
        }
    }

    // MARK: Navigation Destination

    @ViewBuilder
    private func navigationDestination(for destination: SettingsNavigationDestination) -> some View {
        switch destination {
        case .algorithms:
            AlgorithmsView(viewModel: viewModel)
        case .theme:
            ThemeSettingsView()
        case .dataManagement:
            DataManagementView(viewModel: viewModel)
        case .appleWatch:
            AppleWatchView(viewModel: viewModel)
        case .deviceMode:
            DeviceModeSettingsView(viewModel: viewModel)
        case .backgroundDiagnostics:
            BackgroundDiagnosticsView()
        }
    }

    // MARK: Sheets

    @ViewBuilder
    private func sheetContent(for sheet: SettingsSheet) -> some View {
        switch sheet {
        case .onboardingView:
            OnboardingView()
                .presentationDragIndicator(.visible)
        case .mailView(let recipient, let subject, let body):
            MailView(
                result: $viewModel.mailResult,
                recipient: recipient,
                subject: subject,
                body: body
            )
        case .roadmap:
            RoadmapView()
                .presentationDragIndicator(.visible)
        case .systemReportView:
            SystemReportView(viewModel: viewModel)
                .presentationDragIndicator(.visible)
        case .releaseNotes:
            ReleaseNotesView()
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: Alert Content

    private func alertContent(for alert: SettingsAlert) -> Alert {
        switch alert {
        case .resetDatabaseConfirmation:
            return resetDatabaseConfirmationAlert
        case .restartApp:
            return restartAppAlert
        }
    }

    // MARK: Theme

    private var themeSettings: some View {
        NavigationLink(value: SettingsNavigationDestination.theme) {
            LabeledContent {
                Text(theme.localized)
                    .foregroundStyle(Color.secondary)
            } label: {
                SettingsRowLabel(
                    title: String(localized: "Theme"),
                    subtitle: String(localized: "Change the app theme"),
                    systemImage: "circle.lefthalf.filled.righthalf.striped.horizontal.inverse"
                )
            }
        }
        .accessibilityIdentifier("settings.theme")
    }

    // MARK: MindulPacer Expanded

    private var mindfulPacerExpanded: some View {
        Toggle(isOn: $viewModel.isExpandedModeOfUseOn) {
            SettingsRowLabel(
                title: String(localized: "MindfulPacer Expanded"),
                subtitle: String(localized: "Access all app features, including fine-grained self-reports for fatigue, shortness of breath, pains, and other factors."),
                assetImage: "MindfulPacer Expanded Icon"
            )
        }
    }

    // MARK: Device Mode

    private var deviceModeSetting: some View {
        NavigationLink(value: SettingsNavigationDestination.deviceMode) {
            SettingsRowLabel(
                title: String(localized: "Device Mode"),
                systemImage: "iphone.gen3"
            )
        }
        .accessibilityIdentifier("settings.deviceMode")
    }

    // MARK: Algorithms

    private var algorithms: some View {
        NavigationLink(value: SettingsNavigationDestination.algorithms) {
            SettingsRowLabel(
                title: String(localized: "Algorithms"),
                systemImage: "slider.horizontal.below.square.filled.and.square"
            )
        }
    }

    // MARK: Release Notes

    private var releaseNotes: some View {
        Button {
            viewModel.presentSheet(.releaseNotes)
        } label: {
            SettingsRowLabel(
                title: String(localized: "Release Notes"),
                subtitle: String(localized: "See what changed in each version"),
                systemImage: "doc.text.fill",
                isAction: true
            )
        }
    }

    // MARK: Data Management

    private var dataManagement: some View {
        NavigationLink(value: SettingsNavigationDestination.dataManagement) {
            SettingsRowLabel(
                title: String(localized: "Manage Data"),
                subtitle: String(localized: "Export or delete your data"),
                systemImage: "externaldrive.fill"
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
            SettingsRowLabel(
                title: String(localized: "Contact Us"),
                systemImage: "envelope.fill",
                isAction: true
            )
        }
    }

    // MARK: - More Info

    private var moreInfo: some View {
        Button {
            openURL(viewModel.landingPageURL)
        } label: {
            SettingsRowLabel(
                title: String(localized: "More Info"),
                systemImage: "info.circle.fill",
                isAction: true
            )
        }
    }

    // MARK: - Privacy Policy

    private var privacyPolicy: some View {
        Button {
            openURL(viewModel.privacyPolicyURL)
        } label: {
            SettingsRowLabel(
                title: String(localized: "Privacy Policy"),
                systemImage: "hand.raised.fill",
                isAction: true
            )
        }
    }

    // MARK: View Onboarding

    private var viewOnboarding: some View {
        Button {
            viewModel.presentSheet(.onboardingView)
        } label: {
            SettingsRowLabel(
                title: String(localized: "Onboarding"),
                subtitle: String(localized: "View the onboarding again"),
                systemImage: "square.stack.3d.up.fill",
                isAction: true
            )
        }
    }

    // MARK: Roadmap

    private var roadmap: some View {
        Button {
            viewModel.presentSheet(.roadmap)
        } label: {
            SettingsRowLabel(
                title: String(localized: "Roadmap"),
                subtitle: String(localized: "View upcoming features"),
                systemImage: "map.fill",
                isAction: true
            )
        }
    }

    // MARK: Join TestFlight

    private var joinTestFlight: some View {
        Button {
            openURL(URL(string: "https://mindfulpacer.ch/apple-testflight")!)
        } label: {
            SettingsRowLabel(
                title: String(localized: "Join TestFlight"),
                subtitle: String(localized: "Help us test new features before release"),
                systemImage: "airplane.circle.fill",
                isAction: true
            )
        }
    }

    // MARK: Disclaimer

    private var disclaimer: some View {
        SettingsRowLabel(
            title: String(localized: "Disclaimer"),
            systemImage: "exclamationmark.triangle.fill",
            tint: .yellow
        )
    }

    private var disclaimerDescription: String {
        String(localized: """
            MindfulPacer is a spin-off project from the University of Zurich, developed by the Human Aspects of Software Engineering Lab.

            MindfulPacer is not a medical product and does not offer medical services such as diagnosis, cure, relief, prevention, or treatment of any disease or medical condition. MindfulPacer is not a substitute for treatment by medical professionals. You should always consult a doctor before making medical decisions.
            """)
    }

    // MARK: Logos

    private var logos: some View {
        VStack(spacing: 16) {
            HStack {
                Label(
                    String(localized: "Supported By"),
                    systemImage: "building.columns"
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
                                institute.logo
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200, height: 80)
                            }
                            .accessibilityLabel(institute.name)
                        }
                    }
                    .frame(maxWidth: 256)
                }
                .scrollTargetLayout()
                .frame(maxHeight: 128)
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }

    // MARK: Apple Watch

    private var appleWatch: some View {
        NavigationLink(value: SettingsNavigationDestination.appleWatch) {
            SettingsRowLabel(
                title: String(localized: "Apple Watch"),
                systemImage: "applewatch"
            )
        }
    }

    // MARK: App Version

    private var appVersion: some View {
        Button {
            viewModel.presentSheet(.systemReportView)
        } label: {
            Label("MindfulPacer Version \(viewModel.appVersion)", systemImage: "iphone.gen3")
                .font(.footnote)
                .foregroundStyle(Color.accentColor)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal)
    }

    // MARK: Reset Database Confirmation Alert

    private var resetDatabaseConfirmationAlert: Alert {
        Alert(
            title: Text("Reset Data"),
            message: Text("All data stored on your device and in iCloud will be deleted, including Reflections and Reminders. This action cannot be reversed. Are you sure you want to proceed?"),
            primaryButton: .destructive(Text("Delete")) {
                viewModel.resetDatabase()
            },
            secondaryButton: .cancel()
        )
    }

    // MARK: Restart App Alert

    private var restartAppAlert: Alert {
        Alert(
            title: Text("Restart Required"),
            message: Text("Please restart the app to see the changes take effect."),
            dismissButton: .default(Text("OK"))
        )
    }
}

// MARK: - Settings Row Label

struct SettingsRowLabel: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let title: String
    var subtitle: String?
    var systemImage: String?
    var assetImage: String?
    var tint: Color = .brandPrimary
    var isAction: Bool = false

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    icon
                    text
                }
            } else {
                Label { text } icon: { icon }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var text: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .foregroundStyle(isAction ? Color.accentColor : Color.primary)

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var icon: some View {
        if let assetImage {
            Image(assetImage)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
        } else if let systemImage {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .tint(.brandPrimary)
}
