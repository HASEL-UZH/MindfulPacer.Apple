//
//  EditReflectionViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 06.08.2024.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - ReminderContext

enum ReminderContext: String {
    case reminder
    case chart
}

// MARK: - EditReflectionViewModel

@MainActor
@Observable
class EditReflectionViewModel {
    enum Mode { case create, edit }
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    
    // MARK: - Published Properties (State)
    
    var mode: Mode = .create
    var navigationPath: [EditReflectionNavigationDestination] = []
    var activeSheet: EditReflectionSheet?
    var activeAlert: EditReflectionAlert?
    var selectedReminderContext: ReminderContext = .reminder
    
    var navigationTitle: String {
        switch mode {
        case .create:
            return String(localized: "Create Reflection")
        case .edit:
            return String(localized: "Edit Reflection")
        }
    }
    
    var date: Date = .now
    var selectedActivity: Activity? {
        didSet {
            selectedSubactivity = nil
        }
    }
    var selectedMood: Mood?
    var selectedSubactivity: Subactivity?
    
    var wellBeing = Symptom.wellBeing(nil)
    var fatigue = Symptom.fatigue(nil)
    var shortnessOfBreath = Symptom.shortnessOfBreath(nil)
    var sleepDisorder = Symptom.sleepDisorder(nil)
    var cognitiveImpairment = Symptom.cognitiveImpairment(nil)
    var physicalPain = Symptom.physicalPain(nil)
    var depressionOrAnxiety = Symptom.depressionOrAnxiety(nil)
    var didTriggerCrash: Bool = false
    var additionalInformation: String = ""
    
    var wellBeingBinding: Binding<Symptom> {
        Binding(
            get: { self.wellBeing },
            set: { newValue in
                if self.wellBeing == newValue {
                    self.wellBeing.setValue(nil)
                } else {
                    self.wellBeing.setValue(newValue.value)
                }
            }
        )
    }
    
    var fatigueBinding: Binding<Symptom> {
        Binding(
            get: { self.fatigue },
            set: { newValue in
                if self.fatigue == newValue {
                    self.fatigue.setValue(nil)
                } else {
                    self.fatigue.setValue(newValue.value)
                }
            }
        )
    }
    
    var shortnessOfBreathBinding: Binding<Symptom> {
        Binding(
            get: { self.shortnessOfBreath },
            set: { newValue in
                if self.shortnessOfBreath == newValue {
                    self.shortnessOfBreath.setValue(nil)
                } else {
                    self.shortnessOfBreath.setValue(newValue.value)
                }
            }
        )
    }
    
    var sleepDisorderBinding: Binding<Symptom> {
        Binding(
            get: { self.sleepDisorder },
            set: { newValue in
                if self.sleepDisorder == newValue {
                    self.sleepDisorder.setValue(nil)
                } else {
                    self.sleepDisorder.setValue(newValue.value)
                }
            }
        )
    }
    var cognitiveImpairmentBinding: Binding<Symptom> {
        Binding(
            get: { self.cognitiveImpairment },
            set: { newValue in
                if self.cognitiveImpairment == newValue {
                    self.cognitiveImpairment.setValue(nil)
                } else {
                    self.cognitiveImpairment.setValue(newValue.value)
                }
            }
        )
    }
    
    var physicalPainBinding: Binding<Symptom> {
        Binding(
            get: { self.physicalPain },
            set: { newValue in
                if self.physicalPain == newValue {
                    self.physicalPain.setValue(nil)
                } else {
                    self.physicalPain.setValue(newValue.value)
                }
            }
        )
    }
    
    var depressionOrAnxietyBinding: Binding<Symptom> {
        Binding(
            get: { self.depressionOrAnxiety },
            set: { newValue in
                if self.depressionOrAnxiety == newValue {
                    self.depressionOrAnxiety.setValue(nil)
                } else {
                    self.depressionOrAnxiety.setValue(newValue.value)
                }
            }
        )
    }
    
    var isActionButtonDisabled: Bool {
        let disabled = selectedActivity == nil
        return disabled
    }
    
    var isSaveButtonDisabled: Bool {
        let disabled = selectedActivity == nil
        return disabled
    }
    
    var isReflectionDeleted = false
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - View Lifecycle
    
