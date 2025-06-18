//
//  SystemInspectorView.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI
import ContainerModels

struct SystemInspectorView: View {
    @Environment(ContainerService.self) private var containerService
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        List {
            Section("System Information") {
                if let systemInfo = containerService.systemInfo {
                    LabeledContent("Service Status") {
                        HStack {
                            Circle()
                                .fill(systemInfo.serviceStatus.color)
                                .frame(width: 8, height: 8)
                            Text(systemInfo.serviceStatus.displayName)
                        }
                    }
                    
                    LabeledContent("DNS Domains", value: "\(systemInfo.dnsSettings.count)")
                    
                    if let kernelInfo = systemInfo.kernelInfo {
                        LabeledContent("Kernel Version") {
                            Text(kernelInfo)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                } else {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Loading system information...")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section("DNS Configuration") {
                if let systemInfo = containerService.systemInfo {
                    if systemInfo.dnsSettings.isEmpty {
                        Text("No DNS domains configured")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(systemInfo.dnsSettings) { domain in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(domain.domain)
                                        .font(.headline)
                                    
                                    if domain.isDefault {
                                        Text("Default Domain")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if domain.isDefault {
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundStyle(.yellow)
                                }
                            }
                        }
                    }
                } else {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Loading DNS configuration...")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section("Diagnostics") {
                Button("View System Logs") {
                    let logSource = containerService.createSystemLogSource()
                    openWindow(id: "universal-logs", value: logSource.id)
                }
                
                Button("Refresh System Info") {
                    Task {
                        await containerService.refreshSystemInfo()
                    }
                }
            }
        }
        .navigationTitle("System Inspector")
    }
}

#Preview {
    SystemInspectorView()
} 