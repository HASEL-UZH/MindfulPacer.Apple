import SwiftUI
import SwiftData

extension EnvironmentValues {
    @Entry var dismissSheet: @Sendable () -> Void = {}
    /// True on a page that has to scroll because its content cannot fit, for example with large text.
    @Entry var watchPageScrolls: Bool = false
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
                .navigationTitle {
                    if viewModel.selectedTab == .main {
                        batteryWidget
                    } else {
                        Text(viewModel.selectedTab.title)
                    }
                }
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
            if phase == .active {
                viewModel.refreshHighlights()
                viewModel.refreshMonitoringState()
            }
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
        WatchPage(bottomReach: 1) {
            VStack(spacing: 6) {
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
                                     value: viewModel.todaysSteps.formatted(), unit: "today",
                                     color: .cyan, highlight: viewModel.stepsHighlight,
                                     hidesUnitWhenHighlighted: true)
                }
                .tint(viewModel.stepsHighlight?.color ?? Color.gray)
                .accessibilityIdentifier("watch.steps")

                // The status is the way into Controls, where monitoring is paused and resumed.
                Button { showsControls = true } label: {
                    Label(viewModel.statusMessage.localized, systemImage: viewModel.statusMessage.symbolName)
                        .font(.caption2)
                        .foregroundStyle(viewModel.statusMessage.color)
                        // One line, so a longer status cannot make the page taller than the screen.
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens Controls")
                .accessibilityIdentifier("watch.status")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .buttonBorderShape(.roundedRectangle(radius: 20))
            .padding(.horizontal, 8)
        }
    }

    private var batteryWidget: some View {
        Label {
            Text(viewModel.batteryLevel >= 0 ? "\(Int(viewModel.batteryLevel * 100))%" : "–")
                .monospacedDigit()
                .foregroundStyle(Color.secondary)
        } icon: {
            Image(systemName: batterySymbol)
                .foregroundStyle(batteryColor)
        }
        .font(.caption2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Battery")
        .accessibilityValue(viewModel.batteryLevel >= 0
                            ? "\(Int(viewModel.batteryLevel * 100))%" : String(localized: "Unavailable"))
        .accessibilityIdentifier("watch.battery")
    }

    private var batterySymbol: String {
        switch viewModel.batteryLevel {
        case ..<0.1: "battery.0percent"
        case ..<0.35: "battery.25percent"
        case ..<0.6: "battery.50percent"
        case ..<0.85: "battery.75percent"
        default: "battery.100percent"
        }
    }

    private var batteryColor: Color {
        switch viewModel.batteryLevel {
        case ..<0: .secondary
        case ..<0.2: .red
        case ..<0.5: .yellow
        default: .green
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

/// One page of the vertical pager. The content is laid out without a scroll view whenever it fits, so the
/// Digital Crown and a swipe always turn the page. A page that scrolls has to reach its end before the
/// pager moves, which made paging unreliable when the content was only slightly too tall.
/// A scroll view is still used when the content cannot fit, for example with large text.
struct WatchPage<Content: View>: View {
    /// The share of the bottom safe area that a page without a scroll view may use. That area is on
    /// screen, but the rounded corners narrow it, so only centered content should reach all the way down.
    private let bottomReach: CGFloat
    private let content: Content
    @State private var bottomInset: CGFloat = 0

    init(bottomReach: CGFloat = 0.6, @ViewBuilder content: () -> Content) {
        self.bottomReach = bottomReach
        self.content = content()
    }

    var body: some View {
        ViewThatFits(in: .vertical) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                // A scroll view shows its content down to the edge of the screen. Without one, the page
                // ends at the safe area, which is shorter than the pages on every Watch size.
                .padding(.bottom, -bottomInset * bottomReach)
            ScrollView {
                content.environment(\.watchPageScrolls, true)
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.bottom } action: { bottomInset = $0 }
    }
}

private struct WatchMetricLabel: View {
    let title: LocalizedStringKey
    let symbol: String
    let value: String
    let unit: LocalizedStringKey
    let color: Color
    let highlight: Reminder.ReminderType?
    /// A long value needs the unit's space once the highlight dot is shown.
    var hidesUnitWhenHighlighted = false

    private var showsUnit: Bool { !(hidesUnitWhenHighlighted && highlight != nil) }

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.body)
                .foregroundStyle(highlight?.color ?? color)
                .frame(width: 20)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                // One line, so the row keeps its height and the page keeps fitting the screen.
                Text(title).font(.caption2).foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if showsUnit {
                    // The value is never cut off: when it does not fit next to the unit it first gets
                    // smaller, and then the unit is dropped.
                    ViewThatFits(in: .horizontal) {
                        valueRow(.title3, showsUnit: true).fixedSize()
                        valueRow(.body, showsUnit: true).fixedSize()
                        valueRow(.footnote, showsUnit: true).fixedSize()
                        valueRow(.title3, showsUnit: false)
                    }
                } else {
                    valueRow(.title3, showsUnit: false)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let highlight {
                Image(systemName: highlight.icon)
                    .foregroundStyle(highlight.color)
                    .font(.caption2)
                    .accessibilityLabel(highlight.localized)
            }
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.secondary)
                .accessibilityHidden(true)
        }
        .foregroundStyle(Color.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func valueRow(_ style: Font.TextStyle, showsUnit: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(value)
                .font(.system(style, design: .rounded, weight: .semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if showsUnit {
                Text(unit).font(.caption2).foregroundStyle(.secondary).lineLimit(1).fixedSize()
            }
        }
    }
}

struct WatchControlsView: View {
    @Bindable var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss

    /// The button always offers an action: it resumes whenever monitoring is not running.
    private var startsMonitoring: Bool { viewModel.monitoringControlAction.startsMonitoring }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label(viewModel.statusMessage.localized, systemImage: viewModel.statusMessage.symbolName)
                        .foregroundStyle(viewModel.statusMessage.color)
                    Button {
                        viewModel.togglePauseResume()
                    } label: {
                        Label(LocalizedStringKey(startsMonitoring ? "Resume Monitoring" : "Pause Monitoring"),
                              systemImage: startsMonitoring ? "play.fill" : "pause.fill")
                    }
                    .tint(startsMonitoring ? .green : .yellow)
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
