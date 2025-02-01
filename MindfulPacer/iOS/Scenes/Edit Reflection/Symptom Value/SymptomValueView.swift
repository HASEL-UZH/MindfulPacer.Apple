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

        @Binding var symptom: Symptom

        // MARK: Body

        var body: some View {
            NavigationStack {
                VStack {
                    VStack(alignment: .leading, spacing: 16) {
                        if !symptom.isWellBeing { // TODO: Need message for wellBeing
                            InfoBox(text: "Report severity of symptom.")
                        }

                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                ForEach(0 ..< 4, id: \.self) { index in
                                    VStack(spacing: 12) {
                                        SelectableButton(
                                            shape: .circle,
                                            backgroundColor: symptom.color(for: index).opacity(0.1),
                                            selectionColor: Color("BrandPrimary"),
                                            isSelected: symptom.value == index
                                        ) {
                                            symptom.setValue(index)
                                        } label: {
                                            Text("\(index)")
                                                .fontWeight(.semibold)
                                                .foregroundStyle(symptom.value == index ? Color("BrandPrimary") : symptom.color(for: index))
                                        }
                                        .buttonStyle(.plain)

                                        Text(symptom.description(for: index))
                                            .font(.footnote.weight(.semibold))
                                            .foregroundStyle(symptom.value == index ? Color("BrandPrimary") : symptom.color(for: index))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
                .navigationTitle(symptom.displayName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        CloseButton()
                    }
                }
            }
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
