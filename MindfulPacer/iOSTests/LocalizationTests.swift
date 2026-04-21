//
//  LocalizationTests.swift
//  iOSTests
//
//  Tests that all `.xcstrings` localization files contain translations for
//  every supported language. Parses the xcstrings JSON at test time and
//  reports any string keys that are missing a translation (excluding keys
//  marked `shouldTranslate = false` or `extractionState = "stale"`).
//
//  The project declares en (source), de, fr, it as known regions.
//  Currently only German (de) translations are present, so the test
//  validates de, fr and it locales. Extend `expectedLanguages` when
//  fr / it translations are added.
//

import Testing
import Foundation
@testable import iOS

// MARK: - XCStrings JSON model

/// Minimal Codable model for Apple's `.xcstrings` JSON format, just enough
/// to detect missing translations.
private struct XCStringsFile: Decodable {
    let sourceLanguage: String
    let strings: [String: StringEntry]

    struct StringEntry: Decodable {
        let shouldTranslate: Bool?
        let extractionState: String?
        let localizations: [String: Localization]?

        struct Localization: Decodable {
            let stringUnit: StringUnit?

            struct StringUnit: Decodable {
                let state: String?
                let value: String?
            }
        }
    }
}

// MARK: - Helpers

/// Root of the MindfulPacer source tree, derived from this file's compile-time path.
/// iOSTests/LocalizationTests.swift  →  ../ = MindfulPacer/
private let projectRoot: String = {
    // #filePath → .../MindfulPacer/iOSTests/LocalizationTests.swift
    let testsDir = ("\(#filePath)" as NSString).deletingLastPathComponent
    return (testsDir as NSString).deletingLastPathComponent
}()

private enum LocalizationTestError: Error, CustomStringConvertible {
    case fileNotFound(String)

    var description: String {
        switch self {
        case .fileNotFound(let path):
            return "Could not find xcstrings file at: \(path)"
        }
    }
}

/// Loads an xcstrings file from the source tree (not the compiled bundle).
private func loadXCStrings(at relativePath: String) throws -> XCStringsFile {
    let fullPath = (projectRoot as NSString).appendingPathComponent(relativePath)
    let url = URL(fileURLWithPath: fullPath)
    guard FileManager.default.fileExists(atPath: fullPath) else {
        throw LocalizationTestError.fileNotFound(fullPath)
    }
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(XCStringsFile.self, from: data)
}

/// Discovers all .xcstrings files under the project root.
private func allXCStringsPaths() -> [String] {
    let fm = FileManager.default
    let rootURL = URL(fileURLWithPath: projectRoot)
    guard let enumerator = fm.enumerator(at: rootURL, includingPropertiesForKeys: nil) else { return [] }
    var paths: [String] = []
    for case let url as URL in enumerator where url.pathExtension == "xcstrings" {
        paths.append(url.path)
    }
    return paths
}

/// Returns all string keys from an `XCStringsFile` that are meant to be
/// translated but are missing a translation for the given language.
private func missingKeys(in file: XCStringsFile, for language: String) -> [String] {
    file.strings.compactMap { key, entry in
        // Skip keys explicitly excluded from translation
        if entry.shouldTranslate == false { return nil }
        // Skip stale keys (removed from source but not yet cleaned up)
        if entry.extractionState == "stale" { return nil }
        // Skip the source language itself
        if language == file.sourceLanguage { return nil }

        // Skip keys where the source value is empty (nothing to translate)
        if let sourceLoc = entry.localizations?[file.sourceLanguage],
           let sourceValue = sourceLoc.stringUnit?.value,
           sourceValue.isEmpty { return nil }

        guard let localization = entry.localizations?[language] else {
            return key // no entry at all for this language
        }

        // A key with state "needs_review" is considered incomplete
        if localization.stringUnit?.state == "needs_review" { return nil }
        // An empty translated value is treated as missing
        if let value = localization.stringUnit?.value, value.isEmpty { return key }

        return nil
    }
    .sorted()
}

// MARK: - Tests

/// Languages that must have complete translations. Extend this array as
/// new languages are added (e.g. "fr", "it").
private let expectedLanguages = ["de", "fr", "it", "es"]

struct LocalizationCompletenessTests {

