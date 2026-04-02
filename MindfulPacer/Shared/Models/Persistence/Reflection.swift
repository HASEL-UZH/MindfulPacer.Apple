//
//  Reflection.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 08.08.2024.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Typealiases

typealias Reflection = SchemaV1.Reflection
typealias Activity = SchemaV1.Activity
typealias Subactivity = SchemaV1.Subactivity
typealias Mood = Reflection.Mood
typealias Symptom = Reflection.Symptom

// MARK: - Reflection

extension SchemaV1 {
    @Model
    final class Reflection {
        var id: UUID = UUID()
        var date: Date = Date.now
        var activity: Activity?
        var subactivity: Subactivity?
        var mood: Mood?
        var didTriggerCrash: Bool = false
        var wellBeing: Int?
        var fatigue: Int?
        var shortnessOfBreath: Int?
        var sleepDisorder: Int?
        var cognitiveImpairment: Int?
        var physicalPain: Int?
        var depressionOrAnxiety: Int?
        var additionalInformation: String = ""

        var measurementType: Reminder.MeasurementType?
        var reminderType: Reminder.ReminderType?
        var threshold: Int?
        var interval: Reminder.Interval?
        var triggerData: Data?
        var isRejected: Bool = false

        var triggerSamples: [MeasurementSample] {
            get {
                guard let data = triggerData else { return [] }
                do {
                    return try JSONDecoder().decode([MeasurementSample].self, from: data)
                } catch {
                    print("DEBUGY: Error decoding triggerData: \(error)")
                    return []
                }
            }
            set {
                do {
                    triggerData = try JSONEncoder().encode(newValue)
                } catch {
                    print("DEBUGY: Error encoding triggerSamples: \(error)")
                }
            }
        }
        
        var isMissedReflection: Bool {
            activity.isNil && reminderType.isNotNil
        }
        
        var reminderTriggerSummary: String {
            guard let reminderMeasurementType = measurementType,
                  let reminderInterval = interval,
                  let reminderThreshold = threshold else { return "No summary" }
            
            switch reminderMeasurementType {
            case .heartRate:
                return String(localized: "Above \(reminderThreshold) bpm for \(reminderInterval.rawValue.lowercased())")
            case .steps:
                return String(localized: "Above \(reminderThreshold) steps within the window of \(reminderInterval.rawValue.lowercased())")
            }
        }
        
        init(
            id: UUID = UUID(),
            date: Date = .now,
            activity: Activity? = nil,
            subactivity: Subactivity? = nil,
            mood: Mood? = nil,
            didTriggerCrash: Bool = false,
            wellBeing: Int?,
            fatigue: Int?,
            shortnessOfBreath: Int?,
            sleepDisorder: Int?,
            cognitiveImpairment: Int?,
            physicalPain: Int?,
            depressionOrAnxiety: Int?,
            additionalInformation: String = "",
            measurementType: Reminder.MeasurementType? = nil,
            reminderType: Reminder.ReminderType? = nil,
            threshold: Int? = nil,
            interval: Reminder.Interval? = nil,
            triggerSamples: [MeasurementSample] = [],
            isRejected: Bool = false
        ) {
            self.id = id
            self.date = date
            self.activity = activity
            self.subactivity = subactivity
            self.mood = mood
            self.didTriggerCrash = didTriggerCrash
            self.wellBeing = wellBeing
            self.fatigue = fatigue
            self.shortnessOfBreath = shortnessOfBreath
            self.sleepDisorder = sleepDisorder
            self.cognitiveImpairment = cognitiveImpairment
            self.physicalPain = physicalPain
            self.depressionOrAnxiety = depressionOrAnxiety
            self.additionalInformation = additionalInformation
            self.measurementType = measurementType
            self.reminderType = reminderType
            self.threshold = threshold
            self.interval = interval
            self.triggerSamples = triggerSamples
            self.isRejected = isRejected
        }
    }
}

// MARK: - MeasurementSample

struct MeasurementSample: Codable, Hashable {
    let type: Reminder.MeasurementType
    let value: Double
    let date: Date
}

// MARK: - Activity

extension SchemaV1 {
    @Model
    final class Activity {
        var id: UUID = UUID()

        /// Stable identifier for seeded (default) content.
        /// Must be optional or have a default to satisfy iCloud Model Requirements.
        /// Leave empty for user-created activities.
        var seedKey: String = ""

        var name: String = ""
        var icon: String = ""
        @Relationship(inverse: \Subactivity.activity) var subactivities: [Subactivity]?
        @Relationship(inverse: \Reflection.activity) var reflections: [Reflection]? = []

