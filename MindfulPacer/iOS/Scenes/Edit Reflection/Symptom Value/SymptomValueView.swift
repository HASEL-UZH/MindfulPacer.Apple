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
        VStack(spacing: 16) {
            Spacer(minLength: 0)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 64, maximum: 64), spacing: 12, alignment: .center)],
                spacing: 16
            ) {
                ForEach(0 ..< symptom.numOptions, id: \.self) { index in
                    symptomButton(index)
                }
            }
            .padding(.horizontal)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

// MARK: - Toolbar Content

private extension EditReflectionView.SymptomValueView {

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .fontWeight(.semibold)
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                isPresentingInfoSheet = true
            } label: {
                Image(systemName: "info.circle")
                    .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Symptom Button

private extension EditReflectionView.SymptomValueView {

    func symptomButton(_ index: Int) -> some View {
        let isSelected = symptom.value == index
        let tint = symptom.color(for: index)

        return Button {
            if isSelected {
                symptom.setValue(nil)
            } else {
                symptom.setValue(index)
            }
            dismiss()
        } label: {
            VStack(spacing: 10) {
                Text("\(index)")
                    .font(.headline)
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                    .frame(width: 56, height: 56)
                    .background {
                        Circle()
                            .foregroundStyle(tint.opacity(isSelected ? 0.22 : 0.12))
                    }
                    .overlay {
                        Circle().strokeBorder(
                            tint.opacity(isSelected ? 1.0 : 0.35),
                            lineWidth: isSelected ? 3 : 1
                        )
                    }

                Text(symptom.description(for: index))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(width: 64)
        }
        .buttonStyle(.plain)
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
        VStack(alignment: .leading, spacing: 16) {
            scaleHeader
            scaleRow
            Divider().opacity(0.25)
            explanation
            Spacer(minLength: 0)
        }
        .padding()
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
                Image(systemName: "xmark")
                    .fontWeight(.semibold)
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
