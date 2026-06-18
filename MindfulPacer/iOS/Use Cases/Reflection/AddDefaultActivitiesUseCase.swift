//
//  AddDefaultActivitiesUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 05.07.2024.
//

import Foundation
import SwiftData
import SwiftUI

protocol AddDefaultActivitiesUseCase: Sendable {
    func execute() async
}

// MARK: - Use Case Implementation

@MainActor
final class DefaultAddDefaultActivitiesUseCase: AddDefaultActivitiesUseCase {
    private let context: ModelContext

    init(modelContext: ModelContext) {
        self.context = modelContext
    }

    // MARK: - Public

    func execute() async {
        // 1) Upsert all default activities/subactivities by seedKey
        upsertDefaults()

        // 2) Reconcile duplicates (possible after CloudKit merges)
        try? reconcileDuplicateDefaults()

        // 3) Persist
        try? context.save()
    }

    // MARK: - Seed Catalog

    private struct SeedActivity {
        let key: String
        let name: String
        let icon: String
    }

    private struct SeedSubactivity {
        let key: String
        let parentKey: String
        let name: String
        let icon: String
    }

    // Activities
    private let activityCatalog: [SeedActivity] = [
        .init(key: "movement", name: String(localized: "Movement"), icon: "figure.run"),
        .init(key: "transportation", name: String(localized: "Transportation"), icon: "tram"),
        .init(key: "household", name: String(localized: "Household"), icon: "house"),
        .init(key: "selfcare", name: String(localized: "Selfcare"), icon: "shower"),
        .init(key: "cognitive", name: String(localized: "Cognitive"), icon: "brain"),
        .init(key: "social", name: String(localized: "Interactions & Social"), icon: "rectangle.3.group.bubble"),
        .init(key: "work", name: String(localized: "Work"), icon: "briefcase"),
        .init(key: "others", name: String(localized: "Others"), icon: "ellipsis")
    ]

