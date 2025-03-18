//
//  SettingsViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 13.09.2024.
//

import Foundation
import MessageUI
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Theme

enum Theme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: Self { self }
    
    var icon: String {
        switch self {
        case .system:
            "circle.lefthalf.filled.righthalf.striped.horizontal.inverse"
        case .light:
            "sun.min"
        case .dark:
            "moon"
        }
    }
    
    var localized: String {
        NSLocalizedString(rawValue, comment: "Theme setting option")
    }
    
    var description: String {
        switch self {
        case .system:
            String(localized: "Use the same setting as your device")
        case .light:
            String(localized: "Always use light mode")
        case .dark:
            String(localized: "Always use dark mode")
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    static var appStorageKey: String {
        "theme"
    }
}

// MARK: - ExportFileFormat

enum ExportFileFormat: String, CaseIterable, Identifiable {
    case csv
    
    var description: String {
        switch self {
        case .csv: ".CSV"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .csv: ".csv"
        }
    }
    
    var id: String { self.rawValue }
}

// MARK: - ExportDataModel

enum ExportDataModel: String, CaseIterable, Identifiable {
    case reflection
    case reminder
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .reflection: "Reflections"
        case .reminder: "Reminders"
        }
    }
    
    var icon: String {
        switch self {
        case .reflection: "book.pages.fill"
        case .reminder: "bell.badge.fill"
        }
    }
    
    var fileName: String {
        switch self {
        case .reflection: "MindfulPacer_Reflections"
        case .reminder: "MindfulPacer_Reminders"
        }
    }
}

// MARK: - ExportDocument

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        return [.commaSeparatedText, .spreadsheet]
    }
    
    var fileURL: URL
    
    init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    init(configuration: ReadConfiguration) throws {
        fatalError("Reading not supported")
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return try FileWrapper(url: fileURL)
    }
}

// MARK: - SettingsViewModel

@MainActor
@Observable
class SettingsViewModel {
    
    // MARK: - Dependencies
    
    private let fetchReflectionsUseCase: FetchReflectionsUseCase
    private let fetchRemindersUseCase: FetchRemindersUseCase
    
    // MARK: - Published Properties
    
    var navigationPath: [SettingsNavigationDestination] = []
    var activeSheet: SettingsSheet?
    
    var mailResult: Result<MFMailComposeResult, Error>?
    
    var reflections: [Reflection] = []
    var reminders: [Reminder] = []
    
    var isFetchingRoadmap: Bool = false
    var roadmapItems: [RoadmapItem] = []
    var isInternetConnected: Bool = true
    var fetchErrorMessage: String?
    var isExpandedModeOfUseOn: Bool = false
    var selectedExportFileFormat: ExportFileFormat = .csv
    var selectedExportDataModel: ExportDataModel = .reminder
    var exportURL: URL?
    var isExporting = false
    
    var contactSupportRecipient: String = "support@mindfulpacer.ch"
    var contactSupportSubject: String = "MindfulPacer - Feedback"
    
    var isGermanLanguage: Bool {
        Locale.current.language.languageCode?.identifier == "de"
    }
    
    var privacyPolicyURL: URL {
        isGermanLanguage ? URL(string: "https://mindfulpacer.ch/datenschutzbestimmungen/")! : URL(string: "https://mindfulpacer.ch/en/privacy-policy/")!
    }
    
