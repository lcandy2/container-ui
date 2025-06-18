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
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationStack {
            List {
                // System Status Section
                Section {
                    SystemStatusCard(systemInfo: containerService.systemInfo)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                
                // System Controls Section
                Section("System Controls") {
                    systemControlsContent
                }
                
                // DNS Management Section
                Section {
                    dnsManagementContent
                } header: {
                    HStack {
                        Text("DNS Management")
                        Spacer()
                        Button("Add Domain", systemImage: "plus") {
                            showingAddDomainAlert = true
                        }
                        .buttonStyle(.borderless)
                    }
                }
                
                // System Logs Section
                Section("System Logs") {
                    systemLogsContent
                }
            }
            .navigationTitle("System")
            .refreshable {
                await refreshSystemInfo()
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await refreshSystemInfo() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isRefreshing)
                }
            }
            .alert("Add DNS Domain", isPresented: $showingAddDomainAlert) {
                TextField("example.com", text: $newDomainName)
                    .autocorrectionDisabled()
                
                Button("Cancel", role: .cancel) {
                    newDomainName = ""
                }
                
                Button("Add") {
                    Task { await addDNSDomain() }
                }
                .disabled(newDomainName.isEmpty || !isValidDomain(newDomainName))
            } message: {
                Text("Enter a DNS domain name to add to the system configuration.")
            }
        }
    }
    
    // MARK: - System Controls Content
    
    private var systemControlsContent: some View {
        HStack(spacing: 8) {
            Button {
                Task { await performSystemAction { 
                    try await containerService.startSystem()
                }}
            } label: {
                Label("Start", systemImage: "play.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(containerService.systemInfo?.serviceStatus == .running)
            
            Button {
                Task { await performSystemAction { 
                    try await containerService.stopSystem()
                }}
            } label: {
                Label("Stop", systemImage: "stop.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(containerService.systemInfo?.serviceStatus != .running)
            
            Button {
                Task { await performSystemAction { 
                    try await containerService.restartSystem()
                }}
            } label: {
                Label("Restart", systemImage: "arrow.clockwise.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
    }
    
    // MARK: - DNS Management Content
    
    private var dnsManagementContent: some View {
        Group {
            if let systemInfo = containerService.systemInfo {
                if systemInfo.dnsSettings.isEmpty {
                    ContentUnavailableView(
                        "No DNS Domains",
                        systemImage: "network.slash",
                        description: Text("Add a domain to enable container DNS resolution.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(systemInfo.dnsSettings) { domain in
                        dnsDomainRow(domain)
                    }
                }
            } else {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading DNS settings...")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private func dnsDomainRow(_ domain: DNSDomain) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(domain.domain)
                        .font(.headline)
                    
                    if domain.isDefault {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }
                
                if domain.isDefault {
                    Text("Default Domain")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Menu {
                if !domain.isDefault {
                    Button {
                        Task { await setDefaultDomain(domain.domain) }
                    } label: {
                        Label("Set as Default", systemImage: "star")
                    }
                    
                    Divider()
                }
                
                Button(role: .destructive) {
                    Task { await deleteDomain(domain.domain) }
                } label: {
                    Label("Delete Domain", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
        }
    }
    
    // MARK: - System Logs Content
    
    private var systemLogsContent: some View {
        Button {
            let logSource = containerService.createSystemLogSource()
            openWindow(id: "universal-logs", value: logSource.id)
        } label: {
            HStack {
                Label("View System Logs", systemImage: "doc.text")
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "arrow.up.right.square")
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }
    
    // MARK: - Helper Methods
    
    private func refreshSystemInfo() async {
        isRefreshing = true
        await containerService.refreshSystemInfo()
        isRefreshing = false
    }
    
    private func performSystemAction(_ action: () async throws -> Void) async {
        do {
            try await action()
            await containerService.refreshSystemInfo()
        } catch {
            print("System action failed: \(error)")
        }
    }
    
    private func addDNSDomain() async {
        do {
            try await containerService.createDNSDomain(newDomainName)
            await containerService.refreshSystemInfo()
            newDomainName = ""
        } catch {
            print("Failed to create domain: \(error)")
        }
    }
    
    private func setDefaultDomain(_ domain: String) async {
        do {
            try await containerService.setDefaultDNSDomain(domain)
            await containerService.refreshSystemInfo()
        } catch {
            print("Failed to set default domain: \(error)")
        }
    }
    
    private func deleteDomain(_ domain: String) async {
        do {
            try await containerService.deleteDNSDomain(domain)
            await containerService.refreshSystemInfo()
        } catch {
            print("Failed to delete domain: \(error)")
        }
    }
    
    private func isValidDomain(_ domain: String) -> Bool {
        let regex = "^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\\.[a-zA-Z]{2,}$"
        return domain.range(of: regex, options: .regularExpression) != nil
    }
}