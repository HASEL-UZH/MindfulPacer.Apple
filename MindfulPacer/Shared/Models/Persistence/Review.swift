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
typealias Activity = SchemaV1.Activity
typealias Subactivity = SchemaV1.Subactivity
typealias Mood = Review.Mood
typealias Symptom = Review.Symptom

// MARK: - Review

extension SchemaV1 {
    @Model
    final class Review {
        var id: UUID = UUID()
        var date: Date = Date.now
        @Relationship(inverse: \Activity.review) var activity: Activity?
        @Relationship(inverse: \Subactivity.review) var subactivity: Subactivity?
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
        // MARK: Review Reminder Properties
        var measurementType: ReviewReminder.MeasurementType?
        var reviewReminderType: ReviewReminder.ReviewReminderType?
        var threshold: Int?
        var interval: ReviewReminder.Interval?
        
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
            measurementType: ReviewReminder.MeasurementType? = nil,
            reviewReminderType: ReviewReminder.ReviewReminderType? = nil,
            threshold: Int? = nil,
            interval: ReviewReminder.Interval? = nil
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
            self.reviewReminderType = reviewReminderType
            self.threshold = threshold
            self.interval = interval
        }
    }
}

// MARK: - Activity

extension SchemaV1 {
    @Model
    final class Activity {
        var id: UUID = UUID()
        var name: String = ""
        var icon: String = ""
        @Relationship(inverse: \Subactivity.activity) var subactivities: [Subactivity]?
        var review: Review?

        init(
            id: UUID = UUID(),
            name: String = "",
            icon: String = "",
            subactivities: [Subactivity] = [],
            review: Review? = nil
        ) {
            self.id = id
            self.name = name
            self.icon = icon
            self.subactivities = subactivities
            self.review = review
        }
    }
}

// MARK: - Subactivity

extension SchemaV1 {
    @Model
    final class Subactivity {
        var id: UUID = UUID()
        var name: String = ""
        var icon: String = ""
        var activity: Activity?
        var review: Review?

