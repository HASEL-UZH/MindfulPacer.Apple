//
//  DataManagementView.swift
//  iOS
//
//  Created by Grigor Dochev on 30.08.2025.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - DataManagementView

struct DataManagementView: View {
    
    // MARK: Properties
    
    @Bindable var viewModel: SettingsViewModel

    // MARK: Body
    
    var body: some View {
        List {
            exportData
            deleteData

            #if DEBUG
            debugMissedReflections
            #endif
        }
        .pickerStyle(.navigationLink)
        .fileExporter(
            isPresented: $viewModel.isExporting,
            document: viewModel.exportURL.map { ExportDocument(fileURL: $0) },
            contentType: viewModel.selectedFileUTType,
            defaultFilename: viewModel.selectedExportDataModel.fileName
        ) { result in
            switch result {
            case .success(let url): print("File saved to: \(url)")
            case .failure(let error): print("Export failed: \(error.localizedDescription)")
            }
        }
        .navigationTitle(String(localized: "Manage Data"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Export Data
    
    private var exportData: some View {
        Section {
            Picker(selection: $viewModel.selectedExportDataModel) {
                ForEach(ExportDataModel.allCases) { model in
                    Label(model.description, systemImage: model.icon).tag(model)
                }
            } label: {
                Label("Data to Export", systemImage: "tray.full.fill")
            }

            Picker(selection: $viewModel.selectedExportFileFormat) {
                ForEach(ExportFileFormat.allCases) { format in
                    Text(format.description)
                        .tag(format)
                        .disabled(!viewModel.selectedExportDataModel.allowedExportFormats.contains(format))
                }
            } label: {
                Label("File Format", systemImage: "doc.fill")
            }
            .onChange(of: viewModel.selectedExportDataModel) { _, newModel in
                if !newModel.allowedExportFormats.contains(viewModel.selectedExportFileFormat) {
                    viewModel.selectedExportFileFormat = newModel.allowedExportFormats.first ?? .csv
                }
            }

            Button {
                viewModel.onExportTapped()
            } label: {
                Label("Export Data", systemImage: "square.and.arrow.up.fill")
            }
            .foregroundStyle(Color.accentColor)
        } header: {
            Text("Export Data")
        } footer: {
            Text("Exports are created locally and shared through the system file picker.")
        }
    }
    
    // MARK: Delete Data

    private var deleteData: some View {
        Section {
            Button(role: .destructive) {
                viewModel.presentAlert(.resetDatabaseConfirmation)
            } label: {
                Label(String(localized: "Erase All Data"), systemImage: "trash")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .foregroundStyle(.red)
        } header: {
            Text("Delete Data")
        } footer: {
            Text("This permanently deletes reflections, reminders, cached health data, and settings from this device and iCloud. This action cannot be undone.")
        }
    }

    // MARK: Debug Missed Reflections

    #if DEBUG
    private var debugMissedReflections: some View {
        Section {
            Stepper(
                "Count: \(viewModel.seedMissedReflectionsCount)",
                value: $viewModel.seedMissedReflectionsCount,
                in: 5...100,
                step: 5
            )

            Button {
                viewModel.seedMockMissedReflections()
            } label: {
                Label("Seed", systemImage: "plus.circle.fill")
            }
            .foregroundStyle(Color.accentColor)

            Button(role: .destructive) {
                viewModel.deleteAllMissedReflections()
            } label: {
                Label("Delete Missed", systemImage: "trash.circle.fill")
            }
        } header: {
            Text("Debug: Missed Reflections")
        } footer: {
            Text("Inserts mock missed reflections with realistic trigger data for local testing.")
        }
    }
    #endif
}

// MARK: - Preview

#Preview {
    let viewModel: SettingsViewModel = ScenesContainer.shared.settingsViewModel()
    return NavigationStack {
        DataManagementView(viewModel: viewModel)
            .tint(Color.brandPrimary)
    }
}