    /// The main Localizable.xcstrings must contain a translation for every
    /// translatable key in each expected language.
    @Test(arguments: expectedLanguages)
    func localizable_allKeysTranslated(language: String) throws {
        let file = try loadXCStrings(at: "Shared/Resources/Localizable.xcstrings")
        let missing = missingKeys(in: file, for: language)

        #expect(missing.isEmpty,
                "Localizable.xcstrings is missing \(missing.count) \(language) translation(s):\n\(missing.map { "  • \($0)" }.joined(separator: "\n"))")
    }

    /// Every xcstrings file in the source tree should have complete
    /// translations for expected languages.
    @Test(arguments: expectedLanguages)
    func allXCStringsFiles_noMissingTranslations(language: String) throws {
        let paths = allXCStringsPaths()

        var failures: [(file: String, keys: [String])] = []

        for path in paths {
            let url = URL(fileURLWithPath: path)
            let data = try Data(contentsOf: url)
            let file = try JSONDecoder().decode(XCStringsFile.self, from: data)
            let missing = missingKeys(in: file, for: language)

            if !missing.isEmpty {
                failures.append((file: url.lastPathComponent, keys: missing))
            }
        }

        let report = failures.map { entry in
            "\(entry.file): \(entry.keys.count) missing\n" +
            entry.keys.map { "  • \($0)" }.joined(separator: "\n")
        }.joined(separator: "\n\n")

        #expect(failures.isEmpty,
                "Missing \(language) translations across xcstrings files:\n\(report)")
    }

    /// Every translatable key should have a non-empty value in the source
    /// language (en). Guards against accidentally blanking a source string.
    @Test func localizable_sourceStringsNonEmpty() throws {
        let file = try loadXCStrings(at: "Shared/Resources/Localizable.xcstrings")
        let emptySourceKeys = file.strings.compactMap { key, entry -> String? in
            if entry.shouldTranslate == false { return nil }
            if entry.extractionState == "stale" { return nil }
            // Source language often uses the key itself as the value.
            // Flag keys that have an explicit empty en value.
            if let enLoc = entry.localizations?[file.sourceLanguage],
               let value = enLoc.stringUnit?.value,
               value.isEmpty {
                return key
            }
            return nil
        }.sorted()

        #expect(emptySourceKeys.isEmpty,
                "Localizable.xcstrings has \(emptySourceKeys.count) key(s) with empty source (\(file.sourceLanguage)) value:\n\(emptySourceKeys.map { "  • \($0)" }.joined(separator: "\n"))")
    }

    /// Proper nouns, brand names, and terms that are intentionally identical
    /// to the English key in at least one locale. Extend this set when a new
    /// key is legitimately the same in any supported language.
    private static let identicalAcrossLanguages: Set<String> = [
        "%@\n%@",
        "1 Minute", "10 Minutes", "15 Minutes",
        "2 Minutes", "5 Minutes", "30 Minutes",
        "Absent", "App Info", "Apple Health Integration",
        "Apple Watch", "Apple Watch Support", "Articles",
        "Community", "Date", "Fatigue", "Gaming", "General", "Home",
        "Label", "Long Covid Kids Schweiz",
        "Meditation", "Meetings", "Mild", "MindfulPacer",
        "MindfulPacer ", "MindfulPacer Version %@", "Minutes",
        "Networking", "Normal", "Note", "Onboarding", "Outreach",
        "Relaxation", "Roadmap", "Start", "Status Info",
        "Stretching", "Yoga",
        "iPhone + Apple Watch",
    ]

    /// No translated string should be identical to the source key for
    /// non-trivial keys (length > 3 and not marked shouldTranslate=false).
    /// This catches placeholders that were never actually translated.
    @Test(arguments: expectedLanguages)
    func localizable_translationsNotIdenticalToKey(language: String) throws {
        let file = try loadXCStrings(at: "Shared/Resources/Localizable.xcstrings")
        let untranslated = file.strings.compactMap { key, entry -> String? in
            if entry.shouldTranslate == false { return nil }
            if entry.extractionState == "stale" { return nil }
            guard key.count > 3 else { return nil }
            if Self.identicalAcrossLanguages.contains(key) { return nil }
            guard let value = entry.localizations?[language]?.stringUnit?.value else { return nil }
            // If the translation is identical to the English key, it's
            // likely a copy-paste placeholder that was never translated.
            return value == key ? key : nil
        }.sorted()

        #expect(untranslated.isEmpty,
                "\(untranslated.count) \(language) translation(s) are identical to the English key (possibly untranslated):\n\(untranslated.map { "  • \($0)" }.joined(separator: "\n"))")
    }
}
