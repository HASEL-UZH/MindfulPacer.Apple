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
        ScrollView {
            VStack(spacing: 16) {
                exportData
                deleteData

                #if DEBUG
                debugMissedReflections
                #endif
            }
        }
        .background(Color(.systemGroupedBackground))
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
        .alert(String(localized: "Delete All Data?"), isPresented: $viewModel.isShowingDeleteAllDataAlert) {
            Button(String(localized: "Cancel"), role: .cancel) {}
            Button(String(localized: "Delete"), role: .destructive) {
                viewModel.confirmDeleteAllUserData()
            }
        } message: {
            Text(String(localized: "This will permanently remove your reflections, reminders, cached health data, and settings from this device. This action cannot be undone."))
        }
        .navigationTitle(String(localized: "Manage Data"))
    }

    // MARK: Export Data
    
    private var exportData: some View {
        IconLabelGroupBox(
            label: IconLabel(
                icon: "tray.and.arrow.up.fill",
                title: String(localized: "Export Data"),
                labelColor: .brandPrimary,
                background: true
            )
        ) {
            VStack(spacing: 16) {
                HStack {
                    Text("Data Model")
                    
                    Spacer()
                    
                    Picker(selection: $viewModel.selectedExportDataModel) {
                        ForEach(ExportDataModel.allCases) { model in
                            Label(model.description, systemImage: model.icon).tag(model)
                        }
                    } label: { Text("Label") }
                }
                
                HStack {
                    Text("File Type")
                    
                    Spacer()
                    
                    Picker(selection: $viewModel.selectedExportFileFormat) {
                        ForEach(ExportFileFormat.allCases) { format in
                            Text(format.description)
                                .tag(format)
                                .disabled(!viewModel.selectedExportDataModel.allowedExportFormats.contains(format))
                        }
                    } label: { EmptyView() }
                        .onChange(of: viewModel.selectedExportDataModel) { _, newModel in
                            if !newModel.allowedExportFormats.contains(viewModel.selectedExportFileFormat) {
                                viewModel.selectedExportFileFormat = newModel.allowedExportFormats.first ?? .csv
                            }
                        }
                }
            }
        } footer: {
            Button {
                viewModel.onExportTapped()
            } label: {
                IconLabel(title: "Export", labelColor: .brandPrimary)
                    .font(.subheadline.weight(.semibold))
            }
        }
        .iconLabelGroupBoxStyle(.divider)
        .padding(.horizontal)
    }
    
    // MARK: Delete Data

    private var deleteData: some View {
        IconLabelGroupBox(
            label: IconLabel(
                icon: "trash",
                title: "Delete Data",
                labelColor: .red,
                background: true
            )
        ) {
            Card(backgroundColor: Color(.tertiarySystemGroupedBackground)) {
                IconLabel(
                    icon: "exclamationmark.triangle",
                    title: String(localized: "Note"),
                    description: String(localized: "You can delete all data in this app and start from fresh."),
                    iconColor: .yellow
                )
            }
        } footer: {
            Button {
                viewModel.presentAlert(.resetDatabaseConfirmation)
            } label: {
                IconLabel(title: String(localized: "Erase all Data"), labelColor: .red)
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding(.horizontal)
    }

    // MARK: Debug Missed Reflections

    #if DEBUG
    private var debugMissedReflections: some View {
        IconLabelGroupBox(
            label: IconLabel(
                icon: "ladybug.fill",
                title: "Debug: Missed Reflections",
                labelColor: .purple,
                background: true
            )
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Stepper("Count: \(viewModel.seedMissedReflectionsCount)",
                        value: $viewModel.seedMissedReflectionsCount,
                        in: 5...100,
                        step: 5)

                Text("Inserts mock missed reflections with realistic trigger data (HR & steps, mixed severity).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } footer: {
            HStack(spacing: 16) {
                Button {
                    viewModel.seedMockMissedReflections()
                } label: {
                    Label("Seed", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.purple)
                }

                Button {
                    viewModel.deleteAllMissedReflections()
                } label: {
                    Label("Delete Missed", systemImage: "trash.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.red)
                }
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal)
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
