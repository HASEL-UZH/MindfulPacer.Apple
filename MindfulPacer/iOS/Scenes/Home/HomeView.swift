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
    @AppStorage("userHasSeenOnboarding") var userHasSeenOnboarding: Bool = false
    @State var viewModel: HomeViewModel = ScenesContainer.shared.homeViewModel()
    var onWidgetTap: () -> Void
    
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
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 10) {
                    healthPermissionsWidget
                    missedReflectionsWidget
                    ReflectionsWidget(viewModel: viewModel)
                    stepsAndHeartRateWidgets
                    RemindersWidget(viewModel: viewModel)
                }
                .padding([.horizontal, .bottom])
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .background {
                ZStack {
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        LinearGradient(
                            colors: [
                                Color("BrandPrimary").opacity(0.16),
                                Color.pink.opacity(0.08),
                                Color(.systemGroupedBackground).opacity(0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 280)
                        .ignoresSafeArea(edges: .top)

                        Spacer()
                    }
                }
            }
            .navigationDestination(for: HomeNavigationDestination.self, destination: navigationDestination)
            .refreshable {
                viewModel.onRefresh(reminders: reminders)
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.watchConnectionStatus == .appNotInstalled {
                        Button {
                            viewModel.presentAlert(.watchAppNotInstalled)
                        } label: {
                            Image(systemName: "exclamationmark.applewatch")
                                .foregroundStyle(.orange)
                        }
                    } else if viewModel.watchConnectionStatus == .noWatchPaired {
                        Button {
                            viewModel.presentAlert(.watchNotPaired)
                        } label: {
                            Image(systemName: "applewatch.slash")
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Health Kit Permission Widget
    
    @ViewBuilder
    private var healthPermissionsWidget: some View {
        switch viewModel.healthPermissionState {
        case .ok:
            EmptyView()
        case .needsRequest:
            LabeledCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("We need Health permission to read steps and heart rate.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

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
                Label {
                    Text("Connect Apple Health")
                } icon: {
                    Image("Apple Health")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                }
                .foregroundStyle(.pink)
            }
        case .unavailable:
            LabeledCard {
                Text("Apple Health isn’t available on this device.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
            LabeledCard {
                Text("You're caught up.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } label: {
                Label("No Missed Reflections", systemImage: "book.pages.fill.badge.checkmark")
                    .foregroundStyle(Color("BrandPrimary"))
            }
        } else {
            NavigationLink(value: HomeNavigationDestination.missedReflectionsList) {
                LabeledCard {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(viewModel.missedReflections.count > 10 ? "10+" : String(viewModel.missedReflections.count))
                            .font(.title2.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(.red)

                        Text(viewModel.missedReflections.count == 1 ? "reflection needs review" : "reflections need review")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } label: {
                    Label("Missed Reflections", systemImage: "book.pages.fill.badge.exclamationmark")
                        .foregroundStyle(.red)
                } accessory: {
                    navigationAccessory("Review")
                }
            }
            .buttonStyle(.plain)
            .redacted(reason: viewModel.isFetchingMissedReflections ? .placeholder : .init())
        }
    }

    // MARK: Steps and Heart Rate Widgets
    
    private var stepsAndHeartRateWidgets: some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                onWidgetTap()
            } label: {
                StepsWidget(viewModel: viewModel)
            }
            .buttonStyle(.plain)
            
            Button {
                onWidgetTap()
            } label: {
                HeartRateWidget(viewModel: viewModel)
            }
            .buttonStyle(.plain)
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
            .presentationCornerRadius(16)
        case .createReminderView(let reminder):
            CreateReminderView(reminder: reminder)
                .interactiveDismissDisabled(reminder.isNil)
                .presentationCornerRadius(16)
                .presentationDragIndicator(reminder.isNil ? .hidden : .visible)
        case .reviewsFilterView:
            ReflectionsFilterView(
                filterAndSortingPublisher: viewModel.filterAndSortingPublisher,
                activities: activities
            )
                .presentationCornerRadius(16)
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
