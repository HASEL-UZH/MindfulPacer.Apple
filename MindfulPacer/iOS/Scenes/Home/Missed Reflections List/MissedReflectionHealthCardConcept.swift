//
//  MissedReflectionHealthCardConcept.swift
//  iOS
//
//  Created by Grigor Dochev on 04.07.2026.
//

import SwiftUI

// MARK: - MissedReflectionHealthCardConcept

struct MissedReflectionHealthCardConcept: View {
    private let tint: Color = .pink
    private let thresholdValue = 55
    private let triggerValue = 72
    private let triggerTime = "17:00"

    var body: some View {
        ScrollView {
            LabeledCard(
                contentSpacing: 22,
                contentPadding: 20,
                cornerRadius: 24
            ) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Above 55 bpm for 2 minutes")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()

                    comparisonValues

                    MissedReflectionHealthChartConcept(
                        tint: tint,
                        thresholdValue: thresholdValue,
                        triggerValue: triggerValue,
                        triggerTime: triggerTime
                    )
                    .frame(height: 260)
                }
            } label: {
                Label {
                    Text("Heart Rate")
                } icon: {
                    Image(systemName: "heart.fill")
                }
                .foregroundStyle(tint)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private var comparisonValues: some View {
        HStack(alignment: .top, spacing: 20) {
            metricColumn(
                title: "Triggered",
                value: "\(triggerValue)",
                unit: "bpm",
                color: tint
            )

            metricColumn(
                title: "Threshold",
                value: "\(thresholdValue)",
                unit: "bpm",
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
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(title)
                    .font(.headline.weight(.semibold))
            } icon: {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
            }
            .foregroundStyle(color)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
                    .minimumScaleFactor(0.75)

                Text(unit)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - MissedReflectionHealthChartConcept

private struct MissedReflectionHealthChartConcept: View {
    let tint: Color
    let thresholdValue: Int
    let triggerValue: Int
    let triggerTime: String

    private let todayPoints: [CGPoint] = [
        CGPoint(x: 0.00, y: 0.12),
        CGPoint(x: 0.06, y: 0.13),
        CGPoint(x: 0.18, y: 0.13),
        CGPoint(x: 0.32, y: 0.14),
        CGPoint(x: 0.42, y: 0.18),
        CGPoint(x: 0.48, y: 0.34),
        CGPoint(x: 0.54, y: 0.38),
        CGPoint(x: 0.58, y: 0.44),
        CGPoint(x: 0.62, y: 0.70),
        CGPoint(x: 0.66, y: 0.82),
        CGPoint(x: 0.72, y: 0.82)
    ]

    private let thresholdPoints: [CGPoint] = [
        CGPoint(x: 0.32, y: 0.18),
        CGPoint(x: 0.42, y: 0.26),
        CGPoint(x: 0.52, y: 0.42),
        CGPoint(x: 0.62, y: 0.55),
        CGPoint(x: 0.72, y: 0.72),
        CGPoint(x: 0.82, y: 0.86),
        CGPoint(x: 0.94, y: 0.88)
    ]

    var body: some View {
        Canvas { context, size in
            let plotRect = CGRect(
                x: 4,
                y: 10,
                width: size.width - 8,
                height: size.height - 44
            )

            let markerX = plotRect.minX + plotRect.width * 0.72
            let todayPoint = point(todayPoints.last!, in: plotRect)
            let thresholdPoint = point(thresholdPoints[4], in: plotRect)

            drawDottedXAxis(in: &context, plotRect: plotRect)
            drawPath(
                todayPoints,
                in: &context,
                plotRect: plotRect,
                color: tint,
                opacity: 1,
                lineWidth: 5
            )
            drawPath(
                thresholdPoints,
                in: &context,
                plotRect: plotRect,
                color: Color(.systemGray3),
                opacity: 0.55,
                lineWidth: 5
            )
            drawHorizontalThresholdLine(in: &context, plotRect: plotRect, y: thresholdPoint.y)
            drawTriggerMarker(in: &context, plotRect: plotRect, markerX: markerX)
            drawPoint(in: &context, point: thresholdPoint, color: Color(.systemGray2))
            drawPoint(in: &context, point: todayPoint, color: tint)
        }
        .overlay(alignment: .bottom) {
            axisLabels
        }
    }

    private var axisLabels: some View {
        HStack {
            Text("00:00")

            Spacer()

            Text(triggerTime)

            Spacer()

            Text("00:00")
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 2)
    }

    private func point(_ point: CGPoint, in rect: CGRect) -> CGPoint {
        CGPoint(
            x: rect.minX + rect.width * point.x,
            y: rect.maxY - rect.height * point.y
        )
    }

    private func drawDottedXAxis(in context: inout GraphicsContext, plotRect: CGRect) {
        var dashPath = Path()
        dashPath.move(to: CGPoint(x: plotRect.minX, y: plotRect.maxY))
        dashPath.addLine(to: CGPoint(x: plotRect.maxX, y: plotRect.maxY))

        context.stroke(
            dashPath,
            with: .color(Color(.systemGray3)),
            style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [0.1, 18])
        )
    }

    private func drawPath(
        _ points: [CGPoint],
        in context: inout GraphicsContext,
        plotRect: CGRect,
        color: Color,
        opacity: Double,
        lineWidth: CGFloat
    ) {
        guard let first = points.first else { return }

        var path = Path()
        path.move(to: point(first, in: plotRect))

        for point in points.dropFirst() {
            path.addLine(to: self.point(point, in: plotRect))
        }

        context.stroke(
            path,
            with: .color(color.opacity(opacity)),
            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
        )
    }

    private func drawHorizontalThresholdLine(
        in context: inout GraphicsContext,
        plotRect: CGRect,
        y: CGFloat
    ) {
        var path = Path()
        path.move(to: CGPoint(x: plotRect.minX, y: y))
        path.addLine(to: CGPoint(x: plotRect.maxX, y: y))

        context.stroke(
            path,
            with: .color(Color(.systemGray4)),
            style: StrokeStyle(lineWidth: 2)
        )
    }

    private func drawTriggerMarker(
        in context: inout GraphicsContext,
        plotRect: CGRect,
        markerX: CGFloat
    ) {
        var path = Path()
        path.move(to: CGPoint(x: markerX, y: plotRect.minY + 8))
        path.addLine(to: CGPoint(x: markerX, y: plotRect.maxY))

        context.stroke(
            path,
            with: .color(Color(.systemGray4)),
            style: StrokeStyle(lineWidth: 3, lineCap: .round)
        )
    }

    private func drawPoint(
        in context: inout GraphicsContext,
        point: CGPoint,
        color: Color
    ) {
        let outerRect = CGRect(
            x: point.x - 9,
            y: point.y - 9,
            width: 18,
            height: 18
        )
        let innerRect = CGRect(
            x: point.x - 6,
            y: point.y - 6,
            width: 12,
            height: 12
        )

        context.fill(Path(ellipseIn: outerRect), with: .color(.white))
        context.fill(Path(ellipseIn: innerRect), with: .color(color))
    }
}

// MARK: - Preview

#Preview {
    MissedReflectionHealthCardConcept()
}
