import SwiftUI
import SwiftData

extension EnvironmentValues {
    @Entry var dismissSheet: @Sendable () -> Void = {}
}

enum HomePage: Hashable {
    case main, heartRateChart, stepsChart

    var title: LocalizedStringKey {
        switch self {
        case .main: "MindfulPacer"
        case .heartRateChart: "Heart Rate"
        case .stepsChart: "Steps"
        }
    }
}

struct HomeView: View {
    @Bindable var viewModel: HomeViewModel
    @EnvironmentObject private var navigationManager: NavigationManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var showsControls = false

    var body: some View {
        ZStack {
            NavigationStack {
                TabView(selection: $viewModel.selectedTab) {
                    overview.tag(HomePage.main)
                    HeartRateChartView(viewModel: viewModel).tag(HomePage.heartRateChart)
                    StepsChartView(viewModel: viewModel).tag(HomePage.stepsChart)
                }
                .tabViewStyle(.verticalPage)
                .navigationTitle(viewModel.selectedTab.title)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Controls", systemImage: "slider.horizontal.3") {
                            showsControls = true
                        }
                        .accessibilityIdentifier("watch.controls")
                    }
                }
            }
            .allowsHitTesting(viewModel.alertState == .none)
            .accessibilityHidden(viewModel.alertState != .none)

            if case .showing(let rule, let alertID) = viewModel.alertState {
                notificationOverlay(for: rule, with: alertID)
            }
        }
        .sheet(isPresented: $showsControls) {
            WatchControlsView(viewModel: viewModel)
        }
        .sheet(item: $navigationManager.pendingActivitySelection) { selection in
            SelectActivityView(reminderID: selection.reminderID, alertID: selection.id)
                .environment(\.dismissSheet) {
                    Task { @MainActor in navigationManager.pendingActivitySelection = nil }
                }
        }
        .onChange(of: viewModel.alertState) { _, state in
            if state != .none { showsControls = false }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { viewModel.refreshHighlights() }
        }
        .onAppear { viewModel.onAppear() }
        .onChange(of: viewModel.selectedTab) { _, page in viewModel.didSelectTab(page) }
        .alert("Activities Unavailable", isPresented: $viewModel.showActivitiesUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Open MindfulPacer on your iPhone to sync your activities, then try again.")
        }
    }

    private var overview: some View {
        ScrollView {
            VStack(spacing: 8) {
                Button { viewModel.selectedTab = .heartRateChart } label: {
                    WatchMetricLabel(title: "Heart Rate", symbol: "heart.fill",
                                     value: viewModel.isMonitoring && viewModel.heartRate > 0
                                        ? Int(viewModel.heartRate).formatted() : "–",
                                     unit: "BPM", color: .pink, highlight: viewModel.heartRateHighlight)
                }
                .tint(viewModel.heartRateHighlight?.color ?? Color.gray)
                .accessibilityIdentifier("watch.heartRate")

                Button { viewModel.selectedTab = .stepsChart } label: {
                    WatchMetricLabel(title: "Steps", symbol: "figure.walk",
                                     value: viewModel.todaysSteps.formatted(), unit: "steps",
                                     color: .cyan, highlight: viewModel.stepsHighlight)
                }
                .tint(viewModel.stepsHighlight?.color ?? Color.gray)
                .accessibilityIdentifier("watch.steps")

                Label(viewModel.statusMessage.localized, systemImage: viewModel.statusMessage.symbolName)
                    .font(.caption2)
                    .foregroundStyle(viewModel.statusMessage.color)
                    .multilineTextAlignment(.center)
                    .padding(.top, 2)
                    .accessibilityIdentifier("watch.status")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .buttonBorderShape(.roundedRectangle(radius: 20))
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
        }
    }

    private func notificationOverlay(for rule: AlertRule, with alertID: UUID) -> some View {
        ZStack {
            Rectangle().foregroundStyle(.ultraThickMaterial).ignoresSafeArea()
            rule.reminderType.color.opacity(0.7).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("Reminder to Reflect")
                            .font(.body.weight(.bold))
                            .layoutPriority(1)

                        if #available(watchOS 26.0, *) {
                            Label {
                                Text(rule.measurementType.localized + " " + rule.alertMessage.lowercased())
                                    .multilineTextAlignment(.center)
                                    .font(.footnote)
                            } icon: {
                                Image(systemName: rule.measurementType.icon)
                                    .foregroundStyle(rule.measurementType.color)
                            }
                            .labelIconToTitleSpacing(0)
                            .foregroundStyle(.white)
                        } else {
                            Label {
                                Text(rule.measurementType.localized + " " + rule.alertMessage.lowercased())
                                    .multilineTextAlignment(.center)
                                    .font(.footnote)
                            } icon: {
                                Image(systemName: rule.measurementType.icon)
                                    .foregroundStyle(rule.measurementType.color)
                            }
                            .foregroundStyle(.white)
                        }
                    }

                    VStack {
                        Button {
                            viewModel.handleAlertAction(shouldAddDetails: true, alertID: alertID)
                        } label: {
                            Text("Accept & Add Details")
                                .fontWeight(.semibold)
                        }
                        .accessibilityIdentifier("watch.alert.details")

                        Button {
                            viewModel.handleAlertAction(shouldAddDetails: false, alertID: alertID)
                        } label: {
                            Text("Accept & Add Details Later")
                        }
                        .accessibilityIdentifier("watch.alert.later")

                        Button {
                            viewModel.dismissAlertOverlay()
                        } label: {
                            Text("Delete")
                        }
                        .accessibilityIdentifier("watch.alert.dismiss")
                    }
                    .buttonStyle(.bordered)
                    .tint(rule.reminderType.color)
                    .foregroundStyle(.white)

                    Spacer()
                }
                .padding()
            }
        }
        .transition(.opacity.animation(.easeInOut))
    }
}

