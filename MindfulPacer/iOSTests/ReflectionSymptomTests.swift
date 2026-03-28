//
//  ReflectionSymptomTests.swift
//  iOSTests
//
//  Tests for `Reflection.Symptom`, an enum with associated values that models
//  the severity of seven health symptoms tracked in MindfulPacer: well-being,
//  fatigue, shortness of breath, sleep disorder, cognitive impairment,
//  physical pain, and depression/anxiety. Each symptom carries an optional Int
//  severity value (0–4 for well-being, 0–3 for all others). The enum provides
//  computed properties for display names, icons, severity descriptions
//  (e.g. "Absent", "Mild", "Severe"), and color-coded severity indicators.
//

import Testing
import Foundation
@testable import iOS

// MARK: - numOptions

/// Validates `numOptions`, which determines how many severity levels are shown
/// in the symptom picker UI. Well-being has 5 levels (Very Low → Very High),
/// while all other symptoms have 4 levels (Absent → Severe).
struct SymptomNumOptionsTests {

    /// Well-being uses a 5-point scale because it ranges from "Very Low" to "Very High".
    @Test func numOptions_wellBeing_isFive() {
        #expect(Symptom.wellBeing(nil).numOptions == 5)
    }

    /// All non-well-being symptoms use a 4-point severity scale (Absent, Mild, Moderate, Severe).
    @Test(arguments: [
        Symptom.fatigue(nil),
        Symptom.shortnessOfBreath(nil),
        Symptom.sleepDisorder(nil),
        Symptom.cognitiveImpairment(nil),
        Symptom.physicalPain(nil),
        Symptom.depressionOrAnxiety(nil)
    ])
    func numOptions_otherSymptoms_isFour(symptom: Symptom) {
        #expect(symptom.numOptions == 4)
    }
}

// MARK: - value getter

/// Validates that the `value` computed property extracts the associated Int?
/// from any symptom variant, regardless of which symptom it is.
struct SymptomValueTests {

    /// A well-being of 3 should return 3 from the `value` getter.
    @Test func value_wellBeing_returnsAssociatedValue() {
        #expect(Symptom.wellBeing(3).value == 3)
    }

    /// A nil-valued symptom should return nil.
    @Test func value_nil_returnsNil() {
        #expect(Symptom.fatigue(nil).value == nil)
    }

    /// Verify that `value` works for every symptom variant.
    @Test func value_allVariants_returnCorrectValue() {
        #expect(Symptom.fatigue(2).value == 2)
        #expect(Symptom.shortnessOfBreath(1).value == 1)
        #expect(Symptom.sleepDisorder(0).value == 0)
        #expect(Symptom.cognitiveImpairment(3).value == 3)
        #expect(Symptom.physicalPain(1).value == 1)
        #expect(Symptom.depressionOrAnxiety(2).value == 2)
    }
}

// MARK: - setValue

/// Validates `setValue(_:)`, a mutating method that replaces the associated
/// severity value while preserving the symptom type. This is used when the
/// user taps a different severity level in the reflection editor.
struct SymptomSetValueTests {

    /// Setting a new value on a well-being symptom should update the associated value
    /// while keeping it as `.wellBeing`.
    @Test func setValue_wellBeing_updatesValue() {
        var symptom = Symptom.wellBeing(1)
        symptom.setValue(4)
        #expect(symptom == .wellBeing(4))
    }

    /// Setting nil should clear the severity (user deselected).
    @Test func setValue_toNil_clearsValue() {
        var symptom = Symptom.fatigue(2)
        symptom.setValue(nil)
        #expect(symptom == .fatigue(nil))
    }

    /// Verify `setValue` works across all symptom types.
    @Test func setValue_allVariants() {
        var s1 = Symptom.shortnessOfBreath(nil)
        s1.setValue(2)
        #expect(s1 == .shortnessOfBreath(2))

        var s2 = Symptom.sleepDisorder(0)
        s2.setValue(3)
        #expect(s2 == .sleepDisorder(3))

        var s3 = Symptom.cognitiveImpairment(1)
        s3.setValue(0)
        #expect(s3 == .cognitiveImpairment(0))

        var s4 = Symptom.physicalPain(nil)
        s4.setValue(1)
        #expect(s4 == .physicalPain(1))

        var s5 = Symptom.depressionOrAnxiety(3)
        s5.setValue(2)
        #expect(s5 == .depressionOrAnxiety(2))
    }
}

// MARK: - Display Names & Icons

/// Verifies that each symptom variant returns a non-empty display name and
/// icon string. These are used in the symptom picker and reflection detail views.
struct SymptomDisplayTests {

