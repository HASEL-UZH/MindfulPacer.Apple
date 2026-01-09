//
//  BackgroundDiagnosticsView.swift
//  iOS
//
//  Created by Grigor Dochev on 11.12.2025.
//

import SwiftUI
import MessageUI

// MARK: - BGDebug diagnostics dump

extension BGDebug {
    nonisolated static func diagnosticsDump() -> String {
        let d = DefaultsStore.shared
        
        func string(_ key: String) -> String {
            d.object(forKey: key).map { "\($0)" } ?? "nil"
        }
        
        // Generic date formatter used everywhere
        func format(date: Date?) -> String {
            guard let date else { return "nil" }
            let formatter = DateFormatter()
            formatter.locale = .current
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        
        // From any UserDefaults-backed value (String ISO, TimeInterval, Date)
        func prettyDateFromAny(_ value: Any?) -> String {
            guard let value else { return "nil" }
            
            let date: Date?
            
            switch value {
            case let s as String:
                let iso = ISO8601DateFormatter()
                date = iso.date(from: s)
            case let ts as TimeInterval:
                date = Date(timeIntervalSince1970: ts)
            case let d as Date:
                date = d
            default:
                date = nil
            }
            
            guard let date else {
                return "\(value)"
            }
            
            return format(date: date)
        }
        
        func prettyDateValue(_ key: String) -> String {
            guard let value = d.object(forKey: key) else {
                return "nil"
            }
            return prettyDateFromAny(value)
        }
        
        func prettyDateDirect(_ date: Date?) -> String {
            format(date: date)
        }
        
        func prettyDateFromISO(_ isoString: String?) -> String {
            guard let isoString else { return "nil" }
            let iso = ISO8601DateFormatter()
            let date = iso.date(from: isoString)
            return format(date: date)
        }
        
        // Load full history (oldest → newest) and then sort here
        let history = BGDebug.loadHistory()
        
        let historyLines: String = history
            .sorted(by: { $0.createdAt > $1.createdAt }) // newest first
            .enumerated()
            .map { index, entry in
                let entryNumber = index + 1
                let created = format(date: entry.createdAt)
                let start = prettyDateFromISO(entry.lastRunStart)
                let end   = prettyDateFromISO(entry.lastRunEnd)
                
                let result = entry.lastResult ?? "nil"
                let error  = entry.lastError ?? "nil"
                let found  = entry.lastFound
                
                let decision = entry.lastNotifyDecision ?? "nil"
                let reason   = entry.lastNotifyReason ?? "nil"
                
                return """
                [\(entryNumber)] at \(created)
                  start: \(start)
                  end:   \(end)
                  result: \(result)
                  error:  \(error)
                  found:  \(found)
                  notifyDecision: \(decision)
                  notifyReason:   \(reason)
                """
            }
            .joined(separator: "\n\n")
        
        return """
        [MindfulPacer Background Diagnostics]

        ### General (current snapshot)
        lastSchedule       = \(prettyDateValue(Keys.lastSchedule))
        lastRunStart       = \(prettyDateValue(Keys.lastRunStart))
        lastRunEnd         = \(prettyDateValue(Keys.lastRunEnd))
        lastResult         = \(string(Keys.lastResult))
        lastError          = \(string(Keys.lastError))
        runsCount          = \(d.integer(forKey: Keys.runsCount))

        ### Missed Reflections (current snapshot)
        lastFound          = \(d.integer(forKey: Keys.lastFound))

        ### Notification Throttle (current snapshot)
        lastNotifyDateISO  = \(prettyDateValue(Keys.lastNotifyDateISO))
        lastNotifyCount    = \(string(Keys.lastNotifyCount))
        lastNotifyDecision = \(string(Keys.lastNotifyDecision))
        lastNotifyReason   = \(string(Keys.lastNotifyReason))

        DeviceMode         = \(DeviceMode.current(from: DefaultsStore.shared))
        GeneratedAt        = \(prettyDateDirect(Date()))

        ### History (most recent first)
        \(historyLines.isEmpty ? "No history yet." : historyLines)
        """
    }
}

// MARK: - Diagnostics View

struct BackgroundDiagnosticsView: View {
    private let supportEmail = "grigor.dochev@uzh.ch"
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
    @State private var showMail = false
    @State private var showCopyAlert = false
    @State private var showInfoSheet = false
    
