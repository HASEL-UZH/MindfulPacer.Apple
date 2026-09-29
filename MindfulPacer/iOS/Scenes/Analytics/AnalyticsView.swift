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
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var viewModel: AnalyticsViewModel
    
    @Query(sort: \Reflection.date, order: .reverse) private var allReflections: [Reflection]

    init(viewModel: AnalyticsViewModel? = nil) {
        _viewModel = State(initialValue: viewModel ?? ScenesContainer.shared.analyticsViewModel())
    }

    // MARK: Body
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Analytics")
                .navigationBarTitleDisplayMode(.inline)
                .background {
                    Color(.systemBackground)
                        .ignoresSafeArea()
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.presentSheet(.dateSelection)
                        } label: {
                            Label("Selected Date", systemImage: "calendar")
                        }
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
        GeometryReader { geometry in
            if dynamicTypeSize.isAccessibilitySize || geometry.size.height < 540 {
                ScrollView {
                    VStack(spacing: 0) {
                        chartSection(height: 220)
                        reflectionSelections
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGroupedBackground))
                    }
                }
            } else {
                // Athleon's stat detail layout: a fixed chart and a separate
                // scrollable panel of full-width selection controls.
                VStack(spacing: 0) {
                    chartSection(height: min(320, max(200, geometry.size.height * 0.34)))
                    Divider()
                    ScrollViewReader { proxy in
                        ScrollView {
                            reflectionSelections
                                .padding(16)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGroupedBackground))
                        .accessibilityIdentifier("analytics.reflections.list")
                        .onChange(of: viewModel.activeReflectionChipID) { _, selected in
                            guard let selected else { return }
                            withAnimation { proxy.scrollTo(selected, anchor: .top) }
                        }
                    }
                }
            }
        }
    }

    private func chartSection(height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Measurement Type", selection: $viewModel.selectedMeasurementType) {
                Text("Heart Rate").tag(MeasurementType.heartRate)
                Text("Steps").tag(MeasurementType.steps)
            }
            .pickerStyle(.segmented)

            StatChart(
                entries: viewModel.statChartData,
                configuration: statChartConfiguration(height: height),
                selectedPeriod: viewModel.statChartPeriodBinding,
                activeChipID: $viewModel.activeReflectionChipID,
                visibleWindow: $viewModel.visibleWindow
            )
            .id(viewModel.chartRevision)
            .overlay(alignment: .topTrailing) {
                if viewModel.isLoading { ProgressView().padding(.top, 44) }
            }
            if viewModel.loadFailed {
                Button("Try Again", systemImage: "arrow.clockwise", action: viewModel.refreshChart)
                    .foregroundStyle(Color.accentColor)
            }

        }
        .frame(maxWidth: 900)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
    }

    private var reflectionSelections: some View {
        let chips = Dictionary(uniqueKeysWithValues: viewModel.reflectionChips.map { ($0.id, $0) })
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Reflections in Period")
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                Spacer(minLength: 8)
                Button("Create Reflection", systemImage: "plus") {
                    viewModel.presentSheet(.editReflectionView(nil))
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .controlSize(.regular)
                .tint(.accentColor)
            }
            if viewModel.reflectionsInPeriod.isEmpty {
                Text("Your reflections will appear alongside your health data.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .padding(.vertical, 8)
            } else {
                Text("Select a reflection to highlight it on the chart.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                ForEach(viewModel.reflectionsInPeriod) { bucket in
                    reflectionSelection(bucket, chip: chips[viewModel.reflectionChipID(for: bucket)])
                        .id(viewModel.reflectionChipID(for: bucket))
                }
            }
        }
        .frame(maxWidth: 900, alignment: .leading)
        .frame(maxWidth: .infinity)
    }

    private func reflectionSelection(_ bucket: ReflectionBucket, chip: StatChartChip?) -> some View {
        let chipID = viewModel.reflectionChipID(for: bucket)
        let isSelected = viewModel.activeReflectionChipID == chipID
        return VStack(alignment: .leading, spacing: 10) {
            CapsuleSelectableButton(fillColor: .accentColor, isSelected: isSelected) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.activeReflectionChipID = isSelected ? nil : chipID
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: chip?.systemImage ?? "book.closed")
                        .frame(width: 20)
                        .accessibilityHidden(true)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 12) {
                            Text(chip?.label ?? String(localized: "Reflection"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            reflectionTime(bucket.startDate)
                                .font(.subheadline.weight(.semibold))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(chip?.label ?? String(localized: "Reflection"))
                            reflectionTime(bucket.startDate)
                                .font(.subheadline.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .font(.body)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityIdentifier("analytics.reflectionRow.\(bucket.reflections.first?.id.uuidString ?? chipID)")
            .accessibilityHint("Show on chart")

            if isSelected {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(bucket.reflections) { reflection in
                        if reflection.id != bucket.reflections.first?.id { Divider() }
                        selectedReflectionDetails(reflection)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
            }
        }
    }

    @ViewBuilder
    private func reflectionTime(_ date: Date) -> some View {
        if viewModel.selectedPeriod == .week {
            Text(date, format: .dateTime.weekday(.abbreviated).hour().minute())
        } else {
            Text(date, format: .dateTime.hour().minute())
        }
    }

    private func selectedReflectionDetails(_ reflection: Reflection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(reflection.subactivity?.name ?? reflection.activity?.name ?? String(localized: "Reflection"))
                .font(.headline).foregroundStyle(Color.primary)
            Text(reflection.date, format: .dateTime.month(.abbreviated).day().hour().minute())
                .font(.subheadline).foregroundStyle(Color.secondary)
            if reflection.didTriggerCrash {
                Label("Crash", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
            if let wellBeing = reflection.wellBeing {
                Text(Symptom.wellBeing(wellBeing).description)
                    .foregroundStyle(Symptom.wellBeing(wellBeing).color)
            }
            if let mood = reflection.mood {
                Text("\(mood.emoji) \(mood.text)").foregroundStyle(Color.secondary)
            }
            Button("Edit Reflection", systemImage: "square.and.pencil") {
                viewModel.presentSheet(.editReflectionView(reflection))
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.capsule)
            .controlSize(.regular)
            .tint(.accentColor)
        }
        .font(.subheadline)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func statChartConfiguration(height: CGFloat) -> StatChartConfiguration {
        StatChartConfiguration(
            markStyle: viewModel.statChartMarkStyle,
            tintColor: viewModel.selectedMeasurementType.color,
            chartHeight: height,
            unitLabel: viewModel.selectedMeasurementType.units,
            summaryMode: viewModel.statChartSummaryMode,
            periods: viewModel.activeStatChartPeriods,
            defaultPeriod: viewModel.statChartPeriod,
            visibleDomainLength: viewModel.statChartDomainMapping[viewModel.statChartPeriod] ?? 86_400,
            valueFormatter: { value in Int(value).formatted() },
            xAxisDateFormat: viewModel.statChartXAxisDateFormat,
            xAxisDateUnit: viewModel.getXUnitForPeriod(viewModel.selectedPeriod),
            chips: viewModel.reflectionChips,
            showChipsInline: false,
            periodDomainMapping: viewModel.statChartDomainMapping,
            xAxisDateFormatForPeriod: { period in
                switch period {
                case .oneHour, .twoHours: "HH:mm"
                case .day: "HH"
                case .week: "EEE"
                case .month: "d"
                case .sixMonths, .year: "MMM"
                }
            },
            minimumValuePadding: viewModel.selectedMeasurementType == .heartRate ? 10 : nil,
            dateDomain: viewModel.chartDateDomain,
            initialWindowStart: viewModel.initialVisibleWindow.startDate,
            startsAtZero: viewModel.selectedMeasurementType == .steps
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
                .presentationDragIndicator(reflection.isNil ? .hidden : .visible)
        case .dateSelection:
            DateSelectionSheet(viewModel: viewModel)
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
