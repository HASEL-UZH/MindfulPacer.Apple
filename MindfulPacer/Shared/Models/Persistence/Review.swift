//
//  Review.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 08.08.2024.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Typealiases

typealias Review = SchemaV1.Review
typealias Category = SchemaV1.Category
typealias Subcategory = SchemaV1.Subcategory
typealias Mood = Review.Mood
typealias Symptom = Review.Symptom

// MARK: - Review

extension SchemaV1 {
    @Model
    final class Review {
        var id: UUID = UUID()
        var date: Date = Date.now
        @Relationship(inverse: \Category.review) var category: Category?
        @Relationship(inverse: \Subcategory.review) var subcategory: Subcategory?
        var mood: Mood?
        var didTriggerCrash: Bool = false
        var wellBeing: Symptom?
        var fatigue: Symptom?
        var shortnessOfBreath: Symptom?
        var sleepDisorder: Symptom?
        var cognitiveImpairment: Symptom?
        var physicalPain: Symptom?
        var depressionOrAnxiety: Symptom?
        var additionalInformation: String = ""
        // MARK: Review Reminder Properties
        var measurementType: ReviewReminder.MeasurementType?
        var reviewReminderType: ReviewReminder.ReviewReminderType?
        var threshold: Int?
        var interval: ReviewReminder.Interval?
        
        init(
            id: UUID = UUID(),
            date: Date = .now,
            category: Category? = nil,
            subcategory: Subcategory? = nil,
            mood: Mood? = nil,
            didTriggerCrash: Bool = false,
            wellBeing: Symptom?,
            fatigue: Symptom?,
            shortnessOfBreath: Symptom?,
            sleepDisorder: Symptom?,
            cognitiveImpairment: Symptom?,
            physicalPain: Symptom?,
            depressionOrAnxiety: Symptom?,
            additionalInformation: String = "",
            measurementType: ReviewReminder.MeasurementType? = nil,
            reviewReminderType: ReviewReminder.ReviewReminderType? = nil,
            threshold: Int? = nil,
            interval: ReviewReminder.Interval? = nil
        ) {
            self.id = id
            self.date = date
            self.category = category
            self.subcategory = subcategory
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
            self.reviewReminderType = reviewReminderType
            self.threshold = threshold
            self.interval = interval
        }
    }
}

// MARK: - Category

extension SchemaV1 {
    @Model
    final class Category {
        var id: UUID = UUID()
        var name: String = ""
        var icon: String = ""
        @Relationship(inverse: \Subcategory.category) var subcategories: [Subcategory]?
        var review: Review?

        init(
            id: UUID = UUID(),
            name: String = "",
            icon: String = "",
            subcategories: [Subcategory] = [],
            review: Review? = nil
        ) {
            self.id = id
            self.name = name
            self.icon = icon
            self.subcategories = subcategories
            self.review = review
        }
    }
}

// MARK: - Subcategory

extension SchemaV1 {
    @Model
    final class Subcategory {
        var id: UUID = UUID()
        var name: String = ""
        var icon: String = ""
        var category: Category?
        var review: Review?

        init(
            id: UUID = UUID(),
            name: String = "",
            icon: String = "",
            category: Category? = nil,
            review: Review? = nil
        ) {
            self.id = id
            self.name = name
            self.icon = icon
            self.category = category
            self.review = review
        }
    }
}

// MARK: - Mood

extension Review {
    struct Mood: Codable, Equatable {
        let emoji: String
        let text: String
    }
}

// MARK: - Symptom

