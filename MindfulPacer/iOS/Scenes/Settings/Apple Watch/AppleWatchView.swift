//
//  AppleWatchView.swift
//  iOS
//
//  Created by Grigor Dochev on 12.08.2025.
//

import SwiftUI

// MARK: - AppleWatchView

extension SettingsView {
    struct AppleWatchView: View {
        
        // MARK: Properties
        
        @Environment(\.openURL) private var openURL
        @Bindable var viewModel: SettingsViewModel
        
        @ObservedObject private var logs = LiveLogsStore.shared
        @State private var filter = ""
        @State private var isExporting = false
        @State private var exportURL: URL?
        
        // MARK: Body
        
        var body: some View {
            if viewModel.isWatchAppInstalled {
                RoundedList {
                    Section {
                        IconLabelGroupBox(
                            label: IconLabel(
                                icon: "antenna.radiowaves.left.and.right",
                                title: "Connection",
                                labelColor: Color("BrandPrimary"),
                                background: true
                            ),
                            description: Text("Live status of the connection to your Apple Watch.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        ) {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Connection Status")
                                    Spacer()
                                    IconLabel(
                                        icon: viewModel.watchConnectionStatus.symbolName,
                                        title: viewModel.watchConnectionStatus.rawValue,
                                        labelColor: viewModel.watchConnectionStatus.color
                                    )
                                    .font(.subheadline.weight(.semibold))
                                }
                                
                                HStack {
                                    Text("Connection Speed")
                                    Spacer()
                                    IconLabel(
                                        icon: viewModel.watchConnectionSpeed.symbolName,
                                        title: viewModel.watchConnectionSpeed.rawValue,
                                        labelColor: viewModel.watchConnectionSpeed.color
                                    )
                                    .font(.subheadline.weight(.semibold))
                                }
                            }
                        }
                        .iconLabelGroupBoxStyle(.divider)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Section {
                        IconLabelGroupBox(
                            label: IconLabel(
                                icon: "doc.text.magnifyingglass",
                                title: "Live Logs",
                                labelColor: .blue,
                                background: true
                            ),
                            description: Text("Streamed from Apple Watch in real time for troubleshooting.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        ) {
                            VStack(spacing: 12) {
                                
                                // Controls
                                HStack(spacing: 8) {
                                    TextField("Filter…", text: $filter)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.subheadline)
                                    
                                    Button("Clear") {
                                        logs.clear()
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.red)
                                }
                                
                                // List
                                LogsTextListView(lines: filteredLines)
                                
                                // Export
                                HStack(spacing: 12) {
                                    Button {
                                        do {
                                            let url = try logs.export()
                                            exportURL = url
                                            isExporting = true
                                        } catch {
                                            // no-op; keep UI simple
                                        }
                                    } label: {
                                        Label("Export .log", systemImage: "square.and.arrow.up")
                                    }
                                    .buttonStyle(.borderedProminent)
                                    
                                    Text("\(logs.lines.count) lines")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .iconLabelGroupBoxStyle(.divider)
                    }
                }
                .navigationTitle("Apple Watch")
                .sheet(isPresented: $isExporting) {
                    if let url = exportURL {
                        ShareLink(item: url) { Text("Share Log File") }
                            .presentationDetents([.medium])
                            .padding()
                    }
                }
                .onAppear {
                    ConnectivityService.shared.startPinging()
                }
                .onDisappear {
                    ConnectivityService.shared.stopPinging()
                }
            } else {
                ContentUnavailableView {
                    Label("App Not Installed", systemImage: "exclamationmark.applewatch")
                } description: {
                    Text("The Apple Watch app needs to be installed. Please install it from the Watch app on your iPhone.")
                } actions: {
                    Button {
                        openURL(viewModel.appleWatchInstallationHelp)
                    } label: {
                        Text("How to Install")
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                }
                .navigationTitle("Apple Watch")
                .background {
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()
                }
            }
        }
        
        private var filteredLines: [String] {
            guard !filter.isEmpty else { return logs.lines }
            return logs.lines.filter { $0.localizedCaseInsensitiveContains(filter) }
        }
    }
}

// MARK: - LogsTextListView

private struct LogsTextListView: View {
    let lines: [String]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(lines.indices, id: \.self) { idx in
                        Text(lines[idx])
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(idx)
                    }
                }
                .padding(.vertical, 4)
                .onChange(of: lines.count) { _, _ in
                    if let last = lines.indices.last {
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }
            }
            .frame(maxHeight: 360)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
}

// MARK: - Previewo

#Preview {
    let viewModel: SettingsViewModel = ScenesContainer.shared.settingsViewModel()
    
    NavigationStack {
        SettingsView.AppleWatchView(viewModel: viewModel)
    }
}
