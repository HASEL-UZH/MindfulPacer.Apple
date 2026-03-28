//
//  MoodTests.swift
//  iOSTests
//
//  Tests for `Reflection.Mood`, a simple value type that pairs an emoji with
//  a text label (e.g. "😊" + "Happy"). Moods are selected by the user during
//  reflection creation and persisted as part of the Reflection SwiftData model.
//  The struct conforms to Codable (for persistence) and Equatable (for UI
//  selection state comparisons and filter matching).
//

import Testing
import Foundation
@testable import iOS

// MARK: - Mood Equality

/// Validates that `Mood` equality works correctly, which is critical for
/// the filter system where selected moods are compared against reflection moods.
struct MoodEqualityTests {

    /// Two moods with identical emoji and text should be equal.
    @Test func equality_sameValues_areEqual() {
        let a = Mood(emoji: "😊", text: "Happy")
        let b = Mood(emoji: "😊", text: "Happy")
        #expect(a == b)
    }

    /// Moods with different emoji should not be equal, even if the text matches.
    @Test func equality_differentEmoji_areNotEqual() {
        let a = Mood(emoji: "😊", text: "Happy")
        let b = Mood(emoji: "😢", text: "Happy")
        #expect(a != b)
    }

    /// Moods with different text should not be equal, even if the emoji matches.
    @Test func equality_differentText_areNotEqual() {
        let a = Mood(emoji: "😊", text: "Happy")
        let b = Mood(emoji: "😊", text: "Joyful")
        #expect(a != b)
    }
}

// MARK: - Mood Codable

/// Validates that `Mood` survives JSON encoding/decoding, which is necessary
/// because moods are persisted inside Reflection objects in SwiftData.
struct MoodCodableTests {

    /// A mood should encode to JSON and decode back to an identical value.
    @Test func codable_roundTrip() throws {
        let original = Mood(emoji: "😡", text: "Angry")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Mood.self, from: data)
        #expect(decoded == original)
    }

    /// Moods with Unicode emoji should encode and decode without corruption.
    @Test func codable_unicodeEmoji() throws {
        let original = Mood(emoji: "🥰", text: "In love")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Mood.self, from: data)
        #expect(decoded.emoji == "🥰")
        #expect(decoded.text == "In love")
    }
}
