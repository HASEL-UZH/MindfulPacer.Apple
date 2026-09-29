//
//  RootView.swift
//  WatchOS
//
//  Created by Grigor Dochev on 09.08.2025.
//

import SwiftUI
import SwiftData

struct ActivitySelectionInfo: Identifiable {
    let id: UUID
    let reminderID: UUID
}

@MainActor
class NavigationManager: ObservableObject {
    @Published var pendingActivitySelection: ActivitySelectionInfo?
    init() {}
}

extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}

struct RootView: View {
    @State private var viewModel: HomeViewModel

    init() {
        #if DEBUG && targetEnvironment(simulator)
        _viewModel = State(initialValue: WatchDesignPreview.isEnabled ? WatchDesignPreview.makeViewModel() : HomeViewModel())
        #else
        _viewModel = State(initialValue: HomeViewModel())
        #endif
    }

    var body: some View {
        HomeView(viewModel: viewModel)
    }
}

#Preview {
    RootView()
}

#if DEBUG && targetEnvironment(simulator)
/// Opt-in, isolated simulator data for visually checking the Watch redesign.
@MainActor
enum WatchDesignPreview {
    static var isEnabled: Bool { ProcessInfo.processInfo.arguments.contains("-watch-design-preview") }
    static var scenario: String {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-watch-scenario"), arguments.indices.contains(index + 1) else { return "home" }
        return arguments[index + 1]
    }
    static let container: ModelContainer = {
        let schema = Schema(CurrentScheme.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try! ModelContainer(for: schema, configurations: [config])
        if scenario != "activities-empty" {
            for activity in DefaultActivityData.allActivities { container.mainContext.insert(activity) }
            try! container.mainContext.save()
        }
        return container
    }()

    static func makeViewModel() -> HomeViewModel {
        let model = HomeViewModel.mock
        switch scenario {
        case "heart-rate": model.selectedTab = .heartRateChart
        case "steps": model.selectedTab = .stepsChart
        case "empty-heart-rate", "permission":
            model.heartRateSamples = []
            model.selectedTab = .heartRateChart
            if scenario == "permission" { model.statusMessage = .permissionDenied }
        case "empty-steps":
            model.hourlyStepData = []
            model.selectedTab = .stepsChart
        case "single-heart-rate":
            model.heartRateSamples = [(85, .now)]
            model.selectedTab = .heartRateChart
        case "paused": model.togglePauseResume()
        case "no-reminders": model.activeRules = []; model.statusMessage = .noReminders; model.isMonitoring = false
        case "highlight-light", "highlight-medium", "highlight-strong":
            let severity: Reminder.ReminderType = scenario == "highlight-light" ? .light : (scenario == "highlight-medium" ? .medium : .strong)
            for rule in model.activeRules where rule.reminderType == severity {
                model.widgetHighlights.recordTrigger(for: rule.highlightRule, at: .now)
            }
            model.heartRate = 115
        case "alert", "activities-empty":
            model.alertState = .showing(rule: model.activeRules[0], alertID: UUID())
        default: break
        }
        return model
    }
}
#endif
