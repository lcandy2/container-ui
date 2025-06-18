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
        ScrollView {
            LazyVStack(spacing: 24) {
                // System Status Overview
                SystemStatusCard(systemInfo: containerService.systemInfo)
                    .contentTransition(.numericText())
                
                // System Controls Section
                systemControlsSection
                
                // DNS Management Section
                dnsManagementSection
                
                // System Logs Section
                systemLogsSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .refreshable {
            await refreshSystemInfo()
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    Task { await refreshSystemInfo() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        Text("Refresh")
                    }
                }
                .buttonStyle(.bordered)
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
                Task {
                    await addDNSDomain()
                }
            }
            .disabled(newDomainName.isEmpty || !isValidDomain(newDomainName))
        } message: {
            Text("Enter a DNS domain name to add to the system configuration.")
        }
    }
    
    // MARK: - System Controls Section
    
    private var systemControlsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "System Controls",
                subtitle: "Manage the container system service",
                icon: "gearshape.2.fill",
                iconColor: .blue
            )
            
            VStack(spacing: 12) {
                // Primary Action Buttons
                HStack(spacing: 12) {
                    systemControlButton(
                        title: "Start System",
                        icon: "play.circle.fill",
                        iconColor: .green,
                        style: .prominent,
                        isDisabled: containerService.systemInfo?.serviceStatus == .running
                    ) {
                        await performSystemAction { 
                            try await containerService.startSystem()
                        }
                    }
                    
                    systemControlButton(
                        title: "Stop System",
                        icon: "stop.circle.fill",
                        iconColor: .red,
                        style: .bordered,
                        isDisabled: containerService.systemInfo?.serviceStatus != .running
                    ) {
                        await performSystemAction { 
                            try await containerService.stopSystem()
                        }
                    }
                }
                
                // Secondary Action Button
                systemControlButton(
                    title: "Restart System",
                    icon: "arrow.clockwise.circle.fill",
                    iconColor: .orange,
                    style: .bordered,
                    isDisabled: false
                ) {
                    await performSystemAction { 
                        try await containerService.restartSystem()
                    }
                }
            }
        }
        .modernCard()
    }
    
    // MARK: - DNS Management Section
    
    private var dnsManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                sectionHeader(
                    title: "DNS Management",
                    subtitle: "Configure DNS domains for containers",
                    icon: "network",
                    iconColor: .purple
                )
                
                Spacer()
                
                Button {
                    showingAddDomainAlert = true
                } label: {
                    Label("Add Domain", systemImage: "plus.circle.fill")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add DNS Domain")
            }
            
            dnsDomainsContent
        }
        .modernCard()
    }
    
    private var dnsDomainsContent: some View {
        Group {
            if let systemInfo = containerService.systemInfo {
                if systemInfo.dnsSettings.isEmpty {
                    emptyDNSState
                } else {
                    dnsDomainsGrid(systemInfo.dnsSettings)
                }
            } else {
                loadingDNSState
            }
        }
    }
    
    private var emptyDNSState: some View {
        VStack(spacing: 12) {
            Image(systemName: "network.slash")
                .font(.title)
                .foregroundStyle(.tertiary)
            
            Text("No DNS domains configured")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("Add a domain to enable container DNS resolution")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    private var loadingDNSState: some View {
        VStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { _ in
                HStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.quaternary)
                        .frame(width: 120, height: 16)
                    
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.quaternary)
                        .frame(width: 20, height: 12)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .redacted(reason: .placeholder)
    }
    
    private func dnsDomainsGrid(_ domains: [DNSDomain]) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ], spacing: 8) {
            ForEach(domains) { domain in
                dnsDomainCard(domain)
            }
        }
    }
    
    private func dnsDomainCard(_ domain: DNSDomain) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(domain.domain)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    if domain.isDefault {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                }
                
                if domain.isDefault {
                    Text("Default")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.yellow)
                        .textCase(.uppercase)
                }
            }
            
            Spacer()
            
            Menu {
                if !domain.isDefault {
                    Button {
                        Task {
                            await setDefaultDomain(domain.domain)
                        }
                    } label: {
                        Label("Set as Default", systemImage: "star.fill")
                    }
                }
                
                Divider()
                
                Button(role: .destructive) {
                    Task {
                        await deleteDomain(domain.domain)
                    }
                } label: {
                    Label("Delete Domain", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.quaternary.opacity(0.6), lineWidth: 0.5)
        )
    }
    
    // MARK: - System Logs Section
    
    private var systemLogsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "System Logs",
                subtitle: "View container system activity",
                icon: "doc.text.fill",
                iconColor: .green
            )
            
            Button {
                let logSource = containerService.createSystemLogSource()
                openWindow(id: "universal-logs", value: logSource.id)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.up.right.square.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("View System Logs")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        Text("Open in new window")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.blue.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .modernCard()
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(title: String, subtitle: String, icon: String, iconColor: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(iconColor.gradient)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func systemControlButton(
        title: String,
        icon: String,
        iconColor: Color,
        style: ButtonStyle,
        isDisabled: Bool,
        action: @escaping () async -> Void
    ) -> some View {
        Button {
            Task { await action() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ModernButtonStyle(style: style, iconColor: iconColor))
        .disabled(isDisabled)
    }
    
    // MARK: - Helper Methods
    
    private func refreshSystemInfo() async {
        withAnimation(.easeInOut(duration: 0.4)) {
            isRefreshing = true
        }
        
        await containerService.refreshSystemInfo()
        
        withAnimation(.easeInOut(duration: 0.4).delay(0.1)) {
            isRefreshing = false
        }
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

// MARK: - Custom Button Style

private enum ButtonStyle {
    case prominent, bordered
}

private struct ModernButtonStyle: SwiftUI.ButtonStyle {
    let style: ButtonStyle
    let iconColor: Color
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(backgroundForStyle(configuration.isPressed))
            .foregroundStyle(foregroundForStyle)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.6)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    @ViewBuilder
    private func backgroundForStyle(_ isPressed: Bool) -> some View {
        switch style {
        case .prominent:
            LinearGradient(
                colors: [iconColor, iconColor.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(isPressed ? 0.8 : 1.0)
        case .bordered:
            Color.clear
        }
    }
    
    private var foregroundForStyle: Color {
        switch style {
        case .prominent:
            return .white
        case .bordered:
            return iconColor
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .prominent:
            return .clear
        case .bordered:
            return iconColor.opacity(0.3)
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .prominent:
            return 0
        case .bordered:
            return 1
        }
    }
}

// MARK: - View Extensions

private extension View {
    func modernCard() -> some View {
        self
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.quaternary.opacity(0.5), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            .shadow(color: .black.opacity(0.08), radius: 1, x: 0, y: 1)
    }
}