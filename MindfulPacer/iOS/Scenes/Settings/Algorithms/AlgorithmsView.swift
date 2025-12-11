//
//  AlgorithmsView.swift
//  iOS
//
//  Created by Grigor Dochev on 06.04.2025.
//

import SwiftUI

// MARK: - AlgorithmsView

struct AlgorithmsView: View {
    
    // MARK: Properties
    
    @Bindable var viewModel: SettingsViewModel
    @State private var selectedMeasurementType: Reminder.MeasurementType = .heartRate
    
    // MARK: Body
    
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
                        Text("Heart Rate")
                            .tag(Reminder.MeasurementType.heartRate)
                        Text("Steps")
                            .tag(Reminder.MeasurementType.steps)
                    } label: {
                        Text(selectedMeasurementType.localized)
                    }
                    .pickerStyle(.segmented)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            ForEach(
                                selectedMeasurementType == .heartRate ? Reminder.Interval.heartRateIntervals : Reminder.Interval.stepsIntervals,
                                id: \.self
                            ) { interval in
                                Card(backgroundColor: Color(.tertiarySystemGroupedBackground)) {
                                    BufferSliderView(
                                        interval: interval,
                                        type: selectedMeasurementType,
                                        viewModel: viewModel
                                    )
                                }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                } footer: {
                    Button {
                        viewModel.resetBuffersToDefaults()
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

// MARK: - BufferSliderView

private struct BufferSliderView: View {
    let interval: Reminder.Interval
    let type: Reminder.MeasurementType
    @Bindable var viewModel: SettingsViewModel
    
    let defaultBuffer: Double
    let bufferRange: ClosedRange<Double>
    
    init(interval: Reminder.Interval, type: Reminder.MeasurementType, viewModel: SettingsViewModel) {
        self.interval = interval
        self.type = type
        self._viewModel = Bindable(viewModel)
        
        let context: IntervalContext = (type == .heartRate) ? .heartRate : .steps
        let buffer = BufferManager.shared.buffer(for: interval, context: context)
        self.defaultBuffer = buffer
        
        if interval == .oneDay {
            self.bufferRange = 0...(2 * 3600)
        } else {
            self.bufferRange = 0...(buffer * 3)
        }
    }
    
    private var bufferStep: Double {
        return 1.0
    }
    
    private func formattedBuffer(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let remainingSeconds = totalSeconds % 60

        if hours > 0 {
            return "Buffer: \(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "Buffer: \(minutes)m \(remainingSeconds)s"
        } else {
            return "Buffer: \(totalSeconds)s"
        }
    }
    
    var body: some View {
        let key = StorageKeys.bufferKey(for: interval, type: type)
        
        let bufferBinding = Binding<Double>(
            get: { viewModel.bufferValues[key] ?? self.defaultBuffer },
            set: { newValue in viewModel.bufferValues[key] = newValue }
        )
        
        VStack(alignment: .leading, spacing: 16) {
            IconLabel(
                icon: interval.icon,
                title: interval.localized,
                description: formattedBuffer(bufferBinding.wrappedValue)
            )
            .font(.subheadline.weight(.semibold))
            
            Slider(
                value: bufferBinding,
                in: self.bufferRange,
                step: bufferStep
            ) {
            } onEditingChanged: { isEditing in
                if !isEditing {
                    viewModel.saveBuffer(for: interval, type: type, newBufferInSeconds: bufferBinding.wrappedValue)
                }
            }
            .tint(.brandPrimary)
        }
        .frame(minWidth: 256)
    }
}

// MARK: - Preview

#Preview {
    let viewModel: SettingsViewModel = ScenesContainer.shared.settingsViewModel()
    AlgorithmsView(viewModel: viewModel)
}
