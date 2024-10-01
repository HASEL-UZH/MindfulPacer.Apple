//
//  AnalyticsView.swift
//  iOS
//
//  Created by Grigor Dochev on 12.09.2024.
//

import SwiftUI

// MARK: - Presentation Enums

enum AnalyticsViewSheet: Identifiable {
    case editReviewSheet(Review?)

    var id: Int {
        switch self {
        case .editReviewSheet: 0
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
                    VStack(spacing: 16) {
                        LineChartView(
                            viewModel: viewModel,
                            onReviewSelected: { review in
                                viewModel.presentSheet(.editReviewSheet(review))
                            }
                        )
                        
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
                .padding(.horizontal)
                
                reviewsInPeriod
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
    
    // MARK: Reviews in Period
    
    private var reviewsInPeriod: some View {
        VStack(spacing: 0) {
            Text("Reviews")
                .font(.title.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            if viewModel.reviewsInPeriod.isEmpty {
                EmptyStateView(
                    image: "book.pages",
                    title: "No Reviews",
                    description: "There are no reviews in the selected period."
                )
            } else {
                RoundedList {
                    ForEach(viewModel.reviewsInPeriod) { review in
                        ReviewCell(review: review) {
                            viewModel.presentSheet(.editReviewSheet(review))
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
        case .editReviewSheet(let review):
            EditReviewView(review: review)
                .interactiveDismissDisabled(review.isNil)
                .presentationCornerRadius(16)
                .presentationDragIndicator(review.isNil ? .hidden : .visible)
        }
    }
}

// MARK: - Preview

#Preview {
    AnalyticsView()
}