private struct WatchMetricLabel: View {
    let title: LocalizedStringKey
    let symbol: String
    let value: String
    let unit: LocalizedStringKey
    let color: Color
    let highlight: Reminder.ReminderType?

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.body)
                .foregroundStyle(highlight?.color ?? color)
                .frame(width: 20)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(title).font(.caption2).foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(unit).font(.caption2).foregroundStyle(.secondary).lineLimit(1).fixedSize()
                }
            }
            Spacer(minLength: 0)
            if let highlight {
                Image(systemName: highlight.icon)
                    .foregroundStyle(highlight.color)
                    .font(.caption2)
                    .accessibilityLabel(highlight.localized)
            }
        }
        .foregroundStyle(Color.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct WatchControlsView: View {
    @Bindable var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label(viewModel.statusMessage.localized, systemImage: viewModel.statusMessage.symbolName)
                        .foregroundStyle(viewModel.statusMessage.color)
                    Button {
                        viewModel.togglePauseResume()
                    } label: {
                        Label(LocalizedStringKey(viewModel.isManuallyPaused ? "Resume Monitoring" : "Pause Monitoring"),
                              systemImage: viewModel.isManuallyPaused ? "play.fill" : "pause.fill")
                    }
                    .tint(viewModel.isManuallyPaused ? .green : .yellow)
                    .disabled(!viewModel.isMonitoring && !viewModel.isManuallyPaused)
                    .accessibilityIdentifier("watch.pauseResume")
                } footer: {
                    Text(viewModel.statusMessage.description)
                }
                Section {
                    NavigationLink {
                        WatchRemindersView(rules: viewModel.activeRules)
                    } label: {
                        Label("Reminders", systemImage: "bell.badge")
                    }
                    .accessibilityIdentifier("watch.reminders")
                    NavigationLink {
                        List {
                            WatchEmptyState(title: "Continue on iPhone", symbol: "iphone",
                                            message: "Open MindfulPacer on your iPhone to review your missed reflections.")
                            LabeledContent("Missed Reflections", value: viewModel.missedReflectionsCount.formatted())
                        }
                        .navigationTitle("Reflections")
                    } label: {
                        LabeledContent {
                            Text(viewModel.missedReflectionsCount, format: .number)
                                .foregroundStyle(viewModel.missedReflectionsCount > 0 ? Color.orange : .secondary)
                        } label: {
                            Label("Missed", systemImage: "book.closed")
                        }
                    }
                    .accessibilityIdentifier("watch.missed")
                }
                Section {
                    NavigationLink {
                        List {
                            LabeledContent("Battery", value: viewModel.batteryLevel >= 0
                                           ? "\(Int(viewModel.batteryLevel * 100))%" : "–")
                            Text("Keeping the app in the foreground uses more battery. Monitoring can continue when you lower your wrist.")
                                .font(.footnote).foregroundStyle(.secondary)
                            LabeledContent("Version", value: AppInfoService.appVersion)
                            LabeledContent("Build", value: AppInfoService.buildNumber)
                        }
                        .navigationTitle("About")
                    } label: {
                        Label("About", systemImage: "info.circle")
                    }
                    .accessibilityIdentifier("watch.about")
                }
            }
            .navigationTitle("Controls")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", systemImage: "xmark") { dismiss() }
                }
            }
        }
    }
}

struct WatchRemindersView: View {
    let rules: [AlertRule]

    var body: some View {
        List {
            if rules.isEmpty {
                WatchEmptyState(title: "No Reminders", symbol: "bell.badge",
                                message: "Create a reminder in MindfulPacer on your iPhone. It will appear here after syncing.")
            } else {
                Section {
                    ForEach(rules) { rule in ReminderCell(rule: rule) }
                } footer: {
                    Text("Manage your reminders on iPhone.")
                }
            }
        }
        .navigationTitle("Reminders")
    }
}

struct WatchEmptyState: View {
    let title: LocalizedStringResource
    let symbol: String
    let message: LocalizedStringResource

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            Text(title).font(.headline)
            Text(message).font(.footnote).foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

#Preview {
    HomeView(viewModel: .mock)
        .environmentObject(NavigationManager())
}
