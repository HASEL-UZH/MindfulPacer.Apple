//
//  AnalyticsView.swift
//  iOS
//
//  Created by Grigor Dochev on 12.09.2024.
//

import SwiftUI

// MARK: - AnalyticsView

struct AnalyticsView: View {
    // MARK: Properties
    
    @State private var viewModel: AnalyticsViewModel = ScenesContainer.shared.analyticsViewModel()
    
    // MARK: Body
    
    var body: some View {
        NavigationStack {
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
                        Text("Visualise your \(viewModel.selectedMeasurementType.rawValue.lowercased()) data within the last \(viewModel.selectedPeriod.description).")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                ) {
                    LineChart(
                        chartData: viewModel.selectedMeasurementType == .heartRate ? viewModel.heartRateChartData : viewModel.stepsChartData,
                        color: viewModel.selectedMeasurementType.color,
                        measurementType: viewModel.selectedMeasurementType
                    )
                } footer: {
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
                .padding(.horizontal)

                VStack(spacing: 0) {
                    Text("Reviews")
                        .font(.title.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    RoundedList {
                        ReviewCell(review: Review()) {
                            
                        }
                    }
                    .safeAreaPadding(.top)
                }
                
                Spacer()
            }
            .navigationTitle("Analytics")
            .background {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker(selection: $viewModel.selectedMeasurementType) {
                        ForEach(MeasurementType.allCases, id: \.self) { measurementType in
                            Label(
                                measurementType.rawValue,
                                systemImage: measurementType.icon
                            )
                        }
                    } label: {
                        Label(
                            viewModel.selectedMeasurementType.rawValue,
                            systemImage: viewModel.selectedMeasurementType.icon
                        )
                        
                    }
                    .pickerStyle(.menu)
                    .tint(Color("BrandPrimary"))
                }
            }
            .onViewFirstAppear {
                viewModel.onViewFirstAppear()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AnalyticsView()
}