        init(
            id: UUID = UUID(),
            seedKey: String = "",
            name: String = "",
            icon: String = "",
            subactivities: [Subactivity] = [],
            reflections: [Reflection] = []
        ) {
            self.id = id
            self.seedKey = seedKey
            self.name = name
            self.icon = icon
            self.subactivities = subactivities
            self.reflections = reflections
        }
    }
}

// MARK: - Subactivity

extension SchemaV1 {
    @Model
    final class Subactivity {
        var id: UUID = UUID()

        /// Stable identifier for seeded (default) content.
        /// Use namespaced values like "movement.walking".
        /// Leave empty for user-created subactivities.
        var seedKey: String = ""

        var name: String = ""
        var icon: String = ""
        var activity: Activity?
        @Relationship(inverse: \Reflection.subactivity) var reflections: [Reflection]? = []

        init(
            id: UUID = UUID(),
            seedKey: String = "",
            name: String = "",
            icon: String = "",
            activity: Activity? = nil,
            reflections: [Reflection] = []
        ) {
            self.id = id
            self.seedKey = seedKey
            self.name = name
            self.icon = icon
            self.activity = activity
            self.reflections = reflections
        }
    }
}

// MARK: - Mood

extension Reflection {
    struct Mood: Codable, Equatable {
        let emoji: String
        let text: String
    }
}

// MARK: - Symptom

extension Reflection {
    enum Symptom: Codable, Equatable {
        case wellBeing(Int?)
        case fatigue(Int?)
        case shortnessOfBreath(Int?)
        case sleepDisorder(Int?)
        case cognitiveImpairment(Int?)
        case physicalPain(Int?)
        case depressionOrAnxiety(Int?)
        
        var numOptions: Int {
            switch self {
            case .wellBeing: 5
            default: 4
            }
        }
        
        var value: Int? {
            switch self {
            case .wellBeing(let value),
                 .fatigue(let value),
                 .shortnessOfBreath(let value),
                 .sleepDisorder(let value),
                 .cognitiveImpairment(let value),
                 .physicalPain(let value),
                 .depressionOrAnxiety(let value):
                return value
            }
        }
        
        mutating func setValue(_ newValue: Int?) {
            switch self {
            case .wellBeing:
                self = .wellBeing(newValue)
            case .fatigue:
                self = .fatigue(newValue)
            case .shortnessOfBreath:
                self = .shortnessOfBreath(newValue)
            case .sleepDisorder:
                self = .sleepDisorder(newValue)
            case .cognitiveImpairment:
                self = .cognitiveImpairment(newValue)
            case .physicalPain:
                self = .physicalPain(newValue)
            case .depressionOrAnxiety:
                self = .depressionOrAnxiety(newValue)
            }
        }

        var displayName: String {
            switch self {
            case .wellBeing: return String(localized: "Subjective Well-being")
            case .fatigue: return String(localized: "Fatigue")
            case .shortnessOfBreath: return String(localized: "Shortness of Breath")
            case .sleepDisorder: return String(localized: "Sleep Disorder")
            case .cognitiveImpairment: return String(localized: "Cognitive Impairment")
            case .physicalPain: return String(localized: "Physical Pain")
            case .depressionOrAnxiety: return String(localized: "Depression/Anxiety")
            }
        }
        
        var icon: String {
            switch self {
            case .wellBeing: return "cross.fill"
            case .fatigue: return "flame.fill"
            case .shortnessOfBreath: return "wind"
            case .sleepDisorder: return "bed.double.fill"
            case .cognitiveImpairment: return "brain.head.profile"
            case .physicalPain: return "figure.rolling"
            case .depressionOrAnxiety: return "cloud"
            }
        }
        
        var color: Color {
            switch self {
            case .wellBeing:
                return wellBeingColor(for: value)
            default:
                return severityColor(for: value)
            }
        }
        
        var description: String {
            switch self {
            case .wellBeing:
                return wellBeingDescription(for: value)
            default:
                return defaultSeverityDescription(for: value)
            }
        }
        
        var isWellBeing: Bool {
            switch self {
            case .wellBeing:
                true
            default:
                false
            }
        }
        
        var truncationMode: Text.TruncationMode {
            switch self {
            case .cognitiveImpairment: return .tail
            default: return .middle
            }
        }

        func color(for index: Int) -> Color {
            switch self {
            case .wellBeing:
                return wellBeingColor(for: index)
            default:
                return severityColor(for: index)
            }
        }
        
