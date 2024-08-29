//
//  Review.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 08.08.2024.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Review

typealias Review = SchemaV1.Review
typealias Category = SchemaV1.Category
typealias Subcategory = SchemaV1.Subcategory
typealias Mood = SchemaV1.Review.Mood

extension SchemaV1 {
    @Model
    final class Review {
        var id: UUID = UUID()
        var date: Date = Date.now
        var category: Category?
        var subcategory: Subcategory?
        var mood: String? = ""
        var didTriggerCrash: Bool?
        var perceivedEnergyLevelRating: Int?
        var headachesRating: Int?
        var shortnessOfBreatheRating: Int?
        var feverRating: Int?
        var painsAndNeedlesRating: Int?
        var muscleAchesRating: Int?
        var additionalInformation: String?
        
        init(
            id: UUID = UUID(),
            date: Date = .now,
            category: Category? = nil,
            subcategory: Subcategory? = nil,
            mood: String? = "",
            didTriggerCrash: Bool? = false,
            perceivedEnergyLevelRating: Int? = 0,
            headachesRating: Int? = 0,
            shortnessOfBreatheRating: Int? = 0,
            feverRating: Int? = 0,
            painsAndNeedlesRating: Int? = 0,
            muscleAchesRating: Int? = 0,
            additionalInformation: String? = ""
        ) {
            self.id = id
            self.date = date
            self.category = category
            self.subcategory = subcategory
            self.mood = mood
            self.didTriggerCrash = didTriggerCrash
            self.perceivedEnergyLevelRating = perceivedEnergyLevelRating
            self.headachesRating = headachesRating
            self.shortnessOfBreatheRating = shortnessOfBreatheRating
            self.feverRating = feverRating
            self.painsAndNeedlesRating = painsAndNeedlesRating
            self.muscleAchesRating = muscleAchesRating
            self.additionalInformation = additionalInformation
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

// MARK: - Default Categories

@MainActor
struct DefaultCategoryData {
    static var categories: [Category] = []
    
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
        let meditation = Subcategory(name: "Meditation", icon: "apple.meditate", category: selfcare) // FIXME: Might not be able to use this symbol (refers to Apple's meditation in fitness app)
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

extension Review {
    struct Mood: Equatable {
        let id = UUID()
        let emoji: String
        let description: String
    }
}

@MainActor
struct DefaultMoodData {
    static var moods: [Mood] = [
        Mood(emoji: "😊", description: "Happy"),
        Mood(emoji: "😢", description: "Sad"),
        Mood(emoji: "😡", description: "Angry"),
        Mood(emoji: "😍", description: "In love"),
        Mood(emoji: "😨", description: "Scared"),
        Mood(emoji: "😅", description: "Nervous"),
        Mood(emoji: "🤔", description: "Thinking"),
        Mood(emoji: "😴", description: "Tired"),
        Mood(emoji: "😎", description: "Cool/Confident"),
        Mood(emoji: "😭", description: "Crying/Overwhelmed"),
        Mood(emoji: "🤗", description: "Hugging/Supportive"),
        Mood(emoji: "😕", description: "Confused"),
        Mood(emoji: "😏", description: "Smirking"),
        Mood(emoji: "😱", description: "Shocked"),
        Mood(emoji: "🤩", description: "Excited"),
        Mood(emoji: "😒", description: "Unimpressed"),
        Mood(emoji: "😜", description: "Playful/Teasing"),
        Mood(emoji: "😔", description: "Disappointed"),
        Mood(emoji: "🤒", description: "Sick"),
        Mood(emoji: "😤", description: "Frustrated")
    ]
}
