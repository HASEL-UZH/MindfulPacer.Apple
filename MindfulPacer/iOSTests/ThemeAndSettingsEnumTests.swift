//
//  ThemeAndSettingsEnumTests.swift
//  iOSTests
//
//  Tests for the supporting enums defined in SettingsViewModel:
//  - `Theme`: controls light/dark/system appearance (stored in AppStorage)
//  - `ExportFileFormat`: available file formats for data export (currently CSV only)
//  - `ExportDataModel`: which data to export (reflections or reminders)
//
//  These enums drive the Settings screen UI and data export functionality.
//

import Testing
import Foundation
import SwiftUI
@testable import iOS

// MARK: - Theme

/// Validates `Theme` enum properties used to render the appearance settings.
/// The theme selection is persisted via AppStorage and affects the app's
/// color scheme globally.
struct ThemeTests {

    /// Each theme should have a non-empty SF Symbol icon name.
    @Test func icon_allCases_nonEmpty() {
        for theme in Theme.allCases {
            #expect(!theme.icon.isEmpty, "Theme \(theme) has empty icon")
        }
    }

    /// Each theme should have a non-empty localized description explaining
    /// what the setting does (shown as subtitle text in the settings UI).
    @Test func description_allCases_nonEmpty() {
        for theme in Theme.allCases {
            #expect(!theme.description.isEmpty, "Theme \(theme) has empty description")
        }
    }

    /// `.system` should return nil for colorScheme (follow device setting),
    /// while `.light` and `.dark` should return their respective schemes.
    @Test func colorScheme_mapping() {
        #expect(Theme.system.colorScheme == nil)
        #expect(Theme.light.colorScheme == .light)
        #expect(Theme.dark.colorScheme == .dark)
    }

    /// The AppStorage key should be a stable string so persisted preferences
    /// are not lost between app updates.
    @Test func appStorageKey_isStable() {
        #expect(Theme.appStorageKey == "theme")
    }

    /// All three cases should exist.
    @Test func allCases_count() {
        #expect(Theme.allCases.count == 3)
    }
}

// MARK: - ExportFileFormat

/// Validates `ExportFileFormat` properties used in the data export sheet.
/// Currently only CSV is supported, but the enum is designed for extensibility.
struct ExportFileFormatTests {

    /// CSV should have a ".csv" file extension.
    @Test func csv_fileExtension() {
        #expect(ExportFileFormat.csv.fileExtension == ".csv")
    }

    /// The display description should be ".CSV" (uppercase for UI labels).
    @Test func csv_description() {
        #expect(ExportFileFormat.csv.description == ".CSV")
    }

    /// Each format should have an icon for the picker UI.
    @Test func csv_icon_nonEmpty() {
        #expect(!ExportFileFormat.csv.icon.isEmpty)
    }

    /// The `id` should equal the raw value for use in SwiftUI lists.
    @Test func csv_id() {
        #expect(ExportFileFormat.csv.id == "csv")
    }
}

// MARK: - ExportDataModel

/// Validates `ExportDataModel` properties used to select what data to export.
/// Users can export either their reflections or their reminders.
struct ExportDataModelTests {

    /// Each model should have a non-empty description for the picker UI.
    @Test func description_allCases_nonEmpty() {
        for model in ExportDataModel.allCases {
            #expect(!model.description.isEmpty)
        }
    }

    /// Each model should have a non-empty icon for the picker UI.
    @Test func icon_allCases_nonEmpty() {
        for model in ExportDataModel.allCases {
            #expect(!model.icon.isEmpty)
        }
    }

    /// File names should be deterministic and include the model type.
    @Test func fileName_reflection() {
        #expect(ExportDataModel.reflection.fileName == "MindfulPacer_Reflections")
    }

    @Test func fileName_reminder() {
        #expect(ExportDataModel.reminder.fileName == "MindfulPacer_Reminders")
    }

    /// Both models currently only support CSV export.
    @Test func allowedExportFormats_containsCSV() {
        for model in ExportDataModel.allCases {
            #expect(model.allowedExportFormats.contains(.csv))
        }
    }

    /// The `id` should equal the raw value.
    @Test func id_equalsRawValue() {
        for model in ExportDataModel.allCases {
            #expect(model.id == model.rawValue)
        }
    }
}
