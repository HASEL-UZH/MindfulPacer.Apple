//
//  RoadmapItemTests.swift
//  iOSTests
//
//  Tests for `RoadmapItem` and its nested `Platform` and `Status` enums.
//  `RoadmapItem` represents a feature on the project roadmap, parsed from
//  a remote API response (RoadmapItemDTO). The `Platform` enum uses a custom
//  case-insensitive initializer that falls back to `.all` for unknown values,
//  and `Status` maps raw strings like "in progress" to enum cases.
//

import Testing
import Foundation
@testable import iOS

// MARK: - Platform Parsing

/// Verifies that `RoadmapItem.Platform.init(rawValue:)` correctly parses
/// platform strings from the API. The initializer is case-insensitive and
/// defaults unknown values to `.all` so the app gracefully handles unexpected
/// server responses.
struct RoadmapPlatformTests {

    /// The exact string "Apple" (matching the raw value) should parse to `.apple`.
    @Test func platform_apple_exactMatch() {
        let platform = RoadmapItem.Platform(rawValue: "Apple")
        #expect(platform == .apple)
    }

    /// Case-insensitive: "apple" in lowercase should also parse to `.apple`.
    @Test func platform_apple_caseInsensitive() {
        let platform = RoadmapItem.Platform(rawValue: "apple")
        #expect(platform == .apple)
    }

    /// "Android" should parse to `.android`.
    @Test func platform_android() {
        let platform = RoadmapItem.Platform(rawValue: "Android")
        #expect(platform == .android)
    }

    /// "All" should parse to `.all`.
    @Test func platform_all() {
        let platform = RoadmapItem.Platform(rawValue: "All")
        #expect(platform == .all)
    }

    /// An unrecognized platform string from the API (e.g. "Web") should
    /// fall back to `.all` instead of crashing, ensuring forward compatibility.
    @Test func platform_unknownFallsBackToAll() {
        let platform = RoadmapItem.Platform(rawValue: "Web")
        #expect(platform == .all)
    }

    /// An empty string should also fall back to `.all`.
    @Test func platform_emptyStringFallsBackToAll() {
        let platform = RoadmapItem.Platform(rawValue: "")
        #expect(platform == .all)
    }

    /// Each platform should provide an icon name (SF Symbol or nil for Android
    /// which uses a custom image instead).
    @Test func platform_icons() {
        #expect(RoadmapItem.Platform.apple.icon == "apple.logo")
        #expect(RoadmapItem.Platform.android.icon == nil)
        #expect(RoadmapItem.Platform.all.icon == "iphone.gen1")
    }

    /// Android uses a custom image asset; the other platforms do not.
    @Test func platform_images() {
        #expect(RoadmapItem.Platform.android.image == "android-logo")
        #expect(RoadmapItem.Platform.apple.image == nil)
        #expect(RoadmapItem.Platform.all.image == nil)
    }
}

// MARK: - Status Parsing

/// Verifies that `RoadmapItem.Status` correctly maps raw strings to cases.
/// The "in progress" status uses a space in its raw value, making it a good
/// edge case to verify.
struct RoadmapStatusTests {

    /// "in progress" (with space) should map to `.inProgress`.
    @Test func status_inProgress() {
        let status = RoadmapItem.Status(rawValue: "in progress")
        #expect(status == .inProgress)
    }

    /// "paused" should map to `.paused`.
    @Test func status_paused() {
        let status = RoadmapItem.Status(rawValue: "paused")
        #expect(status == .paused)
    }

    /// "tbd" should map to `.tbd`.
    @Test func status_tbd() {
        let status = RoadmapItem.Status(rawValue: "tbd")
        #expect(status == .tbd)
    }

    /// "ready" should map to `.ready`.
    @Test func status_ready() {
        let status = RoadmapItem.Status(rawValue: "ready")
        #expect(status == .ready)
    }

    /// An unrecognized status string should return nil from the failable init.
    @Test func status_unknownReturnsNil() {
        let status = RoadmapItem.Status(rawValue: "cancelled")
        #expect(status == nil)
    }
}

// MARK: - DTO Mapping

/// Verifies that `RoadmapItem.init(dto:)` correctly maps a server-side DTO
/// into the app's domain model, including platform parsing and status fallback.
struct RoadmapItemDTOMappingTests {

    /// A DTO with known platform and status values should map all fields correctly.
    @Test func initFromDTO_mapsAllFields() {
        let dto = RoadmapItemDTO(
            platform: "Apple",
            description: "Dark mode support",
            status: "in progress",
            comment: "Coming in v2.0"
        )
        let item = RoadmapItem(dto: dto)
        #expect(item.platform == .apple)
        #expect(item.description == "Dark mode support")
        #expect(item.status == .inProgress)
        #expect(item.comment == "Coming in v2.0")
    }

    /// When the DTO's status string is unrecognized, the model should fall
    /// back to `.tbd` (to be determined) so the roadmap still renders.
    @Test func initFromDTO_unknownStatusFallsBackToTBD() {
        let dto = RoadmapItemDTO(
            platform: "All",
            description: "Feature X",
            status: "unknown_status",
            comment: ""
        )
        let item = RoadmapItem(dto: dto)
        #expect(item.status == .tbd)
    }

    /// The `id` property is derived from the description text, so two items
    /// with the same description share the same identity.
    @Test func id_isDescription() {
        let dto = RoadmapItemDTO(platform: "All", description: "Some Feature", status: "tbd", comment: "")
        let item = RoadmapItem(dto: dto)
        #expect(item.id == "Some Feature")
    }
}