extension Review {
    enum Symptom: Codable, Equatable {
        case wellBeing(Int?)
        case fatigue(Int?)
        case shortnessOfBreath(Int?)
        case sleepDisorder(Int?)
        case cognitiveImpairment(Int?)
        case physicalPain(Int?)
        case depressionOrAnxiety(Int?)
        
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
                self = newValue == self.value ? .wellBeing(nil) : .wellBeing(newValue)
            case .fatigue:
                self = newValue == self.value ? .fatigue(nil) : .fatigue(newValue)
            case .shortnessOfBreath:
                self = newValue == self.value ? .shortnessOfBreath(nil) : .shortnessOfBreath(newValue)
            case .sleepDisorder:
                self = newValue == self.value ? .sleepDisorder(nil) : .sleepDisorder(newValue)
            case .cognitiveImpairment:
                self = newValue == self.value ? .cognitiveImpairment(nil) : .cognitiveImpairment(newValue)
            case .physicalPain:
                self = newValue == self.value ? .physicalPain(nil) : .physicalPain(newValue)
            case .depressionOrAnxiety:
                self = newValue == self.value ? .depressionOrAnxiety(nil) : .depressionOrAnxiety(newValue)
            }
        }

        var displayName: String {
            switch self {
            case .wellBeing: return "Subjective Well-being"
            case .fatigue: return "Fatigue"
            case .shortnessOfBreath: return "Shortness of Breath"
            case .sleepDisorder: return "Sleep Disorder"
            case .cognitiveImpairment: return "Cognitive Impairment"
            case .physicalPain: return "Physical Pain"
            case .depressionOrAnxiety: return "Depression/Anxiety"
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
            case 0: return "Very Low"
            case 1: return "Low"
            case 2: return "High"
            case 3: return "Very High"
            default: return "Not Set"
            }
        }
        
        private func defaultSeverityDescription(for value: Int?) -> String {
            switch value {
            case 0: return "Absent"
            case 1: return "Mild"
            case 2: return "Moderate"
            case 3: return "Severe"
            default: return "Not Set"
            }
        }
        
        private func wellBeingColor(for value: Int?) -> Color {
            switch value {
            case 0: return .red
            case 1: return .orange
            case 2: return .yellow
            case 3: return .green
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

// MARK: - Default Categories

@MainActor
struct DefaultCategoryData {
    static var categories: [Category] = []

    // swiftlint:disable:next function_body_length
    static func initializeData() {
        // MARK: Categories
        let movement = Category(name: "Movement", icon: "figure.run")
        let transportation = Category(name: "Transportation", icon: "tram")
        let household = Category(name: "Household", icon: "house")
        let selfcare = Category(name: "Selfcare", icon: "shower")
        let cognitive = Category(name: "Cognitive", icon: "brain")
        let interactionsAndSocial = Category(name: "Interactions & Social", icon: "rectangle.3.group.bubble")
        let work = Category(name: "Work", icon: "briefcase")
        let reviewReminders = Category(name: "Review Reminders", icon: "bell.badge")
        let others = Category(name: "Others", icon: "ellipsis")

        // MARK: Movement Subcategories
        let standUp = Subcategory(name: "Stand Up", icon: "figure.stand", category: movement)
        let walking = Subcategory(name: "Walking", icon: "figure.walk", category: movement)
        let running = Subcategory(name: "Running", icon: "figure.run", category: movement)
        let walkingTheStairs = Subcategory(name: "Walking the Stairs", icon: "figure.stairs", category: movement)
        let bikingMovement = Subcategory(name: "Biking", icon: "figure.outdoor.cycle", category: movement)
        let hiking = Subcategory(name: "Hiking", icon: "figure.hiking", category: movement)
        let yoga = Subcategory(name: "Yoga", icon: "figure.yoga", category: movement)
        let stretching = Subcategory(name: "Stretching", icon: "figure.pilates", category: movement)
        let dancing = Subcategory(name: "Dancing", icon: "figure.dance", category: movement)
        let swimming = Subcategory(name: "Swimming", icon: "figure.pool.swim", category: movement)
        let otherMovement = Subcategory(name: "Other Movement", icon: "ellipsis", category: movement)

        // MARK: Transporation Subcategories
        let drivingCar = Subcategory(name: "Driving Car", icon: "car", category: transportation)
        let publicTransporation = Subcategory(name: "Public Transporation", icon: "bus", category: transportation)
        let bikingTransporation = Subcategory(name: "Biking", icon: "bicycle", category: transportation)
        let flying = Subcategory(name: "Flying", icon: "airplane", category: transportation)
        let otherTransportation = Subcategory(name: "Other Transportation", icon: "ellipsis", category: transportation)

        // MARK: Household Subcategories
        let washingClothes = Subcategory(name: "Washing Clothes", icon: "washer", category: household)
        let washingDishes = Subcategory(name: "Washing Dishes", icon: "dishwasher", category: household)
        let cleaning = Subcategory(name: "Cleaning", icon: "bubbles.and.sparkles", category: household)
        let cooking = Subcategory(name: "Cooking", icon: "frying.pan", category: household)
        let tidyingUp = Subcategory(name: "Tidying Up", icon: "curtains.closed", category: household)
        let groceryShopping = Subcategory(name: "Grocery Shopping", icon: "basket", category: household)
        let gardening = Subcategory(name: "Gardening", icon: "sprinkler.and.droplets", category: household)
        let fixingThings = Subcategory(name: "Fixing Things", icon: "hammer", category: household)

        // MARK: Selfcare Subcategories
        let personalHygiene = Subcategory(name: "Personal Hygiene", icon: "shower", category: selfcare)
        let sleep = Subcategory(name: "Sleep", icon: "bed.double", category: selfcare)
        let gettingDressed = Subcategory(name: "Getting Dress", icon: "tshirt", category: selfcare)
        let eating = Subcategory(name: "Eating", icon: "fork.knife", category: selfcare)
        let meditation = Subcategory(name: "Meditation", icon: "apple.meditate", category: selfcare)
        let visitingDoctorOrTherapist = Subcategory(name: "Visiting Doctor or Therapist", icon: "cross", category: selfcare)
        let exercising = Subcategory(name: "Exercising", icon: "figure.strengthtraining.traditional", category: selfcare)
        let relaxation = Subcategory(name: "Relaxation", icon: "beach.umbrella", category: selfcare)

        // MARK: Cognitive Subcategories
        let thinkingOrBrainstorming = Subcategory(name: "Thinking or Brainstorming", icon: "brain.head.profile", category: cognitive)
        let reading = Subcategory(name: "Reading", icon: "book", category: cognitive)
        let writing = Subcategory(name: "Writing", icon: "pencil.line", category: cognitive)
        let watchingTV = Subcategory(name: "Watching TV", icon: "tv", category: cognitive)
        let usingComputerTabletPhone = Subcategory(name: "Using Computer, Tablet, Phone", icon: "macbook.and.iphone", category: cognitive)
        let gaming = Subcategory(name: "Gaming", icon: "gamecontroller", category: cognitive)
        let readingTheNews = Subcategory(name: "Reading the News", icon: "newspaper", category: cognitive)
        let playingMusic = Subcategory(name: "Playing Music", icon: "pianokeys", category: cognitive)
        let learningSomething = Subcategory(name: "Learning Something", icon: "globe.desk", category: cognitive)

        // MARK: Interactions & Social Subategories
        let meetingCloseFriends = Subcategory(name: "Meeting Close Friends", icon: "person.3", category: interactionsAndSocial)
        let meetingNewPeople = Subcategory(name: "Meeting New People", icon: "person.line.dotted.person", category: interactionsAndSocial)
        let meetingFamily = Subcategory(name: "Meeting Family", icon: "figure.2.and.child.holdinghands", category: interactionsAndSocial)
        let onlineSocializing = Subcategory(name: "Online Socializing", icon: "bubble.left.and.text.bubble.right", category: interactionsAndSocial)
        let groupActivities = Subcategory(name: "Group Activities", icon: "person.3.sequence.fill", category: interactionsAndSocial)
        let attendingEvents = Subcategory(name: "Attending Events", icon: "theatermasks", category: interactionsAndSocial)

        // MARK: Work Subcategories
        let workOnTasks = Subcategory(name: "Work on Tasks", icon: "desktopcomputer", category: work)
        let researchingInformation = Subcategory(name: "Researching Information", icon: "rectangle.and.text.magnifyingglass", category: work)
        let meetings = Subcategory(name: "Meetings", icon: "play.laptopcomputer", category: work)
        let emailAndChat = Subcategory(name: "Email & Chat", icon: "envelope", category: work)
        let helpingOthers = Subcategory(name: "Helping Others", icon: "person.2.badge.gearshape", category: work)
        let networking = Subcategory(name: "Networking", icon: "phone.badge.waveform", category: work)
        let learning = Subcategory(name: "Learning", icon: "character.book.closed", category: work)
        let projectManagement = Subcategory(name: "Project Management", icon: "gearshape.2", category: work)
        let breaks = Subcategory(name: "Breaks", icon: "mug", category: work)

        // MARK: Review Reminders Subcategories
        let steps = Subcategory(name: "Steps", icon: "figure.walk", category: reviewReminders)
        let heartRate = Subcategory(name: "Heart Rate", icon: "heart", category: reviewReminders)

        movement.subcategories = [standUp, walking, running, walkingTheStairs, bikingMovement, hiking, yoga, stretching, dancing, swimming, otherMovement]
        transportation.subcategories = [drivingCar, publicTransporation, bikingTransporation, flying, otherTransportation]
        household.subcategories = [washingClothes, washingDishes, cleaning, cooking, tidyingUp, groceryShopping, gardening, fixingThings]
        selfcare.subcategories = [personalHygiene, sleep, gettingDressed, eating, meditation, visitingDoctorOrTherapist, exercising, relaxation]
        cognitive.subcategories = [thinkingOrBrainstorming, reading, writing, watchingTV, usingComputerTabletPhone, gaming, readingTheNews, playingMusic, learningSomething]
        interactionsAndSocial.subcategories = [meetingCloseFriends, meetingNewPeople, meetingFamily, onlineSocializing, groupActivities, attendingEvents]
        work.subcategories = [workOnTasks, researchingInformation, meetings, emailAndChat, helpingOthers, networking, learning, projectManagement, breaks]
        reviewReminders.subcategories = [steps, heartRate]

        categories = [movement, transportation, household, selfcare, cognitive, interactionsAndSocial, work, reviewReminders, others]
    }
}

// MARK: - Default Moods

@MainActor
struct DefaultMoodData {
    static var moods: [Mood] = [
        Mood(emoji: "😊", text: "Happy"),
        Mood(emoji: "😢", text: "Sad"),
        Mood(emoji: "😡", text: "Angry"),
        Mood(emoji: "😍", text: "In love"),
        Mood(emoji: "😨", text: "Scared"),
        Mood(emoji: "😅", text: "Nervous"),
        Mood(emoji: "🤔", text: "Thinking"),
        Mood(emoji: "😴", text: "Tired"),
        Mood(emoji: "😎", text: "Cool/Confident"),
        Mood(emoji: "😭", text: "Crying/Overwhelmed"),
        Mood(emoji: "🤗", text: "Hugging/Supportive"),
        Mood(emoji: "😕", text: "Confused"),
        Mood(emoji: "😏", text: "Smirking"),
        Mood(emoji: "😱", text: "Shocked"),
        Mood(emoji: "🤩", text: "Excited"),
        Mood(emoji: "😒", text: "Unimpressed"),
        Mood(emoji: "😜", text: "Playful/Teasing"),
        Mood(emoji: "😔", text: "Disappointed"),
        Mood(emoji: "🤒", text: "Sick"),
        Mood(emoji: "😤", text: "Frustrated")
    ]
}
