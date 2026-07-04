//
//  MissedReflectionHealthCardConcept.swift
//  iOS
//
//  Created by Grigor Dochev on 04.07.2026.
//

import Charts
import SwiftUI

// MARK: - MissedReflectionHealthCardConcept

struct MissedReflectionHealthCardConcept: View {
    private let concept = MissedReflectionHealthConceptData.heartRate

    var body: some View {
        ScrollView {
            LabeledCard(
                contentSpacing: 18,
                contentPadding: 18,
                cornerRadius: 24
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(concept.summary)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()

                    metricSummary

                    MissedReflectionHealthChartConcept(concept: concept)
                        .frame(height: 190)
                }
            } label: {
                Label {
                    Text(concept.measurementTitle)
                } icon: {
                    Image(systemName: concept.measurementIcon)
                }
                .foregroundStyle(concept.tint)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private var metricSummary: some View {
        HStack(alignment: .top, spacing: 16) {
            metricColumn(
                title: "At trigger",
                value: concept.triggerValueText,
                unit: concept.unit,
                color: concept.tint
            )

            metricColumn(
                title: "Threshold",
                value: concept.thresholdText,
                unit: concept.unit,
                color: .secondary
            )
        }
    }

    private func metricColumn(
        title: String,
        value: String,
        unit: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text(title)
                    .font(.subheadline.weight(.semibold))
            } icon: {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }
            .foregroundStyle(color)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(unit)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(color)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - MissedReflectionHealthChartConcept

private struct MissedReflectionHealthChartConcept: View {
    let concept: MissedReflectionHealthConceptData

    var body: some View {
        VStack(spacing: 8) {
            Chart {
                RuleMark(y: .value("Threshold", concept.threshold))
                    .foregroundStyle(Color(.systemGray3))
                    .lineStyle(.init(lineWidth: 1.5, dash: [4, 4]))

                ForEach(concept.samples) { sample in
                    LineMark(
                        x: .value("Time", sample.date),
                        y: .value(concept.measurementTitle, sample.value)
                    )
                    .foregroundStyle(concept.tint)
                    .lineStyle(.init(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                }

                if let triggerSample = concept.triggerSample {
                    RuleMark(x: .value("Triggered", concept.triggerDate))
                        .foregroundStyle(Color(.systemGray3))
                        .lineStyle(.init(lineWidth: 2))

                    PointMark(
                        x: .value("Triggered", triggerSample.date),
                        y: .value(concept.measurementTitle, triggerSample.value)
                    )
                    .foregroundStyle(concept.tint)
                    .symbolSize(56)
                }
            }
            .chartXScale(domain: concept.dayRange)
            .chartYScale(domain: concept.valueRange)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
            .chartPlotStyle { plotArea in
                plotArea
                    .background(.clear)
            }

            axisLabels
        }
        .accessibilityLabel("\(concept.measurementTitle) missed reflection trigger chart")
        .accessibilityValue("\(concept.triggerValueText) \(concept.unit), threshold \(concept.thresholdText) \(concept.unit)")
    }

    private var axisLabels: some View {
        HStack(spacing: 12) {
            Text(concept.startTimeText)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(concept.triggerTimeText)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(concept.endTimeText)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.85)
    }
}

// MARK: - Concept Data

private struct MissedReflectionHealthConceptData {
    let measurementTitle: String
    let measurementIcon: String
    let unit: String
    let tint: Color
    let threshold: Double
    let summary: String
    let samples: [MissedReflectionHealthConceptSample]
    let triggerDate: Date

    var triggerSample: MissedReflectionHealthConceptSample? {
        samples.min { lhs, rhs in
            abs(lhs.date.timeIntervalSince(triggerDate)) < abs(rhs.date.timeIntervalSince(triggerDate))
        }
    }

    var triggerValueText: String {
        formattedValue(triggerSample?.value ?? 0)
    }

    var thresholdText: String {
        formattedValue(threshold)
    }

    var dayRange: ClosedRange<Date> {
        dayStart...dayEnd
    }

    var startTimeText: String {
        dayStart.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute())
    }

    var triggerTimeText: String {
        triggerDate.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute())
    }

    var endTimeText: String {
        "24:00"
    }

    var valueRange: ClosedRange<Double> {
        let values = samples.map(\.value) + [threshold]
        let minValue = max(0, (values.min() ?? 0) - 8)
        let maxValue = (values.max() ?? threshold) + 12
        return minValue...maxValue
    }

    private var dayStart: Date {
        Calendar.current.startOfDay(for: triggerDate)
    }

    private var dayEnd: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? triggerDate
    }

    private func formattedValue(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0)))
    }

    static var heartRate: MissedReflectionHealthConceptData {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: .now)
        let triggerDate = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: dayStart) ?? .now

        return MissedReflectionHealthConceptData(
            measurementTitle: "Heart Rate",
            measurementIcon: "heart.fill",
            unit: "bpm",
            tint: .pink,
            threshold: 55,
            summary: "Above 55 bpm for 2 minutes",
            samples: [
                .init(hour: 0.0, value: 44, dayStart: dayStart),
                .init(hour: 3.0, value: 45, dayStart: dayStart),
                .init(hour: 6.0, value: 46, dayStart: dayStart),
                .init(hour: 9.0, value: 48, dayStart: dayStart),
                .init(hour: 11.5, value: 51, dayStart: dayStart),
                .init(hour: 12.5, value: 58, dayStart: dayStart),
                .init(hour: 13.3, value: 62, dayStart: dayStart),
                .init(hour: 14.1, value: 60, dayStart: dayStart),
                .init(hour: 15.2, value: 67, dayStart: dayStart),
                .init(hour: 16.0, value: 70, dayStart: dayStart),
                .init(hour: 17.0, value: 72, dayStart: dayStart)
            ],
            triggerDate: triggerDate
        )
    }
}

private struct MissedReflectionHealthConceptSample: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double

    init(hour: Double, value: Double, dayStart: Date) {
        self.date = dayStart.addingTimeInterval(hour * 60 * 60)
        self.value = value
    }
}

// MARK: - Preview

#Preview {
    MissedReflectionHealthCardConcept()
}
