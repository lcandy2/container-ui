//
//  SystemInspectorView.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

struct SystemInspectorView: View {
    @ObservedObject var containerService: ContainerService
    @State private var newDomainName = ""
    @State private var showingAddDomainAlert = false
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        List {
            Section("System Status") {
                if let systemInfo = containerService.systemInfo {
                    LabeledContent("Service Status") {
                        HStack {
                            Circle()
                                .fill(systemInfo.serviceStatus.color)
                                .frame(width: 8, height: 8)
                            Text(systemInfo.serviceStatus.displayName)
                        }
                    }
                } else {
                    Text("Loading system information...")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("System Actions") {
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
            }
            
            Section("DNS Management") {
                if let systemInfo = containerService.systemInfo {
                    if systemInfo.dnsSettings.isEmpty {
                        Text("No DNS domains configured")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(systemInfo.dnsSettings) { domain in
                            HStack {
                                Text(domain.domain)
                                
                                Spacer()
                                
                                if domain.isDefault {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                }
                            }
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
                    
                    Button("Add DNS Domain") {
                        showingAddDomainAlert = true
                    }
                } else {
                    Text("Loading DNS settings...")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("System Logs") {
                Button("View System Logs") {
                    let logSource = containerService.createSystemLogSource()
                    openWindow(id: "universal-logs", value: logSource.id)
                }
            }
        }
        .navigationTitle("System")
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