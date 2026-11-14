//
//  SymptomValueView.swift
//  iOS
//
//  Created by Grigor Dochev on 29.10.2024.
//

import SwiftUI

// MARK: - SymptomValueView

extension EditReflectionView {
    struct SymptomValueView: View {
        
        // MARK: Properties

        @Environment(\.dismiss) private var dismiss
        @ScaledMetric(relativeTo: .headline) private var valueBadgeSize: CGFloat = 28
        @Binding var symptom: Symptom
        @State private var isPresentingInfoSheet = false

        // MARK: Body

        var body: some View {
            NavigationStack {
                content
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
                .navigationTitle(symptom.displayName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
                .sheet(isPresented: $isPresentingInfoSheet) {
                    SymptomInfoView(symptom: symptom)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
            }
        }
    }
}

// MARK: - Content

private extension EditReflectionView.SymptomValueView {

    var content: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(0..<symptom.numOptions, id: \.self) { index in
                    symptomButton(index)
                }
                Text("Tap the selected value again to clear it.")
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
        }
    }
}

// MARK: - Toolbar Content

private extension EditReflectionView.SymptomValueView {

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            CloseButton()
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                isPresentingInfoSheet = true
            } label: {
                Label("About This Scale", systemImage: "info.circle")
            }
        }
    }
}

// MARK: - Symptom Button

private extension EditReflectionView.SymptomValueView {

    func symptomButton(_ index: Int) -> some View {
        let isSelected = symptom.value == index
        let tint = symptom.color(for: index)

        return SingleSelectRow(isSelected: isSelected, tint: tint) {
            if isSelected {
                symptom.setValue(nil)
            } else {
                symptom.setValue(index)
            }
            dismiss()
        } content: {
            HStack(spacing: 12) {
                Text("\(index)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Color.primary)
                    .frame(width: valueBadgeSize, height: valueBadgeSize)
                    .background(tint.opacity(0.16), in: .circle)

                Text(symptom.description(for: index))
                    .foregroundStyle(Color.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .contentShape(.rect)
        }
    }
}

// MARK: - Symptom Info View

private struct SymptomInfoView: View {

    @Environment(\.dismiss) private var dismiss

    let symptom: Symptom

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(infoTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
        }
    }
}

private extension SymptomInfoView {

    var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Card {
                    VStack(spacing: 16) {
                        scaleHeader
                        scaleRow
                    }
                }
                explanation
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    var scaleHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(lowEndTitle)
                    .font(.headline)
                Text(lowEndSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(highEndTitle)
                    .font(.headline)
                Text(highEndSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    var scaleRow: some View {
        HStack(spacing: 12) {
            ForEach(0 ..< symptom.numOptions, id: \.self) { index in
                symptomChip(index)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 4)
    }

    func symptomChip(_ index: Int) -> some View {
        let tint = symptom.color(for: index)

        return Text("\(index)")
            .font(.headline)
            .foregroundStyle(Color.primary)
            .frame(width: 44, height: 44)
            .background {
                Circle().foregroundStyle(tint.opacity(0.18))
            }
            .overlay {
                Circle().strokeBorder(tint.opacity(0.6), lineWidth: 2)
            }
    }

    var explanation: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(explanationTitle)
                .font(.title3.weight(.semibold))

            Text(primaryExplanation)
                .foregroundStyle(.secondary)

            Text(secondaryExplanation)
                .foregroundStyle(.secondary)
        }
    }
}

private extension SymptomInfoView {

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                dismiss()
            } label: {
                Label("Close", systemImage: "xmark")
            }
        }
    }
}

private extension SymptomInfoView {

    var infoTitle: String {
        symptom.isWellBeing ? String(localized: "Well-being Scale") : String(localized: "Symptom Scale")
    }

    var lowEndTitle: String {
        symptom.isWellBeing ? String(localized: "Lowest") : String(localized: "Absent")
    }

    var lowEndSubtitle: String {
        symptom.isWellBeing ? String(localized: "Very low") : String(localized: "No symptom")
    }

    var highEndTitle: String {
        symptom.isWellBeing ? String(localized: "Highest") : String(localized: "Severe")
    }

    var highEndSubtitle: String {
        symptom.isWellBeing ? String(localized: "Very high") : String(localized: "Strong symptom")
    }

    var explanationTitle: String {
        symptom.isWellBeing ? String(localized: "How to use well-being") : String(localized: "How to report severity")
    }

    var primaryExplanation: String {
        if symptom.isWellBeing {
            return String(localized: "Use this scale to describe how you felt overall at the time of the reflection.")
        } else {
            return String(localized: "Use this scale to describe how strongly this symptom affected you at the time of the reflection.")
        }
    }

    var secondaryExplanation: String {
        if symptom.isWellBeing {
            return String(localized: "Lower values mean worse well-being, while higher values mean you felt better.")
        } else {
            return String(localized: "Lower values mean the symptom was absent or mild, while higher values mean it was more disruptive.")
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var symptom: Symptom = Symptom.wellBeing(nil)
    let viewModel = ScenesContainer.shared.editReflectionViewModel()
    
    EditReflectionView.SymptomValueView(
        symptom: .constant(symptom)
    )
}
