//
//  HomeView.swift
//  iOS
//
//  Created by Grigor Dochev on 26.08.2024.
//

import SwiftUI

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
    @AppStorage(DeviceMode.appStorageKey) var deviceMode: DeviceMode = .iPhoneOnly
    @State var viewModel: HomeViewModel = ScenesContainer.shared.homeViewModel()
    var onWidgetTap: () -> Void
    
    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    healthPermissionsWidget
                    missedReflectionsWidget
                    ReflectionsWidget(viewModel: viewModel)
                    stepsAndHeartRateWidgets
                    RemindersWidget(viewModel: viewModel)
                }
                .padding([.horizontal, .bottom])
            }
            .navigationTitle("Home")
            .background {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
            }
            .navigationDestination(for: HomeNavigationDestination.self, destination: navigationDestination)
            .refreshable {
                viewModel.onRefresh()
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
                viewModel.onViewFirstAppear()
                viewModel.configure(deviceMode)
            }
            .onAppear {
                viewModel.onViewAppear()          
                viewModel.configure(deviceMode)
            }
            .onChange(of: userHasSeenOnboarding) {
                viewModel.onRefresh()
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
    
    private var healthPermissionsWidget: some View {
        Group {
            switch viewModel.healthPermissionState {
            case .ok:
                EmptyView()
            case .needsRequest:
                IconLabelGroupBox(
                    label:
                        IconLabel(
                            image: "Apple Health",
                            title: String(localized: "Connect Apple Health"),
                            labelColor: .pink,
                            background: true
                        )
                ) {
                    Text("We need Health permission to read steps and heart rate.")
                        .foregroundStyle(.secondary)
                } footer: {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    } label: {
                        IconLabel(
                            icon: "arrow.up.right.square.fill",
                            title: String(localized: "Open Settings"),
                            labelColor: .secondary
                        )
                        .font(.subheadline.weight(.semibold))
                    }
                }
            case .unavailable:
                Card {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Health Not Available")
                                .font(.subheadline.weight(.semibold))
                            Text("Apple Health isn’t available on this device.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: Missed Reflections Widget
    
    @ViewBuilder
    private var missedReflectionsWidget: some View {
        if viewModel.missedReflections.isEmpty {
            Card {
                HStack {
                    IconLabel(
                        image: "book.pages.fill.badge.checkmark",
                        title: String(localized: "No Missed Reflections"),
                        labelColor: .brandPrimary,
                        background: true
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .layoutPriority(1)
                    
                    Spacer()
                }
            }
        } else {
            NavigationLink(value: HomeNavigationDestination.missedReflectionsList) {
                Card {
                    HStack {
                        IconLabel(
                            image: "book.pages.fill.badge.exclamationmark",
                            title: String(localized: "Missed Reflections"),
                            labelColor: .red,
                            background: true
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .layoutPriority(1)
                        
                        Spacer(minLength: 16)
                        
                        HStack(spacing: 4) {
                            Text(viewModel.missedReflections.count > 10 ? "10+" : String(viewModel.missedReflections.count))
                                .fontWeight(.semibold)
                                .foregroundStyle(.red)
                                .fixedSize(horizontal: true, vertical: false)
                            
                            
                            Icon(name: "chevron.right", color: Color(.systemGray2))
                                .font(.subheadline.weight(.semibold))
                                .redacted(reason: .init())
                        }
                    }
                }
            }
            .redacted(reason: viewModel.isFetchingMissedReflections ? .placeholder : .init())
        }
    }

    // MARK: Steps and Heart Rate Widgets
    
    private var stepsAndHeartRateWidgets: some View {
        HStack(spacing: 16) {
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
            .presentationCornerRadius(16)
        case .createReminderView(let reminder):
            CreateReminderView(reminder: reminder)
                .interactiveDismissDisabled(reminder.isNil)
                .presentationCornerRadius(16)
                .presentationDragIndicator(reminder.isNil ? .hidden : .visible)
        case .reviewsFilterView:
            ReflectionsFilterView(filterAndSortingPublisher: viewModel.filterAndSortingPublisher)
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
}

// MARK: - Preview

#Preview {
    TabView {
        HomeView(onWidgetTap: { })
            .tabItem {
                Label("Home", systemImage: "house")
            }
    }
    .tint(Color("BrandPrimary"))
}
