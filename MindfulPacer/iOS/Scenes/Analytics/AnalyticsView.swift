//
//  AnalyticsView.swift
//  iOS
//
//  Created by Grigor Dochev on 12.09.2024.
//

import SwiftUI
import SwiftData

// MARK: - Presentation Enums

enum AnalyticsViewSheet: Identifiable {
    case editReflectionView(Reflection?)
    case dateSelection
    
    var id: Int {
        switch self {
        case .editReflectionView: 0
        case .dateSelection: 1
        }
    }
}

// MARK: - AnalyticsView

struct AnalyticsView: View {
    
    // MARK: Properties
    
    @State private var viewModel: AnalyticsViewModel = ScenesContainer.shared.analyticsViewModel()
    
    @Query(sort: \Reflection.date, order: .reverse) private var allReflections: [Reflection]

    // MARK: Body
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Analytics")
                .background {
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Picker(selection: $viewModel.selectedMeasurementType) {
                                ForEach(MeasurementType.allCases, id: \.self) { measurementType in
                                    Label(measurementType.localized, systemImage: measurementType.icon)
                                }
                            } label: {
                                Label("Measurement Type", systemImage: "ruler.fill")
                                Text(viewModel.selectedMeasurementType.localized)
                            }
                            .pickerStyle(.menu)
                            
                            Button {
                                viewModel.presentSheet(.dateSelection)
                            } label: {
                                Label("Selected Date", systemImage: "calendar")
                                Text(viewModel.selectedDateForPeriod.formatted(.dateTime.day().month()))
                            }

                            Button {
                                viewModel.presentSheet(.editReflectionView(nil))
                            } label: {
                                Label("Create Reflection", systemImage: "plus.circle")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                        .tint(Color("BrandPrimary"))
                    }
                }
                .sheet(item: $viewModel.activeSheet, onDismiss: {
                    withAnimation {
                        viewModel.onSheetDismissed()
                    }
                }, content: { sheet in
                    sheetContent(for: sheet)
                })
                .onViewFirstAppear {
                    viewModel.onViewFirstAppear()
                }
                .onChange(of: allReflections) { _, _ in
                    viewModel.updateReflectionsInPeriod()
                }
        }
    }
    
    // MARK: Chart
    
    private var content: some View {
        ScrollView {
            chartContent
                .padding([.horizontal, .bottom])
                .padding(.top, 8)
        }
    }

    @ViewBuilder
    private var chartContent: some View {
        if viewModel.statChartData.isEmpty {
            EmptyStateView(
                image: viewModel.chartEmptyStateImage,
                title: viewModel.chartEmptyStateTitle,
                description: String(localized: "Synchronize your smartwatch")
            )
            .frame(maxWidth: .infinity)
            .frame(minHeight: 360)
        } else {
            StatChart(
                entries: viewModel.statChartData,
                configuration: statChartConfiguration,
                selectedPeriod: viewModel.statChartPeriodBinding,
                activeChipID: $viewModel.activeReflectionChipID
            )
        }
    }

    private var statChartConfiguration: StatChartConfiguration {
        StatChartConfiguration(
            markStyle: viewModel.statChartMarkStyle,
            tintColor: viewModel.selectedMeasurementType.color,
            chartHeight: 260,
            unitLabel: viewModel.selectedMeasurementType.units,
            summaryMode: viewModel.statChartSummaryMode,
            periods: viewModel.activeStatChartPeriods,
            defaultPeriod: viewModel.statChartPeriod,
            visibleDomainLength: viewModel.statChartDomainMapping[viewModel.statChartPeriod] ?? 86_400,
            valueFormatter: { value in Int(value).formatted() },
            xAxisDateFormat: viewModel.statChartXAxisDateFormat,
            xAxisDateUnit: viewModel.getXUnitForPeriod(viewModel.selectedPeriod),
            chips: viewModel.reflectionChips,
            periodDomainMapping: viewModel.statChartDomainMapping,
            xAxisDateFormatForPeriod: { period in
                switch period {
                case .oneHour, .twoHours:
                    "HH:mm"
                case .day:
                    "HH"
                case .week:
                    "EEE"
                case .month:
                    "d"
                case .sixMonths, .year:
                    "MMM"
                }
            }
        )
    }

    // MARK: Sheet Content
    
    @ViewBuilder
    private func sheetContent(for sheet: AnalyticsViewSheet) -> some View {
        switch sheet {
        case .editReflectionView(let reflection):
            EditReflectionView(reflection: reflection)
                .interactiveDismissDisabled(reflection.isNil)
                .presentationDetents([.large])
                .presentationCornerRadius(16)
                .presentationDragIndicator(reflection.isNil ? .hidden : .visible)
        case .dateSelection:
            DateSelectionSheet(viewModel: viewModel)
                .presentationCornerRadius(16)
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Preview

#Preview {
    TabView {
        AnalyticsView()
            .tabItem {
                Label("Home", systemImage: "house")
            }
    }
}
