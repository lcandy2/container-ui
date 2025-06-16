//
//  LogsToolbar.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

struct LogsToolbar: View {
    let logSource: LogSource
    @Binding var timeFilter: String
    @Binding var lineLimit: Int
    @Binding var isStreaming: Bool
    @Binding var showLineNumbers: Bool
    @Binding var wordWrap: Bool
    let onRefresh: () -> Void
    let onExport: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Time Filter (if supported)
            if logSource.availableFilters.contains(.timeRange) {
                Text("Time:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Picker("Time Filter", selection: $timeFilter) {
                    Text("5m").tag("5m")
                    Text("1h").tag("1h")
                    Text("1d").tag("1d")
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }
            
            // Line Limit (for container logs)
            if case .container = logSource.type {
                Text("Lines:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Picker("Lines", selection: $lineLimit) {
                    Text("50").tag(50)
                    Text("100").tag(100)
                    Text("500").tag(500)
                    Text("All").tag(-1)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            
            Spacer()
            
            // View Options
            Menu {
                Toggle("Line Numbers", isOn: $showLineNumbers)
                Toggle("Word Wrap", isOn: $wordWrap)
                
                Divider()
                
                Button("Export Logs", action: onExport)
                    .keyboardShortcut("e", modifiers: [.command])
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            
            // Refresh Button
            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
            }
            .keyboardShortcut("r", modifiers: [.command])
            
            // Streaming Toggle (if supported)
            if logSource.supportsRealTime {
                Toggle("Live", isOn: $isStreaming)
                    .toggleStyle(.button)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.regularMaterial)
    }
}