//
//  ActiveRemindersView.swift
//  WatchOS
//
//  Created by Grigor Dochev on 10.08.2025.
//

import SwiftUI

struct ActiveRemindersView: View {
    @State private var viewModel = ActiveRemindersViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.activeRules.isEmpty {
                    VStack {
                        Image(systemName: "checklist.unchecked")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No Active Reminders")
                            .font(.headline)
                        Text("Create a heart rate reminder on your iPhone to begin monitoring.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    List(viewModel.activeRules, id: \.id) { rule in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Alert If Above")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.secondary)
                            HStack {
                                Image(systemName: "alarm.fill")
                                    .foregroundStyle(rule.type.color)
                                
                                HStack(alignment: .firstTextBaseline) {
                                    Text("\(Int(rule.thresholdBPM))")
                                        .font(.title.weight(.semibold))
                                        .foregroundColor(.primary)
                                    Text("bpm")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Text(rule.alertMessage)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Active Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
#Preview {
    ActiveRemindersView()
}
