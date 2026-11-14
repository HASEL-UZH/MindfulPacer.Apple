//
//  HomeView.swift
//  iOS
//
//  Created by Grigor Dochev on 26.08.2024.
//

import SwiftUI
import SwiftData

// MARK: - Presentation Enums

enum HomeNavigationDestination: Hashable {
    case reviewsList
    case remindersList
    case analytics
    case missedReflectionsList
}

enum HomeSheet: Identifiable {
    case editReflectionView(Reflection?)
    case createReminderView(Reminder?)
    case reviewsFilterView

    var id: Int {
        switch self {
        case .editReflectionView: 0
        case .createReminderView: 1
        case .reviewsFilterView: 2
        }
    }
}

enum HomeAlert: Identifiable {
    case watchAppNotInstalled
    case watchNotPaired
    
    var id: Int {
        hashValue
    }
}

enum HomeToast: Identifiable {
    case successfullyCreatedReflection
    
    var id: Int {
        hashValue
    }
}

// MARK: - HomeView

struct HomeView: View {
    
    // MARK: Properties

    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage("userHasSeenOnboarding") var userHasSeenOnboarding: Bool = false
    @State private var viewModel: HomeViewModel = ScenesContainer.shared.homeViewModel()
    var onWidgetTap: () -> Void
    @State private var navigationPath: [HomeNavigationDestination] = []
    @State private var selectedContext: HomeContext = .today
    @State private var contextBarHeight: CGFloat = 80
    
    @Query private var allReminders: [Reminder]
    
    private var reminders: [Reminder] {
        let groupedReminders = Dictionary(grouping: allReminders) { $0.measurementType }
        let sortedKeys = groupedReminders.keys.sorted { lhs, rhs in
            if lhs == .heartRate { return true }
            else if rhs == .heartRate { return false }
            else { return lhs.rawValue < rhs.rawValue }
        }
        return sortedKeys.flatMap { key in
            groupedReminders[key]?.sorted(by: { $0.threshold > $1.threshold }) ?? []
        }
    }
    
    @Query(sort: \Activity.name) private var activities: [Activity]
    
    @AppStorage(DeviceMode.appStorageKey, store: DefaultsStore.shared)
    private var deviceModeRaw: String = DeviceMode.iPhoneAndWatch.rawValue
    
    private var deviceMode: DeviceMode {
        DeviceMode(rawValue: deviceModeRaw) ?? .iPhoneAndWatch
    }
    
