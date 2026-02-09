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
                title: "Export Data",
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
                    title: "Note",
                    description: String("You can delete all data in this app and start from fresh."),
                    title: String(localized: "Note"),
                    iconColor: .yellow
                )
            }
        } footer: {
            Button {
                viewModel.presentAlert(.resetDatabaseConfirmation)
            } label: {
                IconLabel(title: "Erase all Data", labelColor: .red)
                IconLabel(title: String(localized: "Erase all Data"), labelColor: .red)
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    let viewModel: SettingsViewModel = ScenesContainer.shared.settingsViewModel()
    return NavigationStack {
        DataManagementView(viewModel: viewModel)
            .tint(Color.brandPrimary)
    }
}
