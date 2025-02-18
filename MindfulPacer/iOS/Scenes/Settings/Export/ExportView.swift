//
//  ExportView.swift
//  iOS
//
//  Created by Grigor Dochev on 05.02.2025.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - ExportView

struct ExportView: View {
    
    // MARK: Properties
    
    @Bindable var viewModel: SettingsViewModel
    
    // MARK: Body
    
    var body: some View {
        RoundedList {
            Section {
                exportData
                fileFormat
            }
            
            Section {
                PrimaryButton(title: "Export") {
                    viewModel.onExportTapped()
                }
            }
        }
        .fileExporter(
            isPresented: $viewModel.isExporting,
            document: viewModel.exportURL.map { ExportDocument(fileURL: $0) },
            contentType: UTType.commaSeparatedText,
            defaultFilename: viewModel.selectedExportDataModel.fileName
        ) { result in
            switch result {
            case .success(let url):
                print("File saved to: \(url)")
            case .failure(let error):
                print("Export failed: \(error.localizedDescription)")
            }
        }
        .navigationTitle("Export")
    }

    // MARK: - Export Data
    
    private var exportData: some View {
        HStack {
            IconLabel(
                icon: "externaldrive",
                title: "Data to Export",
                labelColor: .brandPrimary,
                background: true
            )
            .font(.subheadline.weight(.semibold))
            
            Spacer(minLength: 16)
            
            Picker(selection: $viewModel.selectedExportDataModel) {
                ForEach(ExportDataModel.allCases) { dataModel in
                    Label(dataModel.description, systemImage: dataModel.icon)
                        .tag(dataModel)
                }
            } label: {
                EmptyView()
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: - File Format
    
    private var fileFormat: some View {
        HStack {
            IconLabel(
                icon: "document",
                title: "File Format",
                labelColor: .brandPrimary,
                background: true
            )
            .font(.subheadline.weight(.semibold))
            
            Spacer(minLength: 16)
            
            Picker(selection: $viewModel.selectedExportFileFormat) {
                ForEach(ExportFileFormat.allCases) { fileFormat in
                    Text(fileFormat.description)
                        .tag(fileFormat)
                }
            } label: {
                EmptyView()
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
    }
}

// MARK: - Preview

#Preview {
    let viewModel: SettingsViewModel = ScenesContainer.shared.settingsViewModel()
    return ExportView(viewModel: viewModel)
}
