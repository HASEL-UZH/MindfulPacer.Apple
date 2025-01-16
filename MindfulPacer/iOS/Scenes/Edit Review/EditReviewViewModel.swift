//
//  EditReviewViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 06.08.2024.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - EditReviewViewModel

@MainActor
@Observable
class EditReviewViewModel {
    enum Mode { case create, edit }
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let createReviewUseCase: CreateReviewUseCase
    private let deleteReviewUseCase: DeleteReviewUseCase
    private let fetchDefaultActivitiesUseCase: FetchDefaultActivitiesUseCase
    private let saveReviewUseCase: SaveReviewUseCase
    
    // MARK: - Published Properties (State)
    
    var mode: Mode = .create
    var navigationPath: [EditReviewNavigationDestination] = []
    var activeSheet: EditReviewSheet?
    var activeAlert: EditReviewAlert?
    
    var categories: [Activity] = []
    
    var navigationTitle: String {
        switch mode {
        case .create:
            return "Create Review"
        case .edit:
            return "Edit Review"
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
    
    var isReviewDeleted = false
    
    // MARK: - Initialization
    
    init(
        modelContext: ModelContext,
        createReviewUseCase: CreateReviewUseCase,
        deleteReviewUseCase: DeleteReviewUseCase,
        fetchDefaultActivitiesUseCase: FetchDefaultActivitiesUseCase,
        saveReviewUseCase: SaveReviewUseCase
    ) {
        self.modelContext = modelContext
        self.createReviewUseCase = createReviewUseCase
        self.deleteReviewUseCase = deleteReviewUseCase
        self.fetchDefaultActivitiesUseCase = fetchDefaultActivitiesUseCase
        self.saveReviewUseCase = saveReviewUseCase
    }
    
    // MARK: - View Lifecycle
    
    func onViewFirstAppear() {
        fetchDefaultActivities()
    }
    
    func configureMode(with review: Review?) {
        if let review {
            mode = .edit
            loadReview(review)
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
    
    func createReview() {
        let result = createReviewUseCase.execute(
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
            reviewReminderType: nil,
            threshold: nil,
            interval: nil
        )
        
        print("DEBUGY:", wellBeing)
        
        if case .failure = result {
            presentAlert(.unableToSaveReview)
        }
    }
    
    func saveReview(_ review: Review?) {
        let result = saveReviewUseCase.execute(
            existingReview: review.unsafelyUnwrapped,
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
            presentAlert(.unableToSaveReview)
        }
    }
    
    func deleteReview(_ review: Review?) {
        isReviewDeleted = true
        guard let review else { return }
        deleteReviewUseCase.execute(review: review)
    }
    
    func reviewReminderTriggerSummary(for review: Review) -> String {
        guard let reviewReminderMeasurementType = review.measurementType,
              let reviewReminderInterval = review.interval,
              let reviewReminderThreshold = review.threshold else { return "No summary" }
        
        switch reviewReminderMeasurementType {
        case .heartRate:
            return "Above \(reviewReminderThreshold) bpm for \(reviewReminderInterval.rawValue.lowercased())"
        case .steps:
            return "Above \(reviewReminderThreshold) steps within the window of \(reviewReminderInterval.rawValue.lowercased())"
        }
    }
    
    // MARK: - Presentation
    
    func navigateTo(destination: EditReviewNavigationDestination) {
        navigationPath.append(destination)
    }
    
    func presentSymptomValueSheet(for symptom: Symptom) {
        presentSheet(.symptomValueView(symptom))
    }
    
    func presentSheet(_ sheet: EditReviewSheet) {
        activeSheet = sheet
    }
    
    func dismissSheet(_ sheet: EditReviewSheet) {
        activeSheet = nil
    }
    
    func presentAlert(_ alert: EditReviewAlert) {
        activeAlert = alert
    }
    
    // MARK: - Private Methods
    
    private func fetchDefaultActivities() {
        if let fetchedCategories = fetchDefaultActivitiesUseCase.execute() {
            categories = fetchedCategories
        }
    }
    
    private func loadReview(_ review: Review) {
        date = review.date
        selectedActivity = review.activity
        selectedSubactivity = review.subactivity
        selectedMood = review.mood
        wellBeing.setValue(review.wellBeing)
        fatigue.setValue(review.fatigue)
        shortnessOfBreath.setValue(review.shortnessOfBreath)
        sleepDisorder.setValue(review.sleepDisorder)
        cognitiveImpairment.setValue(review.cognitiveImpairment)
        physicalPain.setValue(review.physicalPain)
        depressionOrAnxiety.setValue(review.depressionOrAnxiety)
        didTriggerCrash = review.didTriggerCrash
        additionalInformation = review.additionalInformation
    }
}