        func description(for index: Int) -> String {
            switch self {
            case .wellBeing:
                return wellBeingDescription(for: index)
            default:
                return defaultSeverityDescription(for: index)
            }
        }
        
        private func wellBeingDescription(for value: Int?) -> String {
            switch value {
            case 0: return String(localized: "Very Low")
            case 1: return String(localized: "Low")
            case 2: return String(localized: "Moderate")
            case 3: return String(localized: "High")
            case 4: return String(localized: "Very High")
            default: return String(localized: "Not Set")
            }
        }
        
        private func defaultSeverityDescription(for value: Int?) -> String {
            switch value {
            case 0: return String(localized: "Absent")
            case 1: return String(localized: "Mild")
            case 2: return String(localized: "Moderate")
            case 3: return String(localized: "Severe")
            default: return String(localized: "Not Set")
            }
        }
        
        private func wellBeingColor(for value: Int?) -> Color {
            switch value {
            case 0: return .red
            case 1: return .orange
            case 2: return .yellow
            case 3: return .green
            case 4: return .green
            default: return .gray
            }
        }
        
        private func severityColor(for value: Int?) -> Color {
            switch value {
            case 0: return .green
            case 1: return .yellow
            case 2: return .orange
            case 3: return .red
            default: return .gray
            }
        }
    }
}

// MARK: - Default Activities

@MainActor
struct DefaultActivityData {
    static var activities: [Activity] = []