    // MARK: Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
            homeContent
            .toolbarVisibility(.hidden, for: .navigationBar)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationDestination(for: HomeNavigationDestination.self) { destination in
                navigationDestination(for: destination)
                    .toolbarVisibility(.visible, for: .navigationBar)
            }
            .sheet(item: $viewModel.activeSheet, onDismiss: {
                withAnimation {
                    viewModel.onSheetDismissed()
                }
            }, content: { sheet in
                sheetContent(for: sheet)
            })
            .toast(item: $viewModel.activeToast) { toast in
                toastContent(for: toast)
            }
            .alert(item: $viewModel.activeAlert) { alert in
                alertContent(for: alert)
            }
            .onViewFirstAppear {
                viewModel.configure(deviceMode)
                viewModel.updateActivities(activities)
                viewModel.onViewFirstAppear(reminders: reminders)
            }
            .onAppear {
                viewModel.configure(deviceMode)
                viewModel.onViewAppear()
            }
            .onChange(of: deviceMode) {
                viewModel.configure(deviceMode)
            }
            .onChange(of: reminders) { _, newValue in
                print("DEBUG: Reminders changed, count: \(newValue.count)")
                viewModel.updateReminders(newValue)
            }
            .onChange(of: activities) { _, newValue in
                viewModel.updateActivities(newValue)
            }
        }
        .sensoryFeedback(.selection, trigger: selectedContext)
    }

    // MARK: Home Context

    private enum HomeContext: String, CaseIterable, Identifiable {
        case today, reflections, reminders
        var id: Self { self }
        var title: String {
            switch self {
            case .today: String(localized: "Today")
            case .reflections: String(localized: "Reflections")
            case .reminders: String(localized: "Reminders")
            }
        }
        var icon: String {
            switch self {
            case .today: "sparkles"
            case .reflections: "book.pages.fill"
            case .reminders: "bell.badge.fill"
            }
        }
        var tint: Color {
            switch self {
            case .today: .blue
            case .reflections: .brandPrimary
            case .reminders: .accentColor
            }
        }
    }

    private var selectedPage: Binding<HomeContext?> {
        Binding(get: { selectedContext }, set: { if let context = $0 { selectedContext = context } })
    }

    private var homeContent: some View {
        ScrollViewReader { proxy in
            GeometryReader { geometry in
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        ForEach(HomeContext.allCases) { context in
                            contextPage(context, topInset: contextBarHeight + geometry.safeAreaInsets.top)
                                .containerRelativeFrame(.horizontal)
                                .frame(height: geometry.size.height + geometry.safeAreaInsets.top)
                                .id(context)
                                .accessibilityHidden(context != selectedContext)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: selectedPage)
                .scrollIndicators(.hidden)
                .ignoresSafeArea(.container, edges: .top)
                .accessibilityIdentifier("home.pages")
            }
            .overlay(alignment: .top) {
                contextSwitcher
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contextBarHeight = $0 }
            }
            .onChange(of: selectedContext) {
                withAnimation(.snappy(duration: 0.25)) {
                    proxy.scrollTo("context.\(selectedContext.rawValue)", anchor: .center)
                }
            }
        }
    }

    private func contextPage(_ context: HomeContext, topInset: CGFloat) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                switch context {
                case .today:
                    homeHeadline("How are you feeling?", "Take a moment to reflect on your day.")
                    createReflectionCard
                    healthPermissionsWidget
                    watchConnectionNotice
                    stepsAndHeartRateWidgets
                    ReflectionsWidget(viewModel: viewModel) { navigationPath.append(.reviewsList) }
                    RemindersWidget(viewModel: viewModel) { navigationPath.append(.remindersList) }
                case .reflections:
                    HomeReflectionHistoryView(reflections: viewModel.reflections)
                    homeHeadline("Your days, in perspective.", "Notice how you feel, one reflection at a time.")
                    ReflectionsWidget(viewModel: viewModel) { navigationPath.append(.reviewsList) }
                    missedReflectionsWidget
                case .reminders:
                    HomeReminderOverviewView(reminders: reminders)
                    homeHeadline("A gentle nudge to pause.", "Make space for reflection with reminders that fit your day.")
                    RemindersWidget(viewModel: viewModel) { navigationPath.append(.remindersList) }
                }
            }
            .frame(maxWidth: 640, alignment: .leading)
            .padding([.horizontal, .bottom], 16)
            .padding(.top, 8)
            .frame(maxWidth: .infinity)
        }
        .contentMargins(.top, topInset, for: .scrollContent)
        .scrollIndicators(.hidden)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .accessibilityIdentifier("home.content.\(context.rawValue)")
        .refreshable { viewModel.onRefresh(reminders: reminders) }
    }

    private var createReflectionCard: some View {
        Button {
            viewModel.presentSheet(.editReflectionView(nil))
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Create Reflection")
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                    Text("Activities, mood, and symptoms")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "plus")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(Color.primary)
                    .frame(width: 36, height: 36)
                    .background(Color(.tertiarySystemGroupedBackground), in: .circle)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 22))
            .contentShape(.rect(cornerRadius: 22))
        }
        .accessibilityLabel("Create Reflection")
        .accessibilityHint("Activities, mood, and symptoms")
    }

    private var contextSwitcher: some View {
        ScrollView(.horizontal) {
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(HomeContext.allCases) { context in
                        Button {
                            withAnimation(.snappy(duration: 0.25)) { selectedContext = context }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: context.icon)
                                    .font(.title2.weight(.semibold))
                                    .foregroundStyle(context.tint)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(context.title).foregroundStyle(Color.secondary)
                                    Text(contextValue(context))
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color.primary)
                                        .monospacedDigit()
                                }
                                .font(.subheadline)
                            }
                            .fixedSize()
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.glass(.regular.tint(selectedContext == context ? .white.opacity(0.3) : .clear)))
                        .buttonBorderShape(.roundedRectangle(radius: 20))
                        .controlSize(.regular)
                        .accessibilityAddTraits(selectedContext == context ? [.isSelected] : [])
                        .accessibilityIdentifier("home.context.\(context.rawValue)")
                        .id("context.\(context.rawValue)")
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .scrollIndicators(.hidden)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier("home.contextSwitcher")
    }

    private var weeklyReflectionCount: Int {
        let start = Calendar.current.startOfDay(for: Date.now)
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: start)?.start ?? start
        return viewModel.reflections.filter { $0.date >= weekStart && $0.date <= .now }.count
    }

    private func contextValue(_ context: HomeContext) -> String {
        switch context {
        case .today: Date.now.formatted(.dateTime.day().month(.abbreviated))
        case .reflections: String(localized: "\(weeklyReflectionCount) this week")
        case .reminders: String(localized: "\(reminders.count) active")
        }
    }

    private func homeHeadline(_ title: LocalizedStringKey, _ subtitle: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.largeTitle.bold())
            Text(subtitle).font(.title3).foregroundStyle(Color.secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(16)
    }

    @ViewBuilder
    private var watchConnectionNotice: some View {
        if deviceMode == .iPhoneAndWatch,
           viewModel.watchConnectionStatus == .appNotInstalled || viewModel.watchConnectionStatus == .noWatchPaired {
            Button {
                viewModel.presentAlert(viewModel.watchConnectionStatus == .appNotInstalled ? .watchAppNotInstalled : .watchNotPaired)
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.applewatch")
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Apple Watch Connection").font(.headline)
                        Text(viewModel.watchConnectionStatus == .appNotInstalled ? "Watch App Not Installed" : "Watch Not Paired")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(16)
                .background(.red.gradient, in: .rect(cornerRadius: 24))
                .contentShape(.rect(cornerRadius: 24))
            }
            .accessibilityIdentifier("home.watchConnection")
        }
    }

    // MARK: Health Kit Permission Widget
    
    @ViewBuilder
    private var healthPermissionsWidget: some View {
        switch viewModel.healthPermissionState {
        case .ok:
            EmptyView()
        case .needsRequest:
            LabeledCard(contentSpacing: 10) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("We need Health permission to read steps and heart rate.")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)

                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    } label: {
                        Label("Open Settings", systemImage: "arrow.up.right.square")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .tint(.pink)
                }
            } label: {
                Label("Connect Apple Health", systemImage: "heart.fill")
                .foregroundStyle(.pink)
            }
        case .unavailable:
            LabeledCard(contentSpacing: 10) {
                Text("Apple Health isn’t available on this device.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            } label: {
                Label("Health Not Available", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
        }
    }

    // MARK: Missed Reflections Widget
    
    @ViewBuilder
    private var missedReflectionsWidget: some View {
        if viewModel.missedReflections.isEmpty {
            LabeledCard(contentSpacing: 10) {
                Text("You're caught up.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            } label: {
                Label("No Missed Reflections", systemImage: "book.closed.fill")
                    .foregroundStyle(Color("BrandPrimary"))
            }
        } else {
            NavigationLink(value: HomeNavigationDestination.missedReflectionsList) {
                LabeledCard(contentSpacing: 10) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(viewModel.missedReflections.count > 10 ? "10+" : String(viewModel.missedReflections.count))
                            .font(.title2.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(.red)

                        Text(viewModel.missedReflections.count == 1 ? "reflection needs review" : "reflections need review")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                    }
                } label: {
                    Label("Missed Reflections", systemImage: "book.closed.fill")
                        .foregroundStyle(.red)
                } accessory: {
                    navigationAccessory("Review")
                }
            }
            .redacted(reason: viewModel.isFetchingMissedReflections ? .placeholder : .init())
        }
    }

    // MARK: Steps and Heart Rate Widgets
    
    private var stepsAndHeartRateWidgets: some View {
        let layout = dynamicTypeSize >= .xxxLarge
            ? AnyLayout(VStackLayout(spacing: 12))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 12))
        return layout {
            Button {
                onWidgetTap()
            } label: {
                StepsWidget(viewModel: viewModel)
            }
            
            Button {
                onWidgetTap()
            } label: {
                HeartRateWidget(viewModel: viewModel)
            }
        }
    }
    
    // MARK: Navigation Destination
    
    @ViewBuilder
    private func navigationDestination(for destination: HomeNavigationDestination) -> some View {
        switch destination {
        case .reviewsList:
            ReflectionsListView(viewModel: viewModel)
        case .remindersList:
            RemindersListView(viewModel: viewModel)
        case .missedReflectionsList:
            MissedReflectionsListView(viewModel: viewModel)
        case .analytics:
            AnalyticsView()
        }
    }

    // MARK: Sheet Content

    @ViewBuilder
    private func sheetContent(for sheet: HomeSheet) -> some View {
        switch sheet {
        case .editReflectionView(let reflection):
            EditReflectionView(reflection: reflection)
            .interactiveDismissDisabled()
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        case .createReminderView(let reminder):
            CreateReminderView(reminder: reminder)
                .interactiveDismissDisabled(reminder.isNil)
                .presentationDragIndicator(reminder.isNil ? .hidden : .visible)
        case .reviewsFilterView:
            ReflectionsFilterView(
                filterAndSortingPublisher: viewModel.filterAndSortingPublisher,
                activities: activities
            )
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: Alert Content
    
    private func alertContent(for alert: HomeAlert) -> Alert {
        switch alert {
        case .watchAppNotInstalled:
            return watchAppNotInstalledAlert
        case .watchNotPaired:
            return watchNotPairedAlert
        }
    }
    
    // MARK: Toast Content
    
    private func toastContent(for toast: HomeToast) -> some View {
        switch toast {
        case .successfullyCreatedReflection:
            Toast(
                title: "Successfully Created Reflection",
                message: "Your reflection has been saved"
            )
            .toastStyle(.success)
        }
    }
    
    // MARK: - Watch App Not Installed Alert
    
    private var watchAppNotInstalledAlert: Alert {
        Alert(
            title: Text("Watch App Not Installed"),
            message: Text("You have not installed MindfulPacer on your Apple Watch. Please navigate to Settings > Apple Watch for instructions on how to do this."),
            dismissButton: .default(Text("OK"))
        )
    }
    
    // MARK: Watch Not Paired Alert
    
    private var watchNotPairedAlert: Alert {
        Alert(
            title: Text("Watch Not Paired"),
            message: Text("Your Apple Watch is not paired with this iPhone."),
            primaryButton: .default(Text("Learn How to Pair")) {
                openURL(URL(string: "https://support.apple.com/en-us/HT204505")!)
            },
            secondaryButton: .cancel()
        )
    }

    // MARK: Shared Home Components

    private func navigationAccessory(_ title: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
            Image(systemName: "chevron.right")
        }
        .font(.subheadline)
        .foregroundStyle(Color(.systemGray2))
    }
}

// MARK: - Preview

#Preview {
    TabView {
        HomeView(onWidgetTap: { })
            .tabItem {
                Label("Home", systemImage: "house")
            }
    }
    .modelContainer(ModelContainer.preview)
    .tint(Color("BrandPrimary"))
}