    private var diagnostics: String { BGDebug.diagnosticsDump() }
    
    var body: some View {
        VStack(alignment: .leading) {
            IconLabelGroupBox(
                label:
                    IconLabel(
                        icon: "ellipsis.curlybraces",
                        title: "Diagnostics",
                        labelColor: .accent, background: true
                    )
            ) {
                Text(diagnostics)
                    .font(.system(.footnote, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } footer: {
                HStack {
                    Button {
                        UIPasteboard.general.string = diagnostics
                        showCopyAlert = true
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc.fill")
                            .font(.footnote.weight(.semibold))
                    }
                    
                    Spacer()
                    
                    Button {
                        if MFMailComposeViewController.canSendMail() {
                            showMail = true
                        } else {
                            UIPasteboard.general.string = diagnostics
                            showCopyAlert = true
                        }
                    } label: {
                        Label("Send via Email", systemImage: "envelope.fill")
                            .font(.footnote.weight(.semibold))
                    }
                }
            }
            .iconLabelGroupBoxStyle(.divider)
            .padding(.horizontal)
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("BG Diagnostics")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showInfoSheet = true
                } label: {
                    Image(systemName: "info")
                }
            }
        }
        .sheet(isPresented: $showMail) {
            MailView(
                result: $mailResult,
                recipient: supportEmail,
                subject: "MindfulPacer BG Diagnostics",
                body: diagnostics
            )
        }
        .sheet(isPresented: $showInfoSheet) {
            DiagnosticsInfoSheet()
        }
        .alert("Diagnostics copied", isPresented: $showCopyAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("""
            Diagnostics were copied to your clipboard.

            If Mail is not set up, please paste them into an email and send to:
            \(supportEmail)
            """)
        }
    }
}

// MARK: - Info Sheet

struct DiagnosticsInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    Group {
                        info("lastSchedule", "The last time a BGAppRefreshTaskRequest was successfully submitted.")
                        info("lastRunStart", "When the system actually started running the background task.")
                        info("lastRunEnd", "When the task finished (successfully or with failure).")
                        info("lastResult", "Outcome of the last run: success(count), failure, or skipped due to mode.")
                        info("lastError", "Any error thrown during the task execution or scheduling.")
                        info("runsCount", "Number of times the task has run since installation.")
                    }
                    
                    Divider().padding(.vertical, 8)
                    
                    Group {
                        info("lastFound", "How many missed reflections the pipeline detected last run.")
                    }
                    
                    Divider().padding(.vertical, 8)
                    
                    Group {
                        info("lastNotifyDateISO", "When the last notification was successfully posted.")
                        info("lastNotifyCount", "The count value that triggered the last notification.")
                        info("lastNotifyDecision", """
                            A high-level label describing whether notification was sent:
                            - notification_sent
                            - no_notification
                            - no_run
                            - throttled
                            - failure
                            """)
                        info("lastNotifyReason", "Explains *why* a notification was or wasn’t sent.")
                    }
                    
                    Divider().padding(.vertical, 8)
                    
                    Group {
                        info("DeviceMode", "The current mode (iPhoneOnly or Watch mode), which controls whether background tasks should run.")
                        info("GeneratedAt", "When this diagnostics snapshot was created.")
                    }
                }
                .padding()
            }
            .navigationTitle("Diagnostics Info")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
    
    private func info(_ title: String, _ description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        BackgroundDiagnosticsView()
    }
}