    /// Every symptom should have a human-readable display name for the UI.
    @Test func displayName_allVariants_nonEmpty() {
        let symptoms: [Symptom] = [
            .wellBeing(nil), .fatigue(nil), .shortnessOfBreath(nil),
            .sleepDisorder(nil), .cognitiveImpairment(nil),
            .physicalPain(nil), .depressionOrAnxiety(nil)
        ]
        for symptom in symptoms {
            #expect(!symptom.displayName.isEmpty, "displayName empty for \(symptom)")
        }
    }

    /// Every symptom should have an SF Symbol icon name for rendering.
    @Test func icon_allVariants_nonEmpty() {
        let symptoms: [Symptom] = [
            .wellBeing(nil), .fatigue(nil), .shortnessOfBreath(nil),
            .sleepDisorder(nil), .cognitiveImpairment(nil),
            .physicalPain(nil), .depressionOrAnxiety(nil)
        ]
        for symptom in symptoms {
            #expect(!symptom.icon.isEmpty, "icon empty for \(symptom)")
        }
    }
}

// MARK: - Well-Being Descriptions

/// Validates the well-being description mapping. Well-being is special because
/// it uses a 5-point positive scale (higher = better), unlike other symptoms
/// where higher = worse. Descriptions are localized, so we verify structural
/// properties rather than exact English strings.
struct SymptomWellBeingDescriptionTests {

    /// Each of the 5 well-being levels (0–4) should produce a non-empty
    /// localized description string.
    @Test(arguments: [0, 1, 2, 3, 4])
    func description_wellBeing_knownValues_nonEmpty(value: Int) {
        let description = Symptom.wellBeing(value).description
        #expect(!description.isEmpty)
    }

    /// Each well-being level should map to a distinct description so the
    /// user can tell them apart in the UI.
    @Test func description_wellBeing_allLevelsDistinct() {
        let descriptions: [String] = (0...4).map { i in
            Symptom.wellBeing(i).description
        }
        #expect(Set(descriptions).count == 5)
    }

    /// A nil well-being value (not yet set by the user) should produce a
    /// description that is different from all set values.
    @Test func description_wellBeing_nil_differsFromSetValues() {
        let nilDescription = Symptom.wellBeing(nil).description
        for i in 0...4 {
            #expect(nilDescription != Symptom.wellBeing(i).description)
        }
    }
}

// MARK: - Severity Descriptions (non-well-being)

/// Validates the severity description mapping for standard symptoms (4-point
/// scale from absent to severe). Descriptions are localized, so we verify
/// structural properties rather than exact strings.
struct SymptomSeverityDescriptionTests {

    /// Each of the 4 severity levels (0–3) should produce a non-empty
    /// localized description string.
    @Test(arguments: [0, 1, 2, 3])
    func description_fatigue_knownValues_nonEmpty(value: Int) {
        let description = Symptom.fatigue(value).description
        #expect(!description.isEmpty)
    }

    /// Each severity level should map to a distinct description.
    @Test func description_fatigue_allLevelsDistinct() {
        let descriptions: [String] = (0...3).map { i in
            Symptom.fatigue(i).description
        }
        #expect(Set(descriptions).count == 4)
    }

    /// A nil value should produce a different description than any set value.
    @Test func description_fatigue_nil_differsFromSetValues() {
        let nilDescription = Symptom.fatigue(nil).description
        for i in 0...3 {
            #expect(nilDescription != Symptom.fatigue(i).description)
        }
    }
}

// MARK: - isWellBeing

/// Validates the `isWellBeing` flag which is used to decide which description
/// and color scale to apply in the UI.
struct SymptomIsWellBeingTests {

    /// The `.wellBeing` case should return true.
    @Test func isWellBeing_true() {
        #expect(Symptom.wellBeing(nil).isWellBeing == true)
    }

    /// All other symptom types should return false.
    @Test func isWellBeing_false_forOthers() {
        #expect(Symptom.fatigue(nil).isWellBeing == false)
        #expect(Symptom.shortnessOfBreath(nil).isWellBeing == false)
        #expect(Symptom.physicalPain(nil).isWellBeing == false)
    }
}

// MARK: - Codable

/// Validates that Symptom cases correctly survive JSON encoding/decoding,
/// which is important because symptoms are persisted via SwiftData.
struct SymptomCodableTests {

    /// A symptom with a value should round-trip through JSON unchanged.
    @Test func codable_roundTrip_withValue() throws {
        let original = Symptom.fatigue(2)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Symptom.self, from: data)
        #expect(decoded == original)
    }

    /// A symptom with nil value should also round-trip correctly.
    @Test func codable_roundTrip_withNil() throws {
        let original = Symptom.wellBeing(nil)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Symptom.self, from: data)
        #expect(decoded == original)
    }
}