    // Subactivities
    private let subactivityCatalog: [SeedSubactivity] = [
        // Movement
        .init(key: "movement.standUp", parentKey: "movement", name: String(localized: "Stand Up"), icon: "figure.stand"),
        .init(key: "movement.walking", parentKey: "movement", name: String(localized: "Walking"), icon: "figure.walk"),
        .init(key: "movement.running", parentKey: "movement", name: String(localized: "Running"), icon: "figure.run"),
        .init(key: "movement.stairs", parentKey: "movement", name: String(localized: "Walking the Stairs"), icon: "figure.stairs"),
        .init(key: "movement.biking", parentKey: "movement", name: String(localized: "Biking"), icon: "figure.outdoor.cycle"),
        .init(key: "movement.hiking", parentKey: "movement", name: String(localized: "Hiking"), icon: "figure.hiking"),
        .init(key: "movement.yoga", parentKey: "movement", name: String(localized: "Yoga"), icon: "figure.yoga"),
        .init(key: "movement.stretching", parentKey: "movement", name: String(localized: "Stretching"), icon: "figure.pilates"),
        .init(key: "movement.dancing", parentKey: "movement", name: String(localized: "Dancing"), icon: "figure.dance"),
        .init(key: "movement.swimming", parentKey: "movement", name: String(localized: "Swimming"), icon: "figure.pool.swim"),
        .init(key: "movement.other", parentKey: "movement", name: String(localized: "Other Movement"), icon: "ellipsis"),
        .init(key: "movement.layingDown", parentKey: "movement", name: String(localized: "Laying Down"), icon: "sofa.fill"),
        .init(key: "movement.sitting", parentKey: "movement",name: String(localized: "Sitting"), icon: "chair.fill"),
        
        // Transportation
        .init(key: "transportation.driving", parentKey: "transportation", name: String(localized: "Driving Car"), icon: "car"),
        .init(key: "transportation.public", parentKey: "transportation", name: String(localized: "Public Transportation"), icon: "bus"),
        .init(key: "transportation.biking", parentKey: "transportation", name: String(localized: "Biking"), icon: "bicycle"),
        .init(key: "transportation.flying", parentKey: "transportation", name: String(localized: "Flying"), icon: "airplane"),
        .init(key: "transportation.other", parentKey: "transportation", name: String(localized: "Other Transportation"), icon: "ellipsis"),

        // Household
        .init(key: "household.washingClothes", parentKey: "household", name: String(localized: "Washing Clothes"), icon: "washer"),
        .init(key: "household.washingDishes", parentKey: "household", name: String(localized: "Washing Dishes"), icon: "dishwasher"),
        .init(key: "household.cleaning", parentKey: "household", name: String(localized: "Cleaning"), icon: "bubbles.and.sparkles"),
        .init(key: "household.cooking", parentKey: "household", name: String(localized: "Cooking"), icon: "frying.pan"),
        .init(key: "household.tidyingUp", parentKey: "household", name: String(localized: "Tidying Up"), icon: "curtains.closed"),
        .init(key: "household.groceryShopping", parentKey: "household", name: String(localized: "Grocery Shopping"), icon: "basket"),
        .init(key: "household.gardening", parentKey: "household", name: String(localized: "Gardening"), icon: "sprinkler.and.droplets"),
        .init(key: "household.fixingThings", parentKey: "household", name: String(localized: "Fixing Things"), icon: "hammer"),

        // Selfcare
        .init(key: "selfcare.hygiene", parentKey: "selfcare", name: String(localized: "Personal Hygiene"), icon: "shower"),
        .init(key: "selfcare.sleep", parentKey: "selfcare", name: String(localized: "Sleep"), icon: "bed.double"),
        .init(key: "selfcare.gettingDressed", parentKey: "selfcare", name: String(localized: "Getting Dressed"), icon: "tshirt"),
        .init(key: "selfcare.eating", parentKey: "selfcare", name: String(localized: "Eating"), icon: "fork.knife"),
        .init(key: "selfcare.meditation", parentKey: "selfcare", name: String(localized: "Meditation"), icon: "apple.meditate"),
        .init(key: "selfcare.visitingDoctor", parentKey: "selfcare", name: String(localized: "Visiting Doctor or Therapist"), icon: "cross"),
        .init(key: "selfcare.exercising", parentKey: "selfcare", name: String(localized: "Exercising"), icon: "figure.strengthtraining.traditional"),
        .init(key: "selfcare.relaxation", parentKey: "selfcare", name: String(localized: "Relaxation"), icon: "beach.umbrella"),
        .init(key: "selfcare.toilet", parentKey: "selfcare", name: String(localized: "Toilet"), icon: "toilet"),

        // Cognitive
        .init(key: "cognitive.brainstorming", parentKey: "cognitive", name: String(localized: "Thinking or Brainstorming"), icon: "brain.head.profile"),
        .init(key: "cognitive.reading", parentKey: "cognitive", name: String(localized: "Reading"), icon: "book"),
        .init(key: "cognitive.writing", parentKey: "cognitive", name: String(localized: "Writing"), icon: "pencil.line"),
        .init(key: "cognitive.watchingTV", parentKey: "cognitive", name: String(localized: "Watching TV"), icon: "tv"),
        .init(key: "cognitive.usingDevices", parentKey: "cognitive", name: String(localized: "Using Computer, Tablet, Phone"), icon: "macbook.and.iphone"),
        .init(key: "cognitive.gaming", parentKey: "cognitive", name: String(localized: "Gaming"), icon: "gamecontroller"),
        .init(key: "cognitive.news", parentKey: "cognitive", name: String(localized: "Reading the News"), icon: "newspaper"),
        .init(key: "cognitive.playingMusic", parentKey: "cognitive", name: String(localized: "Playing Music"), icon: "pianokeys"),
        .init(key: "cognitive.learning", parentKey: "cognitive", name: String(localized: "Learning Something"), icon: "globe.desk"),
        .init(key: "cognitive.craftWork", parentKey: "cognitive", name: String(localized: "Craft Work"), icon: "paintbrush.fill"),
        
        // Interactions & Social
        .init(key: "social.closeFriends", parentKey: "social", name: String(localized: "Meeting Close Friends"), icon: "person.3"),
        .init(key: "social.newPeople", parentKey: "social", name: String(localized: "Meeting New People"), icon: "person.line.dotted.person"),
        .init(key: "social.family", parentKey: "social", name: String(localized: "Meeting Family"), icon: "figure.2.and.child.holdinghands"),
        .init(key: "social.online", parentKey: "social", name: String(localized: "Online Socializing"), icon: "bubble.left.and.text.bubble.right"),
        .init(key: "social.groupActivities", parentKey: "social", name: String(localized: "Group Activities"), icon: "person.3.sequence.fill"),
        .init(key: "social.events", parentKey: "social", name: String(localized: "Attending Events"), icon: "theatermasks"),
        .init(key: "social.phoneCalls", parentKey: "social", name: String(localized: "Phone Calls"), icon: "phone.connection.fill"),
        
        // Work
        .init(key: "work.tasks", parentKey: "work", name: String(localized: "Work on Tasks"), icon: "desktopcomputer"),
        .init(key: "work.research", parentKey: "work", name: String(localized: "Researching Information"), icon: "rectangle.and.text.magnifyingglass"),
        .init(key: "work.meetings", parentKey: "work", name: String(localized: "Meetings"), icon: "play.laptopcomputer"),
        .init(key: "work.emailChat", parentKey: "work", name: String(localized: "Email & Chat"), icon: "envelope"),
        .init(key: "work.helpingOthers", parentKey: "work", name: String(localized: "Helping Others"), icon: "person.2.badge.gearshape"),
        .init(key: "work.networking", parentKey: "work", name: String(localized: "Networking"), icon: "phone.badge.waveform"),
        .init(key: "work.learning", parentKey: "work", name: String(localized: "Learning"), icon: "character.book.closed"),
        .init(key: "work.projectManagement", parentKey: "work", name: String(localized: "Project Management"), icon: "gearshape.2"),
        .init(key: "work.breaks", parentKey: "work", name: String(localized: "Breaks"), icon: "mug")
    ]