    func onViewFirstAppear() {
    }
    
    func configureMode(with reflection: Reflection?) {
        if let reflection {
            mode = .edit
            loadReflection(reflection)
        }
    }
    
    // MARK: - User Actions
    
    func toggleSelection<T: Equatable>(_ item: T, selectedItem: inout T?) {
        if selectedItem == item {
            selectedItem = nil
        } else {
            selectedItem = item
            if !ProcessInfo.processInfo.isRunningInPreviewOrTest {
                navigationPath.removeLast()
            }
        }
    }
    
    func createReflection() {
        let reflection = Reflection(
            date: date,
            activity: selectedActivity,
            subactivity: selectedSubactivity,
            mood: selectedMood,
            didTriggerCrash: didTriggerCrash,
            wellBeing: wellBeing.value,
            fatigue: fatigue.value,
            shortnessOfBreath: shortnessOfBreath.value,
            sleepDisorder: sleepDisorder.value,
            cognitiveImpairment: cognitiveImpairment.value,
            physicalPain: physicalPain.value,
            depressionOrAnxiety: depressionOrAnxiety.value,
            additionalInformation: additionalInformation,
            measurementType: nil,
            reminderType: nil,
            threshold: nil,
            interval: nil,
            triggerSamples: [],
            isRejected: false
        )
        
        modelContext.insert(reflection)
        
        do {
            try modelContext.save()
            BackgroundReflectionsStore.shared.upsert(.init(from: reflection))
        } catch {
            presentAlert(.unableToSaveReflection)
        }
    }
    
    func saveReflection(_ reflection: Reflection?) {
        guard let reflection else { return }
        
        reflection.date = date
        reflection.activity = selectedActivity
        reflection.subactivity = selectedSubactivity
        reflection.mood = selectedMood
        reflection.didTriggerCrash = didTriggerCrash
        reflection.wellBeing = wellBeing.value
        reflection.fatigue = fatigue.value
        reflection.shortnessOfBreath = shortnessOfBreath.value
        reflection.sleepDisorder = sleepDisorder.value
        reflection.cognitiveImpairment = cognitiveImpairment.value
        reflection.physicalPain = physicalPain.value
        reflection.depressionOrAnxiety = depressionOrAnxiety.value
        reflection.additionalInformation = additionalInformation
        
        do {
            try modelContext.save()
            BackgroundReflectionsStore.shared.upsert(.init(from: reflection))
        } catch {
            presentAlert(.unableToSaveReflection)
        }
    }
    
    func deleteReflection(_ reflection: Reflection?) {
        isReflectionDeleted = true
        guard let reflection else { return }
        
        modelContext.delete(reflection)
        try? modelContext.save()
        
        BackgroundReflectionsStore.shared.remove(id: reflection.id)
    }
    
    // MARK: - Presentation
    
    func navigateTo(destination: EditReflectionNavigationDestination) {
        navigationPath.append(destination)
    }
    
    func presentSymptomValueSheet(for symptom: Symptom) {
        presentSheet(.symptomValueView(symptom))
    }
    
    func presentSheet(_ sheet: EditReflectionSheet) {
        activeSheet = sheet
    }
    
    func dismissSheet(_ sheet: EditReflectionSheet) {
        activeSheet = nil
    }
    
    func presentAlert(_ alert: EditReflectionAlert) {
        activeAlert = alert
    }
    
    // MARK: - Private Methods
    
    private func loadReflection(_ reflection: Reflection) {
        date = reflection.date
        selectedActivity = reflection.activity
        selectedSubactivity = reflection.subactivity
        selectedMood = reflection.mood
        wellBeing.setValue(reflection.wellBeing)
        fatigue.setValue(reflection.fatigue)
        shortnessOfBreath.setValue(reflection.shortnessOfBreath)
        sleepDisorder.setValue(reflection.sleepDisorder)
        cognitiveImpairment.setValue(reflection.cognitiveImpairment)
        physicalPain.setValue(reflection.physicalPain)
        depressionOrAnxiety.setValue(reflection.depressionOrAnxiety)
        didTriggerCrash = reflection.didTriggerCrash
        additionalInformation = reflection.additionalInformation
    }
}
