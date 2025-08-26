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
    private let createReflectionUseCase: CreateReflectionUseCase
    private let deleteReflectionUseCase: DeleteReflectionUseCase
    private let fetchDefaultActivitiesUseCase: FetchDefaultActivitiesUseCase
    private let saveReflectionUseCase: SaveReflectionUseCase
    
    // MARK: - Published Properties (State)
    
    var mode: Mode = .create
    var navigationPath: [EditReflectionNavigationDestination] = []
    var activeSheet: EditReflectionSheet?
    var activeAlert: EditReflectionAlert?
    var selectedReminderContext: ReminderContext = .reminder
    
    var activities: [Activity] = []
    
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
    
    init(
        modelContext: ModelContext,
        createReflectionUseCase: CreateReflectionUseCase,
        deleteReflectionUseCase: DeleteReflectionUseCase,
        fetchDefaultActivitiesUseCase: FetchDefaultActivitiesUseCase,
        saveReflectionUseCase: SaveReflectionUseCase
    ) {
        self.modelContext = modelContext
        self.createReflectionUseCase = createReflectionUseCase
        self.deleteReflectionUseCase = deleteReflectionUseCase
        self.fetchDefaultActivitiesUseCase = fetchDefaultActivitiesUseCase
        self.saveReflectionUseCase = saveReflectionUseCase
    }
    
    // MARK: - View Lifecycle
    
    func onViewFirstAppear() {
        fetchDefaultActivities()
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
        let result = createReflectionUseCase.execute(
            date: date,
            activity: selectedActivity,
            subactivity: selectedSubactivity,
            mood: selectedMood,
            didTriggerCrash: didTriggerCrash,
            wellBeing: wellBeing,
            fatigue: fatigue,
            shortnessOfBreath: shortnessOfBreath,
            sleepDisorder: sleepDisorder,
            cognitiveImpairment: cognitiveImpairment,
            physicalPain: physicalPain,
            depressionOrAnxiety: depressionOrAnxiety,
            additionalInformation: additionalInformation,
            measurementType: nil,
            reminderType: nil,
            threshold: nil,
            interval: nil,
            triggerSamples: []
        )
        
        print("DEBUGY:", wellBeing)
        
        if case .failure = result {
            presentAlert(.unableToSaveReflection)
        }
    }
    
    func saveReflection(_ reflection: Reflection?) {
        let result = saveReflectionUseCase.execute(
            existingReflection: reflection.unsafelyUnwrapped,
            newDate: date,
            newActivity: selectedActivity,
            newSubactivity: selectedSubactivity,
            newMood: selectedMood,
            newDidTriggerCrash: didTriggerCrash,
            newWellBeing: wellBeing,
            newFatigue: fatigue,
            newShortnessOfBreath: shortnessOfBreath,
            newSleepDisorder: sleepDisorder,
            newCognitiveImpairment: cognitiveImpairment,
            newPhysicalPain: physicalPain,
            newDepressionOrAnxiety: depressionOrAnxiety,
            newAdditionalInformation: additionalInformation
        )
        
        if case .failure = result {
            presentAlert(.unableToSaveReflection)
        }
    }
    
    func deleteReflection(_ reflection: Reflection?) {
        isReflectionDeleted = true
        guard let reflection else { return }
        deleteReflectionUseCase.execute(reflection: reflection)
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
    
    private func fetchDefaultActivities() {
        if let fetchedActivities = fetchDefaultActivitiesUseCase.execute() {
            activities = fetchedActivities
        }
    }
    
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
