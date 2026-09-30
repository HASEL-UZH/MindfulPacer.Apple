//
//  SystemReportView.swift
//  iOS
//
//  Created by Grigor Dochev on 09.10.2024.
//

import SwiftUI

// MARK: - SystemReportView

extension SettingsView {
    struct SystemReportView: View {
        
        // MARK: Properties
        
        @Environment(\.dismiss) private var dismiss
        @Bindable var viewModel: SettingsViewModel
        
        // MARK: Body
        
        var body: some View {
            NavigationStack {
                List {
                    Section {
                        infoCell(title: "App Version", value: viewModel.appVersion)
                        infoCell(title: "System Version", value: viewModel.systemVersion)
                        infoCell(title: "Screen Size", value: viewModel.screenSize)
                        infoCell(title: "Model Name", value: viewModel.modelName)
                    } header: {
                        Text("Details")
                    } footer: {
                        Text("Share this report to help us troubleshoot issues.")
                    }

                    Section {
                        systemReportShareButton
                    }
                }
                .navigationTitle("System Report")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
        
        // MARK: Info Cell
        
        @ViewBuilder
        func infoCell(
            title: String,
            value: String
        ) -> some View {
            LabeledContent {
                Text(value)
                    .foregroundStyle(Color.secondary)
                    .textSelection(.enabled)
            } label: {
                Text(title)
            }
        }
        
        // MARK: System Report Share Button
        
        private var systemReportShareButton: some View {
            Button {
                viewModel.presentSheet(
                    .mailView(
                        recipient: viewModel.contactSupportRecipient,
                        subject: viewModel.contactSupportSubject,
                        body: viewModel.systemReport
                    )
                )
            } label: {
                Label("Share System Report", systemImage: "square.and.arrow.up.fill")
            }
            .foregroundStyle(Color.accentColor)
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: SettingsViewModel = ScenesContainer.shared.settingsViewModel()
    
    SettingsView.SystemReportView(viewModel: viewModel)
}
