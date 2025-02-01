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
                    IconLabelGroupBox(
                        label:
                            IconLabel(
                                icon: viewModel.selectedMeasurementType.icon,
                                title: viewModel.selectedMeasurementType.rawValue,
                                labelColor: viewModel.selectedMeasurementType.color,
                                background: true
                            ),
                        description:
                            Text("\(viewModel.selectedMeasurementType.rawValue) data within last \(viewModel.selectedPeriod.description).")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    ) {
                        VStack(spacing: 16) {
                            MeasurementChartView(viewModel: viewModel) { reflection in
                                viewModel.presentSheet(.editReflectionView(reflection))
                            }
                           
                            Picker(selection: $viewModel.selectedPeriod) {
                                ForEach(Period.allCases, id: \.self) { period in
                                    Text(period.rawValue)
                                        .tag(period)
                                }
                            } label: {
                                EmptyView()
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .frame(height: proxy.size.height / 2)
                    .padding(.horizontal)
                    
                    reviewsInPeriod
                        .frame(height: proxy.size.height / 2)
                }
            }
            .navigationTitle("Analytics")
            .background {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
            }
            .toolbar {
                /// Will add back in later when there are more view options
                //                ToolbarItem(placement: .topBarTrailing) {
                //                    Menu {
                //                        Picker(selection: $viewModel.selectedMeasurementType) {
                //                            ForEach(MeasurementType.allCases, id: \.self) { measurementType in
                //                                Label(measurementType.rawValue, systemImage: measurementType.icon)
                //                            }
                //                        } label: {
                //                            Text("Measurement Type")
                //                        }
                //                        .pickerStyle(.menu)
                //                        .tint(Color("BrandPrimary"))
                //                    } label: {
                //                        Text("View Options")
                //                    }
                //                    .tint(Color("BrandPrimary"))
                //                }
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
    
    // MARK: Reflections in Period
    
    private var reviewsInPeriod: some View {
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
            
            if viewModel.reviewsInPeriod.isEmpty {
                EmptyStateView(
                    image: "book.pages",
                    title: "No Reflections",
                    description: "There are no reflections within the last \(viewModel.selectedPeriod.description)."
                )
            } else {
                RoundedList {
                    ForEach(viewModel.reviewsInPeriod) { reflection in
                        ReflectionCell(reflection: reflection) {
                            viewModel.presentSheet(.editReflectionView(reflection))
                        }
                    }
                }
                .safeAreaPadding(.top)
            }
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
