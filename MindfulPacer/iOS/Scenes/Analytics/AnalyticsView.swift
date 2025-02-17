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
    
    var id: Int {
        switch self {
        case .editReflectionView: 0
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
            GeometryReader { proxy in
                VStack(spacing: 16) {
                    chart
                        .frame(height: proxy.size.height / 2)
                        .padding(.horizontal)
                    
                    Group {
                        if viewModel.selectedReflectionBucket.isNotNil {
                            reflectionsInBucket
                        } else {
                            reflectionsInPeriod
                        }
                    }
                    .frame(height: proxy.size.height / 2)
                }
            }
            .navigationTitle("Analytics")
            .background {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(MeasurementType.allCases, id: \.self) { measurementType in
                            Button {
                                viewModel.selectedMeasurementType = measurementType
                            } label: {
                                Label(measurementType.rawValue, systemImage: measurementType.icon)
                            }
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
                    title: viewModel.selectedMeasurementType.rawValue,
                    labelColor: viewModel.selectedMeasurementType.color,
                    background: true
                ),
            description:
                Text(viewModel.chartDescriptionText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        ) {
            VStack(spacing: 16) {
                Picker(selection: $viewModel.selectedPeriod) {
                    ForEach(Period.allCases, id: \.self) { period in
                        Text(period.displayName)
                            .tag(period)
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
            }
        }
        .overlay(alignment: .top) {
            selectedValueDetail
        }
    }
    
    // MARK: Reflections in Period
    
    private var reflectionsInPeriod: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Reflections")
                    .font(.title.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Button {
                    viewModel.presentSheet(.editReflectionView(nil))
                } label: {
                    IconLabel(
                        icon: "plus.circle",
                        title: "Create Reflection",
                        labelColor: Color("BrandPrimary")
                    )
                    .font(.subheadline.weight(.semibold))
                }
            }
            .padding(.horizontal)
            
            if viewModel.reflectionsInPeriod.isEmpty {
                EmptyStateView(
                    image: "book.pages",
                    title: "No Reflections",
                    description: "There are no reflections within the last \(viewModel.selectedPeriod.description)."
                )
            } else {
                RoundedList {
                    ForEach(viewModel.reflectionsInPeriod) { reflectionBucket in
                        ForEach(reflectionBucket.reflections) { reflection in
                            ReflectionCell(reflection: reflection) {
                                viewModel.presentSheet(.editReflectionView(reflection))
                            }
                        }
                    }
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
                            .font(.title.bold())
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
                .padding(.horizontal)
                
                RoundedList {
                    ForEach(reflectionBucket.reflections) { reflection in
                        ReflectionCell(reflection: reflection) {
                            viewModel.presentSheet(.editReflectionView(reflection))
                        }
                    }
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
                                Text("\(selectedChartDataItem.startDate.formatted(.dateTime.minute().hour())) - \(selectedChartDataItem.endDate.formatted(.dateTime.minute().hour()))")
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
        }
    }
}

// MARK: - Preview

#Preview {
    AnalyticsView()
}