    // swiftlint:disable:next function_body_length
    static func initializeData() {
        
        // MARK: Activities
        
        let movement = Activity(name: String(localized: "Movement"), icon: "figure.run")
        let transportation = Activity(name: String(localized: "Transportation"), icon: "tram")
        let household = Activity(name: String(localized: "Household"), icon: "house")
        let selfcare = Activity(name: String(localized: "Selfcare"), icon: "shower")
        let cognitive = Activity(name: String(localized: "Cognitive"), icon: "brain")
        let interactionsAndSocial = Activity(name: String(localized: "Interactions & Social"), icon: "rectangle.3.group.bubble")
        let work = Activity(name: String(localized: "Work"), icon: "briefcase")
        let others = Activity(name: String(localized: "Others"), icon: "ellipsis")

        // MARK: Movement Subactivities
        
        let standUp = Subactivity(name: String(localized: "Stand Up"), icon: "figure.stand", activity: movement)
        let walking = Subactivity(name: String(localized: "Walking"), icon: "figure.walk", activity: movement)
        let running = Subactivity(name: String(localized: "Running"), icon: "figure.run", activity: movement)
        let walkingTheStairs = Subactivity(name: String(localized: "Walking the Stairs"), icon: "figure.stairs", activity: movement)
        let bikingMovement = Subactivity(name: String(localized: "Biking"), icon: "figure.outdoor.cycle", activity: movement)
        let hiking = Subactivity(name: String(localized: "Hiking"), icon: "figure.hiking", activity: movement)
        let yoga = Subactivity(name: String(localized: "Yoga"), icon: "figure.yoga", activity: movement)
        let stretching = Subactivity(name: String(localized: "Stretching"), icon: "figure.pilates", activity: movement)
        let dancing = Subactivity(name: String(localized: "Dancing"), icon: "figure.dance", activity: movement)
        let swimming = Subactivity(name: String(localized: "Swimming"), icon: "figure.pool.swim", activity: movement)
        let otherMovement = Subactivity(name: String(localized: "Other Movement"), icon: "ellipsis", activity: movement)
        let layingDown = Subactivity(name: String(localized: "Laying Down"), icon: "sofa.fill", activity: movement)
        let sitting = Subactivity(name: String(localized: "Sitting"), icon: "chair.fill", activity: movement)
        
        // MARK: Transportation Subactivities
        
        let drivingCar = Subactivity(name: String(localized: "Driving Car"), icon: "car", activity: transportation)
        let publicTransportation = Subactivity(name: String(localized: "Public Transportation"), icon: "bus", activity: transportation)
        let bikingTransportation = Subactivity(name: String(localized: "Biking"), icon: "bicycle", activity: transportation)
        let flying = Subactivity(name: String(localized: "Flying"), icon: "airplane", activity: transportation)
        let otherTransportation = Subactivity(name: String(localized: "Other Transportation"), icon: "ellipsis", activity: transportation)

        // MARK: Household Subactivities
        
        let washingClothes = Subactivity(name: String(localized: "Washing Clothes"), icon: "washer", activity: household)
        let washingDishes = Subactivity(name: String(localized: "Washing Dishes"), icon: "dishwasher", activity: household)
        let cleaning = Subactivity(name: String(localized: "Cleaning"), icon: "bubbles.and.sparkles", activity: household)
        let cooking = Subactivity(name: String(localized: "Cooking"), icon: "frying.pan", activity: household)
        let tidyingUp = Subactivity(name: String(localized: "Tidying Up"), icon: "curtains.closed", activity: household)
        let groceryShopping = Subactivity(name: String(localized: "Grocery Shopping"), icon: "basket", activity: household)
        let gardening = Subactivity(name: String(localized: "Gardening"), icon: "sprinkler.and.droplets", activity: household)
        let fixingThings = Subactivity(name: String(localized: "Fixing Things"), icon: "hammer", activity: household)

        // MARK: Selfcare Subactivities
        
        let personalHygiene = Subactivity(name: String(localized: "Personal Hygiene"), icon: "shower", activity: selfcare)
        let sleep = Subactivity(name: String(localized: "Sleep"), icon: "bed.double", activity: selfcare)
        let gettingDressed = Subactivity(name: String(localized: "Getting Dressed"), icon: "tshirt", activity: selfcare)
        let eating = Subactivity(name: String(localized: "Eating"), icon: "fork.knife", activity: selfcare)
        let meditation = Subactivity(name: String(localized: "Meditation"), icon: "apple.meditate", activity: selfcare)
        let visitingDoctorOrTherapist = Subactivity(name: String(localized: "Visiting Doctor or Therapist"), icon: "cross", activity: selfcare)
        let exercising = Subactivity(name: String(localized: "Exercising"), icon: "figure.strengthtraining.traditional", activity: selfcare)
        let relaxation = Subactivity(name: String(localized: "Relaxation"), icon: "beach.umbrella", activity: selfcare)
        let toilet = Subactivity(name: String(localized: "Toilet"), icon: "toilet", activity: selfcare)

        // MARK: Cognitive Subactivities
        
        let thinkingOrBrainstorming = Subactivity(name: String(localized: "Thinking or Brainstorming"), icon: "brain.head.profile", activity: cognitive)
        let reading = Subactivity(name: String(localized: "Reading"), icon: "book", activity: cognitive)
        let writing = Subactivity(name: String(localized: "Writing"), icon: "pencil.line", activity: cognitive)
        let watchingTV = Subactivity(name: String(localized: "Watching TV"), icon: "tv", activity: cognitive)
        let usingComputerTabletPhone = Subactivity(name: String(localized: "Using Computer, Tablet, Phone"), icon: "macbook.and.iphone", activity: cognitive)
        let gaming = Subactivity(name: String(localized: "Gaming"), icon: "gamecontroller", activity: cognitive)
        let readingTheNews = Subactivity(name: String(localized: "Reading the News"), icon: "newspaper", activity: cognitive)
        let playingMusic = Subactivity(name: String(localized: "Playing Music"), icon: "pianokeys", activity: cognitive)
        let learningSomething = Subactivity(name: String(localized: "Learning Something"), icon: "globe.desk", activity: cognitive)
        let craftWork = Subactivity(name: String(localized: "Craft Work"), icon: "paintbrush.fill", activity: cognitive)
        
        // MARK: Interactions & Social Subactivities
        
        let meetingCloseFriends = Subactivity(name: String(localized: "Meeting Close Friends"), icon: "person.3", activity: interactionsAndSocial)
        let meetingNewPeople = Subactivity(name: String(localized: "Meeting New People"), icon: "person.line.dotted.person", activity: interactionsAndSocial)
        let meetingFamily = Subactivity(name: String(localized: "Meeting Family"), icon: "figure.2.and.child.holdinghands", activity: interactionsAndSocial)
        let onlineSocializing = Subactivity(name: String(localized: "Online Socializing"), icon: "bubble.left.and.text.bubble.right", activity: interactionsAndSocial)
        let groupActivities = Subactivity(name: String(localized: "Group Activities"), icon: "person.3.sequence.fill", activity: interactionsAndSocial)
        let attendingEvents = Subactivity(name: String(localized: "Attending Events"), icon: "theatermasks", activity: interactionsAndSocial)
        let phoneCalls = Subactivity(name: String(localized: "Phone Calls"), icon: "phone.connection.fill", activity: interactionsAndSocial)
        
        // MARK: Work Subactivities
        
        let workOnTasks = Subactivity(name: String(localized: "Work on Tasks"), icon: "desktopcomputer", activity: work)
        let researchingInformation = Subactivity(name: String(localized: "Researching Information"), icon: "rectangle.and.text.magnifyingglass", activity: work)
        let meetings = Subactivity(name: String(localized: "Meetings"), icon: "play.laptopcomputer", activity: work)
        let emailAndChat = Subactivity(name: String(localized: "Email & Chat"), icon: "envelope", activity: work)
        let helpingOthers = Subactivity(name: String(localized: "Helping Others"), icon: "person.2.badge.gearshape", activity: work)
        let networking = Subactivity(name: String(localized: "Networking"), icon: "phone.badge.waveform", activity: work)
        let learning = Subactivity(name: String(localized: "Learning"), icon: "character.book.closed", activity: work)
        let projectManagement = Subactivity(name: String(localized: "Project Management"), icon: "gearshape.2", activity: work)
        let breaks = Subactivity(name: String(localized: "Breaks"), icon: "mug", activity: work)
        
        movement.subactivities = [
            standUp,
            walking,
            running,
            walkingTheStairs,
            bikingMovement,
            hiking,
            yoga,
            stretching,
            dancing,
            swimming,
            otherMovement,
            layingDown,
            sitting
        ]
        
        transportation.subactivities = [
            drivingCar,
            publicTransportation,
            bikingTransportation,
            flying,
            otherTransportation
        ]
        
        household.subactivities = [
            washingClothes,
            washingDishes,
            cleaning,
            cooking,
            tidyingUp,
            groceryShopping,
            gardening,
            fixingThings
        ]
        
        selfcare.subactivities = [
            personalHygiene,
            sleep,
            gettingDressed,
            eating,
            meditation,
            visitingDoctorOrTherapist,
            exercising,
            relaxation,
            toilet
        ]
        
        cognitive.subactivities = [
            thinkingOrBrainstorming,
            reading,
            writing,
            watchingTV,
            usingComputerTabletPhone,
            gaming,
            readingTheNews,
            playingMusic,
            learningSomething,
            craftWork
        ]
        
        interactionsAndSocial.subactivities = [
            meetingCloseFriends,
            meetingNewPeople,
            meetingFamily,
            onlineSocializing,
            groupActivities,
            attendingEvents,
            phoneCalls
        ]
        
        work.subactivities = [
            workOnTasks,
            researchingInformation,
            meetings,
            emailAndChat,
            helpingOthers,
            networking,
            learning,
            projectManagement,
            breaks
        ]

        activities = [
            movement,
            transportation,
            household,
            selfcare,
            cognitive,
            interactionsAndSocial,
            work,
            others
        ]
    }
    
