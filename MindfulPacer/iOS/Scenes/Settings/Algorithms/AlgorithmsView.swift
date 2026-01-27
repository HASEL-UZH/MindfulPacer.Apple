//
//  AlgorithmsView.swift
//  iOS
//
//  Created by Grigor Dochev on 06.04.2025.
//

import SwiftUI

// MARK: - AlgorithmsView

struct AlgorithmsView: View {

    @Bindable var viewModel: SettingsViewModel
    @State private var selectedMeasurementType: Reminder.MeasurementType = .heartRate
    @State private var resetToken: Int = 0

    var body: some View {
        RoundedList {
            VStack(spacing: 16) {
                IconLabelGroupBox(
                    label: IconLabel(
                        icon: "timer",
                        title: String(localized: "Reminder Buffers"),
                        labelColor: .brandPrimary,
                        background: true
                    ),
                    description: Text("The buffer sets the minimum time between repeated notifications for the same reminder.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                ) {

                    Picker(selection: $selectedMeasurementType) {
                        Text("Heart Rate").tag(Reminder.MeasurementType.heartRate)
                        Text("Steps").tag(Reminder.MeasurementType.steps)
                    } label: {
                        Text(selectedMeasurementType.localized)
                    }
                    .pickerStyle(.segmented)

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            ForEach(
                                selectedMeasurementType == .heartRate
                                ? Reminder.Interval.heartRateIntervals
                                : Reminder.Interval.stepsIntervals,
                                id: \.self
                            ) { interval in
                                Card(backgroundColor: Color(.tertiarySystemGroupedBackground)) {
                                    BufferTextFieldView(
                                        interval: interval,
                                        type: selectedMeasurementType,
                                        viewModel: viewModel,
                                        resetToken: resetToken
                                    )
                                }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)

                } footer: {
                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        viewModel.resetBuffersToDefaults()
                        resetToken &+= 1
                    } label: {
                        IconLabel(
                            icon: "arrow.clockwise",
                            title: String(localized: "Reset to Defaults"),
                            labelColor: .red
                        )
                        .font(.subheadline.weight(.semibold))
                    }
                }
                .iconLabelGroupBoxStyle(.divider)
            }
        }
        .navigationTitle("Algorithms")
    }
}

// MARK: - BufferTextFieldView

private struct BufferTextFieldView: View {
    let interval: Reminder.Interval
    let type: Reminder.MeasurementType
    @Bindable var viewModel: SettingsViewModel
    let resetToken: Int

    @State private var textMinutes: String = ""
    @State private var isOutOfRange: Bool = false
    @FocusState private var isFocused: Bool

    private var context: IntervalContext { type == .heartRate ? .heartRate : .steps }

    private var key: String {
        StorageKeys.bufferKey(for: interval, type: type)
    }

    private var defaultSeconds: TimeInterval {
        BufferManager.shared.defaultBuffer(for: interval, context: context)
    }

    private var allowedRange: ClosedRange<TimeInterval> {
        BufferManager.shared.allowedRange(for: interval, context: context)
    }

    private var currentSeconds: TimeInterval {
        viewModel.bufferValues[key] ?? BufferManager.shared.buffer(for: interval, context: context)
    }

    private func parseMinutesToSeconds(_ text: String) -> TimeInterval? {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard let minutes = Double(normalized), minutes >= 0 else { return nil }
        return minutes * 60.0
    }

    private func secondsToMinutesString(_ seconds: TimeInterval) -> String {
        let minutes = seconds / 60.0
        if minutes.rounded() == minutes {
            return String(Int(minutes))
        } else {
            return String(format: "%.1f", minutes)
        }
    }

    private func formattedTime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60

        if hours > 0 { return "\(hours) h \(minutes) min" }
        if minutes > 0 { return secs > 0 ? "\(minutes) min \(secs) s" : "\(minutes) min" }
        return "\(total) s"
    }

    private func validateCurrentText() {
        guard let candidate = parseMinutesToSeconds(textMinutes) else {
            isOutOfRange = true
            return
        }
        isOutOfRange = !allowedRange.contains(candidate)
    }

    private func commitIfValid() {
        guard let seconds = parseMinutesToSeconds(textMinutes),
              allowedRange.contains(seconds) else {
            isOutOfRange = true
            return
        }

        viewModel.saveBuffer(for: interval, type: type, newBufferInSeconds: seconds)
        viewModel.bufferValues[key] = seconds
        isOutOfRange = false
    }

    private func refreshFromModel() {
        textMinutes = secondsToMinutesString(currentSeconds)
        validateCurrentText()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            IconLabel(
                icon: interval.icon,
                title: interval.localized,
                description: "Default: \(formattedTime(defaultSeconds))"
            )
            .font(.subheadline.weight(.semibold))

            HStack(spacing: 8) {
                TextField("Minutes", text: $textMinutes)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
                    .onChange(of: textMinutes) { _, _ in
                        validateCurrentText()
                    }

                Text("min")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Text("Allowed: \(formattedTime(allowedRange.lowerBound)) – \(formattedTime(allowedRange.upperBound))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if isOutOfRange {
                    Text("Out of range")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                }
            }
        }
        .frame(minWidth: 256)
        .onAppear {
            refreshFromModel()
        }
        .onChange(of: resetToken) { _, _ in
            refreshFromModel()
        }
        .onChange(of: isFocused) { _, focused in
            if !focused { commitIfValid() }
        }
        .onDisappear {
            commitIfValid()
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: SettingsViewModel = ScenesContainer.shared.settingsViewModel()
    AlgorithmsView(viewModel: viewModel)
}
