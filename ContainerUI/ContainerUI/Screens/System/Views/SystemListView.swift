//
//  SystemListView.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI
import ContainerModels

struct SystemListView: View {
    @Environment(ContainerService.self) private var containerService
    @Environment(\.openWindow) private var openWindow
    @State private var newDomainName = ""
    @State private var showingAddDomainAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // System Status Overview
                SystemStatusCard(systemInfo: containerService.systemInfo)
                
                // System Controls
                VStack(alignment: .leading, spacing: 16) {
                    Text("System Controls")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Button("Start System") {
                                Task {
                                    do {
                                        try await containerService.startSystem()
                                        await containerService.refreshSystemInfo()
                                    } catch {
                                        print("Failed to start system: \(error)")
                                    }
                                }
                            }
                            .disabled(containerService.systemInfo?.serviceStatus == .running)
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                            
                            Button("Stop System") {
                                Task {
                                    do {
                                        try await containerService.stopSystem()
                                        await containerService.refreshSystemInfo()
                                    } catch {
                                        print("Failed to stop system: \(error)")
                                    }
                                }
                            }
                            .disabled(containerService.systemInfo?.serviceStatus != .running)
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)
                        }
                        
                        Button("Restart System") {
                            Task {
                                do {
                                    try await containerService.restartSystem()
                                    await containerService.refreshSystemInfo()
                                } catch {
                                    print("Failed to restart system: \(error)")
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                
                // DNS Management
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("DNS Management")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button("Add Domain") {
                            showingAddDomainAlert = true
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if let systemInfo = containerService.systemInfo {
                        if systemInfo.dnsSettings.isEmpty {
                            Text("No DNS domains configured")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(systemInfo.dnsSettings) { domain in
                                    HStack {
                                        Text(domain.domain)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        if domain.isDefault {
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)
                                                .font(.caption)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                                    .contextMenu {
                                        if !domain.isDefault {
                                            Button("Set as Default") {
                                                Task {
                                                    do {
                                                        try await containerService.setDefaultDNSDomain(domain.domain)
                                                        await containerService.refreshSystemInfo()
                                                    } catch {
                                                        print("Failed to set default domain: \(error)")
                                                    }
                                                }
                                            }
                                        }
                                        
                                        Button("Delete", role: .destructive) {
                                            Task {
                                                do {
                                                    try await containerService.deleteDNSDomain(domain.domain)
                                                    await containerService.refreshSystemInfo()
                                                } catch {
                                                    print("Failed to delete domain: \(error)")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        Text("Loading DNS settings...")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                
                // System Logs
                VStack(alignment: .leading, spacing: 16) {
                    Text("System Logs")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Button("View System Logs") {
                        let logSource = containerService.createSystemLogSource()
                        openWindow(id: "universal-logs", value: logSource.id)
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button("Refresh") {
                    Task { @MainActor in
                        await containerService.refreshSystemInfo()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .alert("Add DNS Domain", isPresented: $showingAddDomainAlert) {
            TextField("Domain name", text: $newDomainName)
            Button("Cancel", role: .cancel) {
                newDomainName = ""
            }
            Button("Add") {
                Task {
                    do {
                        try await containerService.createDNSDomain(newDomainName)
                        await containerService.refreshSystemInfo()
                        newDomainName = ""
                    } catch {
                        print("Failed to create domain: \(error)")
                    }
                }
            }
            .disabled(newDomainName.isEmpty)
        } message: {
            Text("Enter a DNS domain name to add to the system.")
        }
    }
}