    // MARK: - Upsert seeding

    private func upsertDefaults() {
        // Upsert all activities, keep a map for subactivities
        var activityByKey: [String: Activity] = [:]
        for a in activityCatalog {
            let act = upsertActivity(seedKey: a.key, name: a.name, icon: a.icon)
            activityByKey[a.key] = act
        }

        // Upsert all subactivities with proper parent relationship
        for s in subactivityCatalog {
            guard let parent = activityByKey[s.parentKey] ?? findActivity(seedKey: s.parentKey) else { continue }
            _ = upsertSubactivity(seedKey: s.key, name: s.name, icon: s.icon, parent: parent)
        }
    }

    private func upsertActivity(seedKey: String, name: String, icon: String) -> Activity {
        if let existing = findActivity(seedKey: seedKey) {
            if existing.name != name { existing.name = name }
            if existing.icon != icon { existing.icon = icon }
            if existing.seedKey.isEmpty { existing.seedKey = seedKey }
            return existing
        } else {
            let a = Activity()
            a.seedKey = seedKey
            a.name = name
            a.icon = icon
            context.insert(a)
            return a
        }
    }

    private func upsertSubactivity(seedKey: String, name: String, icon: String, parent: Activity) -> Subactivity {
        if let existing = findSubactivity(seedKey: seedKey) {
            if existing.name != name { existing.name = name }
            if existing.icon != icon { existing.icon = icon }
            if existing.activity?.persistentModelID != parent.persistentModelID {
                existing.activity = parent
            }
            if existing.seedKey.isEmpty { existing.seedKey = seedKey }
            return existing
        } else {
            let s = Subactivity()
            s.seedKey = seedKey
            s.name = name
            s.icon = icon
            s.activity = parent
            context.insert(s)
            return s
        }
    }

    private func findActivity(seedKey: String) -> Activity? {
        let fd = FetchDescriptor<Activity>(predicate: #Predicate { $0.seedKey == seedKey })
        return (try? context.fetch(fd))?.first
    }

    private func findSubactivity(seedKey: String) -> Subactivity? {
        let fd = FetchDescriptor<Subactivity>(predicate: #Predicate { $0.seedKey == seedKey })
        return (try? context.fetch(fd))?.first
    }

    // MARK: - Reconciliation (merge duplicates by seedKey)

    private func reconcileDuplicateDefaults() throws {
        // Activities
        let allActs = try context.fetch(FetchDescriptor<Activity>())
        let groupsA = Dictionary(grouping: allActs.filter { !$0.seedKey.isEmpty }, by: { $0.seedKey })
        for (_, group) in groupsA where group.count > 1 {
            let keeper = chooseKeeper(from: group)
            for extra in group where extra.persistentModelID != keeper.persistentModelID {
                // move subactivities to keeper
                extra.subactivities?.forEach { $0.activity = keeper }
                context.delete(extra)
            }
        }

        // Subactivities
        let allSubs = try context.fetch(FetchDescriptor<Subactivity>())
        let groupsS = Dictionary(grouping: allSubs.filter { !$0.seedKey.isEmpty }, by: { $0.seedKey })
        for (_, group) in groupsS where group.count > 1 {
            let keeper = chooseKeeper(from: group)
            for extra in group where extra.persistentModelID != keeper.persistentModelID {
                // re-home reflections
                extra.reflections?.forEach { $0.subactivity = keeper }
                context.delete(extra)
            }
        }
    }

    private func chooseKeeper<T: PersistentModel>(from candidates: [T]) -> T {
        // Prefer the one referenced the most; fall back to the first
        if let acts = candidates as? [Activity] {
            return (acts.max { ($0.reflections?.count ?? 0) < ($1.reflections?.count ?? 0) }) as? T ?? candidates[0]
        }
        if let subs = candidates as? [Subactivity] {
            return (subs.max { ($0.reflections?.count ?? 0) < ($1.reflections?.count ?? 0) }) as? T ?? candidates[0]
        }
        return candidates[0]
    }
}