        init(
            id: UUID = UUID(),
            name: String = "",
            icon: String = "",
            activity: Activity? = nil,
            review: Review? = nil
        ) {
            self.id = id
            self.name = name
            self.icon = icon
            self.activity = activity
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

// MARK: - Default Activities

@MainActor
struct DefaultActivityData {
    static var activities: [Activity] = []

    // swiftlint:disable:next function_body_length
    static func initializeData() {
        // MARK: Activities
        let movement = Activity(name: "Movement", icon: "figure.run")
        let transportation = Activity(name: "Transportation", icon: "tram")
        let household = Activity(name: "Household", icon: "house")
        let selfcare = Activity(name: "Selfcare", icon: "shower")
        let cognitive = Activity(name: "Cognitive", icon: "brain")
        let interactionsAndSocial = Activity(name: "Interactions & Social", icon: "rectangle.3.group.bubble")
        let work = Activity(name: "Work", icon: "briefcase")
        let reviewReminders = Activity(name: "Review Reminders", icon: "bell.badge")
        let others = Activity(name: "Others", icon: "ellipsis")

        // MARK: Movement Subactivities
        let standUp = Subactivity(name: "Stand Up", icon: "figure.stand", activity: movement)
        let walking = Subactivity(name: "Walking", icon: "figure.walk", activity: movement)
        let running = Subactivity(name: "Running", icon: "figure.run", activity: movement)
        let walkingTheStairs = Subactivity(name: "Walking the Stairs", icon: "figure.stairs", activity: movement)
        let bikingMovement = Subactivity(name: "Biking", icon: "figure.outdoor.cycle", activity: movement)
        let hiking = Subactivity(name: "Hiking", icon: "figure.hiking", activity: movement)
        let yoga = Subactivity(name: "Yoga", icon: "figure.yoga", activity: movement)
        let stretching = Subactivity(name: "Stretching", icon: "figure.pilates", activity: movement)
        let dancing = Subactivity(name: "Dancing", icon: "figure.dance", activity: movement)
        let swimming = Subactivity(name: "Swimming", icon: "figure.pool.swim", activity: movement)
        let otherMovement = Subactivity(name: "Other Movement", icon: "ellipsis", activity: movement)

        // MARK: Transporation Subactivities
        let drivingCar = Subactivity(name: "Driving Car", icon: "car", activity: transportation)
        let publicTransporation = Subactivity(name: "Public Transporation", icon: "bus", activity: transportation)
        let bikingTransporation = Subactivity(name: "Biking", icon: "bicycle", activity: transportation)
        let flying = Subactivity(name: "Flying", icon: "airplane", activity: transportation)
        let otherTransportation = Subactivity(name: "Other Transportation", icon: "ellipsis", activity: transportation)

        // MARK: Household Subactivities
        let washingClothes = Subactivity(name: "Washing Clothes", icon: "washer", activity: household)
        let washingDishes = Subactivity(name: "Washing Dishes", icon: "dishwasher", activity: household)
        let cleaning = Subactivity(name: "Cleaning", icon: "bubbles.and.sparkles", activity: household)
        let cooking = Subactivity(name: "Cooking", icon: "frying.pan", activity: household)
        let tidyingUp = Subactivity(name: "Tidying Up", icon: "curtains.closed", activity: household)
        let groceryShopping = Subactivity(name: "Grocery Shopping", icon: "basket", activity: household)
        let gardening = Subactivity(name: "Gardening", icon: "sprinkler.and.droplets", activity: household)
        let fixingThings = Subactivity(name: "Fixing Things", icon: "hammer", activity: household)

        // MARK: Selfcare Subactivities
        let personalHygiene = Subactivity(name: "Personal Hygiene", icon: "shower", activity: selfcare)
        let sleep = Subactivity(name: "Sleep", icon: "bed.double", activity: selfcare)
        let gettingDressed = Subactivity(name: "Getting Dress", icon: "tshirt", activity: selfcare)
        let eating = Subactivity(name: "Eating", icon: "fork.knife", activity: selfcare)
        let meditation = Subactivity(name: "Meditation", icon: "apple.meditate", activity: selfcare)
        let visitingDoctorOrTherapist = Subactivity(name: "Visiting Doctor or Therapist", icon: "cross", activity: selfcare)
        let exercising = Subactivity(name: "Exercising", icon: "figure.strengthtraining.traditional", activity: selfcare)
        let relaxation = Subactivity(name: "Relaxation", icon: "beach.umbrella", activity: selfcare)

        // MARK: Cognitive Subactivities
        let thinkingOrBrainstorming = Subactivity(name: "Thinking or Brainstorming", icon: "brain.head.profile", activity: cognitive)
        let reading = Subactivity(name: "Reading", icon: "book", activity: cognitive)
        let writing = Subactivity(name: "Writing", icon: "pencil.line", activity: cognitive)
        let watchingTV = Subactivity(name: "Watching TV", icon: "tv", activity: cognitive)
        let usingComputerTabletPhone = Subactivity(name: "Using Computer, Tablet, Phone", icon: "macbook.and.iphone", activity: cognitive)
        let gaming = Subactivity(name: "Gaming", icon: "gamecontroller", activity: cognitive)
        let readingTheNews = Subactivity(name: "Reading the News", icon: "newspaper", activity: cognitive)
        let playingMusic = Subactivity(name: "Playing Music", icon: "pianokeys", activity: cognitive)
        let learningSomething = Subactivity(name: "Learning Something", icon: "globe.desk", activity: cognitive)

        // MARK: Interactions & Social Subactivities
        let meetingCloseFriends = Subactivity(name: "Meeting Close Friends", icon: "person.3", activity: interactionsAndSocial)
        let meetingNewPeople = Subactivity(name: "Meeting New People", icon: "person.line.dotted.person", activity: interactionsAndSocial)
        let meetingFamily = Subactivity(name: "Meeting Family", icon: "figure.2.and.child.holdinghands", activity: interactionsAndSocial)
        let onlineSocializing = Subactivity(name: "Online Socializing", icon: "bubble.left.and.text.bubble.right", activity: interactionsAndSocial)
        let groupActivities = Subactivity(name: "Group Activities", icon: "person.3.sequence.fill", activity: interactionsAndSocial)
        let attendingEvents = Subactivity(name: "Attending Events", icon: "theatermasks", activity: interactionsAndSocial)

        // MARK: Work Subactivities
        let workOnTasks = Subactivity(name: "Work on Tasks", icon: "desktopcomputer", activity: work)
        let researchingInformation = Subactivity(name: "Researching Information", icon: "rectangle.and.text.magnifyingglass", activity: work)
        let meetings = Subactivity(name: "Meetings", icon: "play.laptopcomputer", activity: work)
        let emailAndChat = Subactivity(name: "Email & Chat", icon: "envelope", activity: work)
        let helpingOthers = Subactivity(name: "Helping Others", icon: "person.2.badge.gearshape", activity: work)
        let networking = Subactivity(name: "Networking", icon: "phone.badge.waveform", activity: work)
        let learning = Subactivity(name: "Learning", icon: "character.book.closed", activity: work)
        let projectManagement = Subactivity(name: "Project Management", icon: "gearshape.2", activity: work)
        let breaks = Subactivity(name: "Breaks", icon: "mug", activity: work)

        // MARK: Review Reminders Subactivities
        let steps = Subactivity(name: "Steps", icon: "figure.walk", activity: reviewReminders)
        let heartRate = Subactivity(name: "Heart Rate", icon: "heart", activity: reviewReminders)

        movement.subactivities = [standUp, walking, running, walkingTheStairs, bikingMovement, hiking, yoga, stretching, dancing, swimming, otherMovement]
        transportation.subactivities = [drivingCar, publicTransporation, bikingTransporation, flying, otherTransportation]
        household.subactivities = [washingClothes, washingDishes, cleaning, cooking, tidyingUp, groceryShopping, gardening, fixingThings]
        selfcare.subactivities = [personalHygiene, sleep, gettingDressed, eating, meditation, visitingDoctorOrTherapist, exercising, relaxation]
        cognitive.subactivities = [thinkingOrBrainstorming, reading, writing, watchingTV, usingComputerTabletPhone, gaming, readingTheNews, playingMusic, learningSomething]
        interactionsAndSocial.subactivities = [meetingCloseFriends, meetingNewPeople, meetingFamily, onlineSocializing, groupActivities, attendingEvents]
        work.subactivities = [workOnTasks, researchingInformation, meetings, emailAndChat, helpingOthers, networking, learning, projectManagement, breaks]
        reviewReminders.subactivities = [steps, heartRate]

        activities = [movement, transportation, household, selfcare, cognitive, interactionsAndSocial, work, reviewReminders, others]
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