    var landingPageURL: URL {
        isGermanLanguage ? URL(string: "https://mindfulpacer.ch/")! : URL(string: "https://mindfulpacer.ch/en/mindfulpacer-english/")!
    }
    
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version).\(build)"
    }
    
    var systemVersion: String {
        "iOS \(UIDevice.current.systemVersion)"
    }
    
    var screenSize: String {
        let size = UIScreen.main.bounds.size
        return "\(Int(size.width)) x \(Int(size.height))"
    }
    
    var modelName: String {
        return iPhoneModelMap[modelIdentifier] ?? "Unknown"
    }
    
    var systemReport: String {
        return """
        App Version: \(appVersion)
        System Version: \(systemVersion)
        Screen Size: \(screenSize)
        Model Name: \(modelName)
        Model Identifier: \(modelIdentifier)
        """
    }
    
    // MARK: Private Properties
    
    private var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let identifier = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingCString: $0)
            }
        }
        return identifier ?? "Unknown"
    }
    
    private let iPhoneModelMap: [String: String] = [
        "iPhone11,8": "iPhone XR",
        "iPhone12,1": "iPhone 11",
        "iPhone12,3": "iPhone 11 Pro",
        "iPhone12,5": "iPhone 11 Pro Max",
        "iPhone12,8": "iPhone SE 2nd Gen",
        "iPhone13,1": "iPhone 12 Mini",
        "iPhone13,2": "iPhone 12",
        "iPhone13,3": "iPhone 12 Pro",
        "iPhone13,4": "iPhone 12 Pro Max",
        "iPhone14,2": "iPhone 13 Pro",
        "iPhone14,3": "iPhone 13 Pro Max",
        "iPhone14,4": "iPhone 13 Mini",
        "iPhone14,5": "iPhone 13",
        "iPhone14,6": "iPhone SE 3rd Gen",
        "iPhone14,7": "iPhone 14",
        "iPhone14,8": "iPhone 14 Plus",
        "iPhone15,2": "iPhone 14 Pro",
        "iPhone15,3": "iPhone 14 Pro Max",
        "iPhone15,4": "iPhone 15",
        "iPhone15,5": "iPhone 15 Plus",
        "iPhone16,1": "iPhone 15 Pro",
        "iPhone16,2": "iPhone 15 Pro Max",
        "iPhone17,1": "iPhone 16 Pro",
        "iPhone17,2": "iPhone 16 Pro Max",
        "iPhone17,3": "iPhone 16",
        "iPhone17,4": "iPhone 16 Plus"
    ]
    
    // MARK: - Initialization
    
    init(
        fetchReflectionsUseCase: FetchReflectionsUseCase,
        fetchRemindersUseCase: FetchRemindersUseCase
    ) {
        self.fetchReflectionsUseCase = fetchReflectionsUseCase
        self.fetchRemindersUseCase = fetchRemindersUseCase
    }
    
    // MARK: - View Events
    
    func onViewAppear() {
        fetchReflections()
        fetchReminders()
    }
    
    // MARK: - Presentation
    
    func presentSheet(_ sheet: SettingsSheet) {
        activeSheet = sheet
    }
    
    // MARK: - User Actions
    
    func setModeOfUse(_ modeOfUse: ModeOfUse) {
        isExpandedModeOfUseOn = modeOfUse == .expanded
    }
    
    func onExportTapped() {
        let exportedFileURL: URL?
        
        switch selectedExportDataModel {
        case .reflection:
            exportedFileURL = exportToCSV(reflections: reflections, reminders: [])
        case .reminder:
            exportedFileURL = exportToCSV(reflections: [], reminders: reminders)
        }
        
        if let url = exportedFileURL {
            exportURL = url
            isExporting = true
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchReflections() {
        reflections = fetchReflectionsUseCase.execute() ?? []
    }
    
    private func fetchReminders() {
        reminders = fetchRemindersUseCase.execute() ?? []
    }
    
    private func exportToCSV(reflections: [Reflection], reminders: [Reminder]) -> URL? {
        let fileName = selectedExportDataModel.fileName + "_" + Date.now.formatted(.dateTime.day().month().year()) + selectedExportFileFormat.fileExtension
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        var csvText = ""
        
        if selectedExportDataModel == .reflection {
            csvText.append("Date,Activity,Subactivity,Mood,DidTriggerCrash,WellBeing,Fatigue,ShortnessOfBreath,SleepDisorder,CognitiveImpairment,PhysicalPain,DepressionOrAnxiety,AdditionalInfo\n")
            
            for reflection in reflections {
                let formattedDate = DateFormatter.localizedString(from: reflection.date, dateStyle: .medium, timeStyle: .short)
                let activityName = reflection.activity?.name ?? ""
                let subactivityName = reflection.subactivity?.name ?? ""
                let moodText = reflection.mood?.text ?? ""
                let moodEmoji = reflection.mood?.emoji ?? ""
                let additionalInfo = reflection.additionalInformation.replacingOccurrences(of: "\"", with: "\"\"")
                
                let csvLine = """
                \(formattedDate),\(activityName),\(subactivityName),\(moodEmoji) \(moodText),\(reflection.didTriggerCrash),\(optionalIntToString(reflection.wellBeing)),\(optionalIntToString(reflection.fatigue)),\(optionalIntToString(reflection.shortnessOfBreath)),\(optionalIntToString(reflection.sleepDisorder)),\(optionalIntToString(reflection.cognitiveImpairment)),\(optionalIntToString(reflection.physicalPain)),\(optionalIntToString(reflection.depressionOrAnxiety)),"\(additionalInfo)"
                """
                
                csvText.append(csvLine + "\n")
            }
        } else if selectedExportDataModel == .reminder {
            csvText.append("ID,MeasurementType,ReminderType,Threshold,Interval\n")
            
            for reminder in reminders {
                let csvLine = """
                \(reminder.id),\(reminder.measurementType.rawValue),\(reminder.reminderType.rawValue),\(reminder.threshold),\(reminder.interval.rawValue)
                """
                csvText.append(csvLine + "\n")
            }
        }
        
        do {
            try csvText.write(to: path, atomically: true, encoding: .utf8)
            print("Export successful. File saved at: \(path)")
            return path
        } catch {
            print("Failed to create CSV file: \(error)")
            return nil
        }
    }
    
    private func optionalIntToString(_ value: Int?) -> String {
        return value.map { "\($0)" } ?? ""
    }
}
