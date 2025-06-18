//
//  SystemListView.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI
import ContainerModels
import ButtonKit

struct SystemListView: View {
    @Environment(ContainerService.self) private var containerService
    @Environment(\.openWindow) private var openWindow
    @State private var newDomainName = ""
    @State private var showingAddDomainAlert = false

    @State private var showingInspector = true
    
    var body: some View {
        NavigationStack {
            List {
                // System Status Section
                Section {
                    SystemStatusCard(systemInfo: containerService.systemInfo)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
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
//                        Button("Add Domain", systemImage: "plus") {
//                            showingAddDomainAlert = true
//                        }
//                        .buttonStyle(.borderless)
                    }
                }
                

            }
            .navigationTitle("System")
            .refreshable {
                await refreshSystemInfo()
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    AsyncButton {
                        await refreshSystemInfo()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .asyncButtonStyle(.none)
                    
                    Button {
                        showingInspector.toggle()
                    } label: {
                        Image(systemName: "sidebar.right")
                    }
                }
            }
            .alert("Add DNS Domain", isPresented: $showingAddDomainAlert) {
                TextField("example.com", text: $newDomainName)
                    .autocorrectionDisabled()
                
                Button("Cancel", role: .cancel) {
                    newDomainName = ""
                }
                
                AsyncButton {
                    try await addDNSDomain()
                } label: {
                    Text("Add")
                }
                .disabled(newDomainName.isEmpty || !isValidDomain(newDomainName))
            } message: {
                Text("Enter a DNS domain name to add to the system configuration.")
            }
            .inspector(isPresented: $showingInspector) {
                SystemInspectorView()
            }
        }
    }
    
    // MARK: - System Controls Content
    
    private var systemControlsContent: some View {
        HStack {
            AsyncButton {
                try await containerService.startSystem()
                await containerService.refreshSystemInfo()
            } label: {
                Label("Start", systemImage: "play.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .asyncButtonStyle(.overlay)
            .disabled(containerService.systemInfo?.serviceStatus == .running)
            
            AsyncButton {
                try await containerService.stopSystem()
                await containerService.refreshSystemInfo()
            } label: {
                Label("Stop", systemImage: "stop.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .asyncButtonStyle(.overlay)
            .disabled(containerService.systemInfo?.serviceStatus != .running)
            
            AsyncButton {
                try await containerService.restartSystem()
                await containerService.refreshSystemInfo()
            } label: {
                Label("Restart", systemImage: "arrow.clockwise.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .asyncButtonStyle(.overlay)
        }
        .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
    }
    
    // MARK: - DNS Management Content
    
    private var dnsManagementContent: some View {
        Group {
            // DNS Domains List
            if let systemInfo = containerService.systemInfo {
                if systemInfo.dnsSettings.isEmpty {
                    HStack {
                        Image(systemName: "network.slash")
                            .foregroundStyle(.secondary)
                        Text("No DNS domains configured")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.vertical, 8)
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
                    Spacer()
                }
            }
        }
    }
    
    private func dnsDomainRow(_ domain: DNSDomain) -> some View {
        HStack {
            // Domain icon
            Image(systemName: "network")
                .frame(width: 20)
            
            // Domain info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(domain.domain)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if domain.isDefault {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                }
                
                if domain.isDefault {
                    Text("Default")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }
            }
            
            Spacer()
            
            // Actions menu
//            Menu {
//                if !domain.isDefault {
//                    Button {
//                        Task { await setDefaultDomain(domain.domain) }
//                    } label: {
//                        Label("Set as Default", systemImage: "star")
//                    }
//                }
//                
//                Button(role: .destructive) {
//                    Task { await deleteDomain(domain.domain) }
//                } label: {
//                    Label("Delete Domain", systemImage: "trash")
//                }
//            } label: {
//                Image(systemName: "ellipsis.circle")
//                    .foregroundStyle(.tertiary)
//            }
//            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
    

    
    // MARK: - Helper Methods
    
    private func refreshSystemInfo() async {
        await containerService.refreshSystemInfo()
    }
    
    private func addDNSDomain() async throws {
        try await containerService.createDNSDomain(newDomainName)
        await containerService.refreshSystemInfo()
        newDomainName = ""
    }
    
    private func setDefaultDomain(_ domain: String) async throws {
        try await containerService.setDefaultDNSDomain(domain)
        await containerService.refreshSystemInfo()
    }
    
    private func deleteDomain(_ domain: String) async throws {
        try await containerService.deleteDNSDomain(domain)
        await containerService.refreshSystemInfo()
    }
    
    private func isValidDomain(_ domain: String) -> Bool {
        let regex = "^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\\.[a-zA-Z]{2,}$"
        return domain.range(of: regex, options: .regularExpression) != nil
    }
}
