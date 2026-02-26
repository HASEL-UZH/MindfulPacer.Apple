//
//  AnalyticsView.swift
//  iOS
//
//  Created by Grigor Dochev on 12.09.2024.
//

import SwiftUI

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

    // MARK: Body
    
    var body: some View {
        NavigationStack {
            chart
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
                        } label: {
                            Text("View Options")
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
                .onAppear {
                    viewModel.onViewAppear()
                }
        }
    }
    
    // MARK: Chart
    
    private var chart: some View {
        IconLabelGroupBox(
            label:
                IconLabel(
                    icon: viewModel.selectedMeasurementType.icon,
                    title: viewModel.selectedMeasurementType.localized,
                    labelColor: viewModel.selectedMeasurementType.color,
                    background: true
                ),
            description:
                Text(viewModel.chartHeaderDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        ) {
            VStack(spacing: 16) {
                Picker(selection: $viewModel.selectedPeriod) {
                    ForEach(Period.activeCases(for: viewModel.selectedDateForPeriod), id: \.self) { period in
                        Text(period.displayName)
                            .tag(period.displayName)
                    }
                } label: {
                    EmptyView()
                }
                .pickerStyle(.segmented)
                
                switch viewModel.selectedMeasurementType {
                case .heartRate:
                    HeartRateChartView(viewModel: viewModel)
                case .steps:
                    StepsChartView(viewModel: viewModel)
                }
                
                Divider()
                
                if viewModel.selectedReflectionBucket.isNotNil {
                    reflectionsInBucket
                } else {
                    reflectionsInPeriod
                }
            }
        } footer: {
            Button {
                viewModel.presentSheet(.editReflectionView(nil))
            } label: {
                IconLabel(
                    icon: "plus.circle",
                    title: String(localized: "Create Reflection"),
                    labelColor: Color("BrandPrimary")
                )
                .font(.subheadline.weight(.semibold))
            }
        }
        .iconLabelGroupBoxStyle(.divider)
        .overlay(alignment: .top) {
            selectedValueDetail
        }
        .padding([.horizontal, .bottom])
    }
    
    // MARK: Reflections in Period
    
    private var reflectionsInPeriod: some View {
        VStack(spacing: 0) {
            Text("Reflections")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if viewModel.reflectionsInPeriod.isEmpty {
                EmptyStateView(
                    image: "book.pages",
                    title: String(localized: "No Reflections"),
                    description: String(localized: "There are no reflections.")
                )
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(viewModel.reflectionsInPeriod) { reflectionBucket in
                            ForEach(reflectionBucket.reflections) { reflection in
                                ReflectionCell(
                                    reflection: reflection,
                                    backgroundColor: Color(.tertiarySystemGroupedBackground)
                                ) {
                                    viewModel.presentSheet(.editReflectionView(reflection))
                                }
                                
                                Divider()
                            }
                        }
                    }
                    .cornerRadius(16)
                }
                .safeAreaPadding(.vertical)
            }
        }
    }
    
    // MARK: Reflections in Bucket
    
    @ViewBuilder
    private var reflectionsInBucket: some View {
        if let reflectionBucket = viewModel.selectedReflectionBucket {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Reflections")
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button {
                            viewModel.selectedReflectionBucket = nil
                        } label: {
                            IconLabel(
                                icon: "arrow.trianglehead.counterclockwise",
                                title: "Reset",
                                labelColor: Color("BrandPrimary")
                            )
                            .font(.subheadline.weight(.semibold))
                        }
                    }
                    
                    Group {
                        Text(reflectionBucket.startDate.formatted(.dateTime.weekday(.wide).year().month().day().minute().hour()))
                        +
                        Text(" - ")
                        +
                        Text(reflectionBucket.endDate.formatted(.dateTime.weekday(.wide).year().month().day().minute().hour()))
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(reflectionBucket.reflections) { reflection in
                            ReflectionCell(
                                reflection: reflection,
                                backgroundColor: Color(.tertiarySystemGroupedBackground)
                            ) {
                                viewModel.presentSheet(.editReflectionView(reflection))
                            }
                            
                            Divider()
                        }
                    }
                    .cornerRadius(16)
                }
                .safeAreaPadding(.vertical)
            }
        }
    }
    
    // MARK: Selected Value Detail
    
    @ViewBuilder
    private var selectedValueDetail: some View {
        if let selectedChartDataItem = viewModel.selectedChartDataItem {
            HStack {
                VStack(alignment: .leading, spacing: 16) {
                    IconLabel(
                        icon: "calendar",
                        title: selectedChartDataItem.startDate.formatted(.dateTime.weekday(.wide).year().month().day()),
                        labelColor: .secondary,
                        background: true
                    )
                    .font(.subheadline.weight(.semibold))
                    
                    Group {
                        switch viewModel.selectedMeasurementType {
                        case .heartRate:
                            Text("\(selectedChartDataItem.startDate.formatted(.dateTime.minute().hour()))")
                        case .steps:
                            switch viewModel.selectedPeriod {
                            case .oneHour, .twoHours, .day:
                                Text("\(selectedChartDataItem.startDate.formatted(.dateTime.minute().hour()))")
                            case .week:
                                Text("Total for Day")
                            }
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("\(Int(selectedChartDataItem.value))")
                    .font(.title3.bold())
                +
                Text(" \(viewModel.selectedMeasurementType.units)")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background {
                UnevenRoundedRectangle(cornerRadii: .init(topLeading: 16, topTrailing: 16))
                    .foregroundStyle(Color(.secondarySystemGroupedBackground))
            }
        } else {
            EmptyView()
        }
    }
    
    // MARK: Sheet Content
    
    @ViewBuilder
    private func sheetContent(for sheet: AnalyticsViewSheet) -> some View {
        switch sheet {
        case .editReflectionView(let reflection):
            EditReflectionView(reflection: reflection)
                .interactiveDismissDisabled(reflection.isNil)
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
