//
//  UniversalLogsWindow.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI
import ContainerModels

struct UniversalLogsWindow: View {
    let logSourceId: String
    @StateObject private var containerService = ContainerService()
    @Environment(\.openWindow) private var openWindow
    
    private var logSource: LogSource? {
        // Reconstruct the LogSource from the ID
        let components = logSourceId.components(separatedBy: "-")
        guard !components.isEmpty else { return nil }
        
        switch components[0] {
        case "container":
            guard components.count > 1 else { return nil }
            let containerID = components.dropFirst().joined(separator: "-")
            // Find container by ID to create LogSource
            if let container = containerService.containers.first(where: { $0.containerID == containerID }) {
                return containerService.createContainerLogSource(for: container)
            }
        case "boot":
            guard components.count > 1 else { return nil }
            let containerID = components.dropFirst().joined(separator: "-")
            if let container = containerService.containers.first(where: { $0.containerID == containerID }) {
                return containerService.createContainerBootLogSource(for: container)
            }
        case "system":
            return containerService.createSystemLogSource()
        default:
            break
        }
        return nil
    }
    
    @State private var logs = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var timeFilter = "5m"
    @State private var lineLimit = 100
    @State private var isStreaming = false
    @State private var showLineNumbers = false
    @State private var wordWrap = true
    
    var body: some View {
        NavigationStack {
            if let logSource = logSource {
                VStack(spacing: 0) {
                    // Toolbar
                    LogsToolbar(
                        logSource: logSource,
                        timeFilter: $timeFilter,
                        lineLimit: $lineLimit,
                        isStreaming: $isStreaming,
                        showLineNumbers: $showLineNumbers,
                        wordWrap: $wordWrap,
                        onRefresh: { Task { await loadLogs() } },
                        onExport: { exportLogs() }
                    )
                    
                    Divider()
                    
                    // Main Content
                    if isLoading {
                        VStack {
                            ProgressView("Loading \(logSource.type.displayName.lowercased())...")
                                .controlSize(.large)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        LogsContentView(
                            logs: filteredLogs,
                            showLineNumbers: showLineNumbers,
                            wordWrap: wordWrap
                        )
                    }
                    
                    // Status Bar
                    LogsStatusBar(
                        logSource: logSource,
                        lineCount: filteredLogs.components(separatedBy: .newlines).count,
                        isStreaming: isStreaming,
                        lastUpdated: Date()
                    )
                }
                .navigationTitle(logSource.title)
                .searchable(text: $searchText, prompt: "Search logs...")
                .task {
                    await containerService.refreshContainers() // Ensure containers are loaded
                    await loadLogs()
                }
                .onChange(of: timeFilter) { _, _ in
                    Task { await loadLogs() }
                }
                .onChange(of: lineLimit) { _, _ in
                    Task { await loadLogs() }
                }
            } else {
                ContentUnavailableView(
                    "Invalid Log Source",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Unable to load log source with ID: \(logSourceId)")
                )
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    private var filteredLogs: String {
        guard !searchText.isEmpty else { return logs }
        
        let lines = logs.components(separatedBy: .newlines)
        let filteredLines = lines.filter { line in
            line.localizedCaseInsensitiveContains(searchText)
        }
        return filteredLines.joined(separator: "\n")
    }
    
    private func loadLogs() async {
        guard let logSource = logSource else {
            await MainActor.run {
                errorMessage = "Invalid log source"
                isLoading = false
            }
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let timeFilterValue = logSource.availableFilters.contains(.timeRange) ? timeFilter : nil
            let lineValue: Int? = if case .containerBoot = logSource.type { nil } else { lineLimit }
            
            let result = try await containerService.fetchLogs(
                for: logSource,
                timeFilter: timeFilterValue,
                lines: lineValue
            )
            
            await MainActor.run {
                logs = result
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load logs: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    private func exportLogs() {
        // TODO: Implement export functionality
        print("Export logs for \(logSourceId)")
    }
}