    static var allActivities: [Activity] {
        if DefaultActivityData.activities.isEmpty {
            DefaultActivityData.initializeData()
        }
        return DefaultActivityData.activities
    }
}

// MARK: - Default Moods

@MainActor
struct DefaultMoodData {
    static var moods: [Mood] = [
        Mood(emoji: "😊", text: String(localized: "Happy")),
        Mood(emoji: "😢", text: String(localized: "Sad")),
        Mood(emoji: "😡", text: String(localized: "Angry")),
        Mood(emoji: "😍", text: String(localized: "In love")),
        Mood(emoji: "😨", text: String(localized: "Scared")),
        Mood(emoji: "😅", text: String(localized: "Nervous")),
        Mood(emoji: "🤔", text: String(localized: "Thinking")),
        Mood(emoji: "😴", text: String(localized: "Tired")),
        Mood(emoji: "😎", text: String(localized: "Cool/Confident")),
        Mood(emoji: "😭", text: String(localized: "Crying/Overwhelmed")),
        Mood(emoji: "🤗", text: String(localized: "Hugging/Supportive")),
        Mood(emoji: "😕", text: String(localized: "Confused")),
        Mood(emoji: "😏", text: String(localized: "Smirking")),
        Mood(emoji: "😱", text: String(localized: "Shocked")),
        Mood(emoji: "🤩", text: String(localized: "Excited")),
        Mood(emoji: "😒", text: String(localized: "Unimpressed")),
        Mood(emoji: "😜", text: String(localized: "Playful/Teasing")),
        Mood(emoji: "😔", text: String(localized: "Disappointed")),
        Mood(emoji: "🤒", text: String(localized: "Sick")),
        Mood(emoji: "😤", text: String(localized: "Frustrated"))
    ]
}
