//
//  HomeView.swift
//  iOS
//
//  Created by Grigor Dochev on 26.08.2024.
//

import SwiftUI

// MARK: - Presentation Enums

enum HomeViewNavigationDestination: Hashable {
    case reviewsList
    case remindersList
    case analytics
    case missedReflectionsList
}

enum HomeViewSheet: Identifiable {
    case editReflectionView(Reflection?)
    case createReminderView(Reminder?)
    case reviewsFilterView
    case missedReflections

    var id: Int {
        switch self {
        case .editReflectionView: 0
        case .createReminderView: 1
        case .reviewsFilterView: 2
        case .missedReflections: 3
        }
    }
}

enum HomeViewToast: Identifiable {
    case successfullyCreatedReflection
    
    var id: Int {
        hashValue
    }
}

// MARK: - HomeView

struct HomeView: View {
    
    // MARK: Properties

    @State var viewModel: HomeViewModel = ScenesContainer.shared.homeViewModel()
    var onWidgetTap: () -> Void
    
    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
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
            .navigationDestination(for: HomeViewNavigationDestination.self, destination: navigationDestination)
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
            .onViewFirstAppear {
                viewModel.onViewFirstAppear()
            }
            .onAppear {
                viewModel.onViewAppear()
            }
        }
    }
    
    // MARK: Missed Reflections Widget
    
    @ViewBuilder
    private var missedReflectionsWidget: some View {
        if !viewModel.missedReflections.isEmpty {
            NavigationLink(value: HomeViewNavigationDestination.missedReflectionsList) {
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
                            Text(String(viewModel.missedReflections.count))
                                .fontWeight(.semibold)
                                .foregroundStyle(.red)
                                .fixedSize(horizontal: true, vertical: false)
                            
                            
                            Icon(name: "chevron.right", color: Color(.systemGray2))
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                }
            }
        } else {
            EmptyView()
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
    private func navigationDestination(for destination: HomeViewNavigationDestination) -> some View {
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
    private func sheetContent(for sheet: HomeViewSheet) -> some View {
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
        case .missedReflections:
            MissedReflectionsView(viewModel: viewModel)
                .presentationCornerRadius(16)
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: Toast Content
    
    private func toastContent(for toast: HomeViewToast) -> some View {
        switch toast {
        case .successfullyCreatedReflection:
            Toast(
                title: "Successfully Created Reflection",
                message: "Your reflection has been saved"
            )
            .toastStyle(.success)
        }
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
