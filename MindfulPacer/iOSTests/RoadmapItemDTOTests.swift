//
//  RoadmapItemDTOTests.swift
//  iOSTests
//
//  Tests for `RoadmapItemDTO`, the data transfer object that represents a
//  roadmap feature as returned by the backend API. The DTO uses custom
//  `CodingKeys` with capitalized JSON keys ("Platform", "Description", etc.)
//  to match the server's format. These tests ensure that JSON parsing handles
//  this key mapping correctly.
//

import Testing
import Foundation
@testable import iOS

/// Validates that `RoadmapItemDTO` correctly decodes from and encodes to
/// JSON with capitalized keys, matching the backend's response format.
struct RoadmapItemDTOTests {

    /// A complete JSON object with all four capitalized keys should decode
    /// into a DTO with all fields populated.
    @Test func decode_fromValidJSON() throws {
        let json = """
        {
            "Platform": "Apple",
            "Description": "Push notifications",
            "Status": "in progress",
            "Comment": "Expected Q3"
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(RoadmapItemDTO.self, from: json)
        #expect(dto.platform == "Apple")
        #expect(dto.description == "Push notifications")
        #expect(dto.status == "in progress")
        #expect(dto.comment == "Expected Q3")
    }

    /// Encoding and then decoding should produce an identical DTO,
    /// confirming the custom CodingKeys work in both directions.
    @Test func codable_roundTrip() throws {
        let original = RoadmapItemDTO(
            platform: "Android",
            description: "Offline mode",
            status: "tbd",
            comment: "Under review"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RoadmapItemDTO.self, from: data)
        #expect(decoded.platform == original.platform)
        #expect(decoded.description == original.description)
        #expect(decoded.status == original.status)
        #expect(decoded.comment == original.comment)
    }

    /// Decoding with lowercase keys (not matching the custom CodingKeys)
    /// should fail, confirming the DTO strictly expects capitalized keys.
    @Test func decode_lowercaseKeysFails() {
        let json = """
        {
            "platform": "Apple",
            "description": "Test",
            "status": "ready",
            "comment": ""
        }
        """.data(using: .utf8)!

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(RoadmapItemDTO.self, from: json)
        }
    }
}
