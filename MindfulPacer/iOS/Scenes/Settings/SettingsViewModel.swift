//
//  SettingsViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 13.09.2024.
//

import Foundation
import MessageUI
import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import Combine

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
    
    var labelColor: Color {
        switch self {
        case .system: Color.primary
        case .light: .yellow
        case .dark: .purple
        }
    }
    
    static var appStorageKey: String {
        "theme"
    }
}

// MARK: - SupportingInstitute

enum SupportingInstitute: String, CaseIterable, Identifiable {
    case uzh, dizh, longCovid
    
    var id: String { name }
    
    var name: String {
        switch self {
        case .uzh: "UZH"
        case .dizh: "DIZH"
        case .longCovid: "Long Covid Switzerland"
        }
    }
    
    var logo: Image {
        switch self {
        case .uzh: Image(.UZH)
        case .dizh: Image(.DIZH)
        case .longCovid: Image(.longCovid)
        }
    }
    
    var url: URL {
        switch self {
        case .uzh:
            URL(string: Locale.current.language.languageCode?.identifier == "de" ? "https://www.uzh.ch/de.html" : "https://www.uzh.ch/en.html")!
        case .dizh:
            URL(string: Locale.current.language.languageCode?.identifier == "de" ? "https://www.dizh.uzh.ch/de/home-2/" : "https://www.dizh.uzh.ch/en/home-2/")!
        case .longCovid:
            URL(string: "https://www.long-covid-info.ch/")!
        }
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
    
    var icon: String {
        switch self {
        case .csv: "document.fill"
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
        case .reflection: String(localized: "Reflections")
        case .reminder: String(localized: "Reminders")
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
    
    var allowedExportFormats: [ExportFileFormat] {
        switch self {
        case .reflection, .reminder:
            return [.csv]
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
    
    private let modelContext: ModelContext
    private let resetDatabaseUseCase: ResetDatabaseUseCase
    
    // MARK: - Published Properties
    
    var navigationPath: [SettingsNavigationDestination] = []
    var activeSheet: SettingsSheet?
    var activeAlert: SettingsAlert?
    
    var mailResult: Result<MFMailComposeResult, Error>?
    
    var isShowingDeleteAllDataAlert: Bool = false
    
    var reflections: [Reflection] = []
    var reminders: [Reminder] = []
    
    var watchConnectionStatus: WatchConnectionStatus = .initializing
    var watchConnectionSpeed: WatchConnectionSpeed = .noResponse
    
    var isWatchPaired: Bool {
        return watchConnectionStatus != .noWatchPaired
    }
    
    var isWatchAppInstalled: Bool {
        switch watchConnectionStatus {
        case .noWatchPaired, .appNotInstalled:
            return false
        default:
            return true
        }
    }
    
    var isFetchingRoadmap: Bool = false
    var roadmapItems: [RoadmapItem] = []
    var isInternetConnected: Bool = true
    var fetchErrorMessage: String?
    var isExpandedModeOfUseOn: Bool = false
    var deviceMode: DeviceMode = DeviceMode.current(from: DefaultsStore.shared) {
        didSet {
            guard oldValue != deviceMode else { return }
            DefaultsStore.shared.set(deviceMode.rawValue, forKey: DeviceMode.appStorageKey)
        }
    }
    var selectedExportFileFormat: ExportFileFormat = .csv
    var selectedExportDataModel: ExportDataModel = .reminder
    var exportURL: URL?
    var isExporting = false
    
    var isShowingDeleteAllUserDataAlert: Bool = false
    
    var contactSupportRecipient: String = "support@mindfulpacer.ch"
    var contactSupportSubject: String = "MindfulPacer - Feedback"
    
    var stepData: [(startDate: Date, endDate: Date, stepCount: Double)] = []
    var heartRateData: [(startDate: Date, endDate: Date, stepCount: Double)] = []
    
    var bufferValues: [String: TimeInterval] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    
    var isGermanLanguage: Bool {
        Locale.current.language.languageCode?.identifier == "de"
    }
    
    var privacyPolicyURL: URL {
        isGermanLanguage ? URL(string: "https://mindfulpacer.ch/datenschutzbestimmungen/")! : URL(string: "https://mindfulpacer.ch/en/privacy-policy/")!
    }
    
    var landingPageURL: URL {
        isGermanLanguage ? URL(string: "https://mindfulpacer.ch/")! : URL(string: "https://mindfulpacer.ch/en/mindfulpacer-english/")!
    }
    
    var appleWatchInstallationHelp: URL {
        isGermanLanguage ? URL(string: "https://support.apple.com/de-ch/109023")! : URL(string: "https://support.apple.com/en-us/109023")!
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
    
    // MARK: - Helpers
    
    var selectedFileUTType: UTType {
        switch selectedExportFileFormat {
        case .csv: return .commaSeparatedText
        }
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
        modelContext: ModelContext,
        resetDatabaseUseCase: ResetDatabaseUseCase
    ) {
        self.modelContext = modelContext
        self.resetDatabaseUseCase = resetDatabaseUseCase
        
        loadAllBuffers()
        subscribeToWatchStatus()
    }
    
    // MARK: - View Events
    
    func onViewAppear() {
        fetchReflections()
    }
    
    func updateReminders(_ newReminders: [Reminder]) {
        reminders = newReminders
    }
    
    // MARK: - Presentation
    
    func presentSheet(_ sheet: SettingsSheet) {
        activeSheet = sheet
    }
    
    func presentAlert(_ alert: SettingsAlert) {
        activeAlert = alert
    }
    
    // MARK: - User Actions
    
    func saveBuffer(for interval: Reminder.Interval, type: Reminder.MeasurementType, newBufferInSeconds: TimeInterval) {
        let key = StorageKeys.bufferKey(for: interval, type: type)
        sharedUserDefaults?.set(newBufferInSeconds, forKey: key)
        bufferValues[key] = newBufferInSeconds
    }
    
    func resetBuffersToDefaults() {
        let measurementTypes: [Reminder.MeasurementType] = [.heartRate, .steps]
        
        for type in measurementTypes {
            let intervals = (type == .heartRate) ? Reminder.Interval.heartRateIntervals : Reminder.Interval.stepsIntervals
            for interval in intervals {
                let key = StorageKeys.bufferKey(for: interval, type: type)
                sharedUserDefaults?.removeObject(forKey: key)
            }
        }
        
        loadAllBuffers()
    }
    
    func resetDatabase() {
        Task { @MainActor in
            do {
                try await resetDatabaseUseCase.execute()
                reflections.removeAll()
                reminders.removeAll()
                stepData.removeAll()
                heartRateData.removeAll()
                bufferValues.removeAll()
                exportURL = nil
                presentAlert(.restartApp)
            } catch {
                print("Reset failed:", error)
            }
        }
    }
    
    func configure(_ modeOfUse: ModeOfUse, _ deviceMode: DeviceMode) {
        isExpandedModeOfUseOn = modeOfUse == .expanded
        self.deviceMode = deviceMode
    }
    
    func onExportTapped() {
        let exportedFileURL: URL?
        
        switch selectedExportDataModel {
        case .reflection, .reminder:
            selectedExportFileFormat = .csv
            exportedFileURL = exportToCSV(
                reflections: selectedExportDataModel == .reflection ? reflections : [],
                reminders: selectedExportDataModel == .reminder ? reminders : []
            )
        }
        
        if let url = exportedFileURL {
            exportURL = url
            isExporting = true
        }
    }
    
    // MARK: - Delete All Data
    
    func requestDeleteAllUserData() {
        isShowingDeleteAllUserDataAlert = true
    }
    
    func confirmDeleteAllUserData() {
        reflections.removeAll()
        reminders.removeAll()
        stepData.removeAll()
        heartRateData.removeAll()
        bufferValues.removeAll()
        exportURL = nil
        
        if let defaults = sharedUserDefaults {
            for (key, _) in defaults.dictionaryRepresentation() {
                defaults.removeObject(forKey: key)
            }
            defaults.synchronize()
        }
        
        let fm = FileManager.default
        let directories: [URL?] = [
            fm.urls(for: .documentDirectory, in: .userDomainMask).first,
            fm.urls(for: .cachesDirectory, in: .userDomainMask).first
        ]
        for dir in directories.compactMap({ $0 }) {
            if let enumerator = fm.enumerator(at: dir, includingPropertiesForKeys: nil) {
                for case let url as URL in enumerator {
                    try? fm.removeItem(at: url)
                }
            }
        }
        
        NotificationCenter.default.post(name: .init("MindfulPacerUserDataDeleted"), object: nil)
    }
    
    // MARK: - Private Methods
    
    private func subscribeToWatchStatus() {
        ConnectivityService.shared.$connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in self?.watchConnectionStatus = status }
            .store(in: &cancellables)
        
        ConnectivityService.shared.$connectionSpeed
            .receive(on: DispatchQueue.main)
            .sink { [weak self] speed in self?.watchConnectionSpeed = speed }
            .store(in: &cancellables)
    }
    
    private func fetchReflections() {
        do {
            let descriptor = FetchDescriptor<Reflection>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            reflections = try modelContext.fetch(descriptor)
        } catch {
            print("DEBUG: Could not fetch reflections: \(error.localizedDescription)")
            reflections = []
        }
    }
    
    private func loadAllBuffers() {
        var loadedValues: [String: TimeInterval] = [:]
        let measurementTypes: [Reminder.MeasurementType] = [.heartRate, .steps]

        for type in measurementTypes {
            let intervals = (type == .heartRate) ? Reminder.Interval.heartRateIntervals : Reminder.Interval.stepsIntervals
            let context: IntervalContext = (type == .heartRate) ? .heartRate : .steps

            for interval in intervals {
                let key = StorageKeys.bufferKey(for: interval, type: type)

                if let defaults = sharedUserDefaults, defaults.object(forKey: key) != nil {
                    loadedValues[key] = defaults.double(forKey: key)
                } else {
                    loadedValues[key] = BufferManager.shared.buffer(for: interval, context: context)
                }
            }
        }

        self.bufferValues = loadedValues
    }
    
    private func exportToCSV(reflections: [Reflection], reminders: [Reminder]) -> URL? {
        let fileName = selectedExportDataModel.fileName
        + "_" + Date.now.formatted(.dateTime.day().month().year())
        + ExportFileFormat.csv.fileExtension
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        var rows: [[String]] = []
        
        switch selectedExportDataModel {
        case .reflection:
            // Header
            rows.append([
                "Date (Local ISO)",
                "Time (Local)",
                "Weekday",
                "Activity",
                "Subactivity",
                "Mood Emoji",
                "Mood",
                "Triggered Crash",
                "Well-being (0–4)",
                "Well-being (Label)",
                "Fatigue (0–3)",
                "Fatigue (Label)",
                "Shortness of Breath (0–3)",
                "Shortness of Breath (Label)",
                "Sleep Disorder (0–3)",
                "Sleep Disorder (Label)",
                "Cognitive Impairment (0–3)",
                "Cognitive Impairment (Label)",
                "Physical Pain (0–3)",
                "Physical Pain (Label)",
                "Depression/Anxiety (0–3)",
                "Depression/Anxiety (Label)",
                "Measurement Type",
                "Reminder Type",
                "Threshold",
                "Interval",
                "Reminder Summary",
                "Additional Info"
            ])
            
            for r in reflections {
                let date = r.date
                let dateISO = localISO8601String(from: date)
                let timeText = timeFormatter.string(from: date)
                let weekday = weekdayFormatter.string(from: date)
                
                let moodEmoji = r.mood?.emoji ?? ""
                let moodText = r.mood?.text ?? ""
                
                func val(_ v: Int?) -> String { v.map(String.init) ?? "" }
                
                let row: [String] = [
                    dateISO,
                    timeText,
                    weekday,
                    r.activity?.name ?? "",
                    r.subactivity?.name ?? "",
                    moodEmoji,
                    moodText,
                    r.didTriggerCrash ? "Yes" : "No",
                    val(r.wellBeing),
                    labelFor(.wellBeing(r.wellBeing)),
                    val(r.fatigue),
                    labelFor(.fatigue(r.fatigue)),
                    val(r.shortnessOfBreath),
                    labelFor(.shortnessOfBreath(r.shortnessOfBreath)),
                    val(r.sleepDisorder),
                    labelFor(.sleepDisorder(r.sleepDisorder)),
                    val(r.cognitiveImpairment),
                    labelFor(.cognitiveImpairment(r.cognitiveImpairment)),
                    val(r.physicalPain),
                    labelFor(.physicalPain(r.physicalPain)),
                    val(r.depressionOrAnxiety),
                    labelFor(.depressionOrAnxiety(r.depressionOrAnxiety)),
                    r.measurementType?.localized ?? "",
                    r.reminderType?.localized ?? "",
                    r.threshold.map(String.init) ?? "",
                    r.interval?.rawValue ?? "",
                    r.reminderTriggerSummary,
                    r.additionalInformation
                ]
                rows.append(row)
            }
            
        case .reminder:
            // Header
            rows.append([
                "ID",
                "Measurement Type",
                "Reminder Type",
                "Threshold",
                "Threshold Units",
                "Interval",
                "Human Summary"
            ])
            
            for rem in reminders {
                rows.append([
                    rem.id.uuidString,
                    rem.measurementType.localized,
                    rem.reminderType.localized,
                    String(rem.threshold),
                    rem.thresholdUnits,
                    rem.interval.rawValue,
                    rem.triggerSummary
                ])
            }
        }
        
        // Build CSV text (quote every field, escape quotes)
        let csvText = rows
            .map { $0.map(csvEscape).joined(separator: ",") }
            .joined(separator: "\r\n")
        
        // Prepend UTF-8 BOM to help Excel auto-detect UTF-8 (esp. emojis)
        let bom = Data([0xEF, 0xBB, 0xBF])
        do {
            var data = bom
            if let body = csvText.data(using: .utf8) {
                data.append(body)
            }
            try data.write(to: path, options: .atomic)
            return path
        } catch {
            print("Failed to create CSV file: \(error)")
            return nil
        }
    }
    
    // MARK: - CSV Helpers

    private func csvEscape(_ field: String) -> String {
        // Always quote. Escape internal quotes by doubling.
        let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    // MARK: - Formatting Helpers

    private var timeFormatter: DateFormatter {
        let df = DateFormatter()
        df.locale = .current
        df.timeZone = .current
        df.dateStyle = .none
        df.timeStyle = .short
        return df
    }

    private var weekdayFormatter: DateFormatter {
        let df = DateFormatter()
        df.locale = .current
        df.timeZone = .current
        df.dateFormat = "EEEE"
        return df
    }

    private func localISO8601String(from date: Date) -> String {
        // ISO8601 with local time zone for human-friendliness in Excel/Numbers
        let df = DateFormatter()
        df.locale = .current
        df.timeZone = .current
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX"
        return df.string(from: date)
    }

    // MARK: - Labels for Symptoms

    private func labelFor(_ symptom: Reflection.Symptom) -> String {
        switch symptom {
        case .wellBeing(let v): return labelWellBeing(v)
        default: return labelSeverity(symptom.value)
        }
    }

    private func labelWellBeing(_ value: Int?) -> String {
        switch value {
        case 0: return String(localized: "Very Low")
        case 1: return String(localized: "Low")
        case 2: return String(localized: "Moderate")
        case 3: return String(localized: "High")
        case 4: return String(localized: "Very High")
        default: return String(localized: "Not Set")
        }
    }

    private func labelSeverity(_ value: Int?) -> String {
        switch value {
        case 0: return String(localized: "Absent")
        case 1: return String(localized: "Mild")
        case 2: return String(localized: "Moderate")
        case 3: return String(localized: "Severe")
        default: return String(localized: "Not Set")
        }
    }

    private var sharedUserDefaults: UserDefaults? {
        return UserDefaults(suiteName: "group.com.MindfulPacer")
    }
    
    private func optionalIntToString(_ value: Int?) -> String {
        return value.map { "\($0)" } ?? ""
    }
}

