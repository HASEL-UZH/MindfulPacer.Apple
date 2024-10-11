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
        
        @Bindable var viewModel: SettingsViewModel
        
        // MARK: Body
        
        var body: some View {
            NavigationStack {
                VStack {
                    IconLabelGroupBox(
                        label:
                            IconLabel(
                                icon: "iphone.gen3",
                                title: "Details",
                                labelColor: Color("BrandPrimary"),
                                background: true
                            ),
                        description:
                            Text("Share this report to help us troubleshoot issues.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    ) {
                        infoCell(
                            title: "App Version",
                            value: viewModel.appVersion
                        )
                        infoCell(
                            title: "System Version",
                            value: viewModel.systemVersion
                        )
                        infoCell(
                            title: "Screen Size",
                            value: viewModel.screenSize
                        )
                        infoCell(
                            title: "Model Name",
                            value: viewModel.modelName
                        )
                    }
                    .iconLabelGroupBoxStyle(.divider)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    systemReportShareLink
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("System Report")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        CloseButton()
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
            HStack {
                Text(title)
                Spacer()
                Text(value)
                    .foregroundStyle(.secondary)
            }
        }
        
        // MARK: System Report Share Link
        
        private var systemReportShareLink: some View {
            ShareLink(item: viewModel.generateSystemReport()) {
                IconLabel(
                    icon: "square.and.arrow.up.fill",
                    title: "Share System Report",
                    labelColor: .white
                )
                .frame(height: 40)
                .frame(maxWidth: .infinity)
                .fontWeight(.semibold)
            }
            .tint(Color("BrandPrimary"))
            .buttonBorderShape(.roundedRectangle(radius: 16))
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: SettingsViewModel = ScenesContainer.shared.settingsViewModel()
    
    SettingsView.SystemReportView(viewModel: viewModel)
}
