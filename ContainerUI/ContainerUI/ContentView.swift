//
//  ContentView.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

struct Container: Identifiable, Hashable {
    let id = UUID()
    let containerID: String  // The actual container ID from the command
    let name: String
    let image: String
    let os: String
    let arch: String
    let status: ContainerStatus
    let addr: String?  // Optional since it might be empty for stopped containers
}

struct ContainerImage: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let tag: String
    let digest: String
    
    var displayName: String {
        return "\(name):\(tag)"
    }
}

enum ContainerStatus: Hashable {
    case running
    case stopped
    case exited
    
    var displayName: String {
        switch self {
        case .running: return "Running"
        case .stopped: return "Stopped"
        case .exited: return "Exited"
        }
    }
    
    var color: Color {
        switch self {
        case .running: return .green
        case .stopped: return .orange
        case .exited: return .red
        }
    }
}

struct SystemInfo {
    let serviceStatus: SystemServiceStatus
    let dnsSettings: [DNSDomain]
    let kernelInfo: String?
}

struct DNSDomain: Identifiable, Hashable {
    let id = UUID()
    let domain: String
    let isDefault: Bool
}

enum SystemServiceStatus: Hashable {
    case running
    case stopped
    case unknown
    
    var displayName: String {
        switch self {
        case .running: return "Running"
        case .stopped: return "Stopped"
        case .unknown: return "Unknown"
        }
    }
    
    var color: Color {
        switch self {
        case .running: return .green
        case .stopped: return .red
        case .unknown: return .orange
        }
    }
}

enum AppTab: String, CaseIterable {
    case containers = "Containers"
    case images = "Images"
    case system = "System"
    
    var systemImage: String {
        switch self {
        case .containers: return "shippingbox"
        case .images: return "disc"
        case .system: return "gearshape"
        }
    }
}

enum SelectedItem: Hashable {
    case container(Container)
    case image(ContainerImage)
    case system
}

struct ContentView: View {
    @StateObject private var containerService = ContainerService()
    @State private var selectedTab: AppTab = .containers
    @State private var selectedItem: SelectedItem?
    @State private var showingNewContainerSheet = false
    @State private var showingLogsSheet = false
    @State private var logsContainer: Container?
    
    var body: some View {
        NavigationSplitView {
            // Left Sidebar
            List(selection: $selectedTab) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    NavigationLink(value: tab) {
                        Label(tab.rawValue, systemImage: tab.systemImage)
                    }
                }
            }
            .navigationTitle("Container UI")
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 250)
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    Button("Refresh") {
                        refreshAll()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("New Container") {
                        showingNewContainerSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        } content: {
            // Center Content
            Group {
                if selectedTab == .containers {
                    ContainerListView(
                        containers: containerService.containers,
                        selectedItem: $selectedItem,
                        onContainerAction: { action, container in
                            handleContainerAction(action, container)
                        }
                    )
                } else if selectedTab == .images {
                    ImageListView(
                        images: containerService.images,
                        selectedItem: $selectedItem,
                        onImageAction: { action, image in
                            handleImageAction(action, image)
                        }
                    )
                } else {
                    SystemListView(
                        selectedItem: $selectedItem,
                        containerService: containerService
                    )
                }
            }
            .navigationTitle(selectedTab.rawValue)
            .navigationSplitViewColumnWidth(min: 300, ideal: 400, max: 600)
            .toolbar {
                if containerService.isLoading {
                    ToolbarItem(placement: .primaryAction) {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
        } detail: {
            // Right Inspector
            if let selectedItem = selectedItem {
                switch selectedItem {
                case .container(let container):
                    ContainerInspectorView(
                        container: container,
                        containerService: containerService,
                        onShowLogs: { showLogs(for: container) }
                    )
                case .image(let image):
                    ImageInspectorView(
                        image: image,
                        containerService: containerService
                    )
                case .system:
                    SystemInspectorView(
                        containerService: containerService
                    )
                }
            } else {
                ContentUnavailableView(
                    "Select an Item",
                    systemImage: selectedTab.systemImage,
                    description: Text(selectedTab == .system ? "System management and configuration" : "Choose a \(selectedTab.rawValue.lowercased().dropLast()) to see details and actions")
                )
            }
        }
        .task {
            await refreshAll()
        }
        .alert("Error", isPresented: .constant(containerService.errorMessage != nil)) {
            Button("OK") {
                containerService.errorMessage = nil
            }
        } message: {
            Text(containerService.errorMessage ?? "")
        }
        .sheet(isPresented: $showingNewContainerSheet) {
            NewContainerView(containerService: containerService)
        }
        .sheet(isPresented: $showingLogsSheet) {
            if let container = logsContainer {
                LogsView(container: container, containerService: containerService)
            }
        }
    }
    
    private func refreshAll() {
        Task {
            await containerService.refreshContainers()
            await containerService.refreshImages()
            await containerService.refreshSystemInfo()
        }
    }
    
    private func startContainer(_ container: Container) {
        Task {
            do {
                try await containerService.startContainer(container.containerID)
                await containerService.refreshContainers()
            } catch {
                print("Failed to start container: \(error)")
            }
        }
    }
    
    private func stopContainer(_ container: Container) {
        Task {
            do {
                try await containerService.stopContainer(container.containerID)
                await containerService.refreshContainers()
            } catch {
                print("Failed to stop container: \(error)")
            }
        }
    }
    
    private func deleteContainer(_ container: Container) {
        Task {
            do {
                try await containerService.deleteContainer(container.containerID)
                await containerService.refreshContainers()
            } catch {
                print("Failed to delete container: \(error)")
            }
        }
    }
    
    private func deleteImage(_ image: ContainerImage) {
        Task {
            do {
                try await containerService.deleteImage("\(image.name):\(image.tag)")
                await containerService.refreshImages()
            } catch {
                print("Failed to delete image: \(error)")
            }
        }
    }
    
    private func showLogs(for container: Container) {
        logsContainer = container
        showingLogsSheet = true
    }
    
    private func handleContainerAction(_ action: String, _ container: Container) {
        switch action {
        case "start":
            startContainer(container)
        case "stop":
            stopContainer(container)
        case "delete":
            deleteContainer(container)
        case "logs":
            showLogs(for: container)
        default:
            break
        }
    }
    
    private func handleImageAction(_ action: String, _ image: ContainerImage) {
        switch action {
        case "delete":
            deleteImage(image)
        case "create":
            Task {
                do {
                    try await containerService.createAndRunContainer(image: image.displayName)
                    await containerService.refreshContainers()
                } catch {
                    print("Failed to create container: \(error)")
                }
            }
        default:
            break
        }
    }
}

struct ContainerListView: View {
    let containers: [Container]
    @Binding var selectedItem: SelectedItem?
    let onContainerAction: (String, Container) -> Void
    
    var body: some View {
        if containers.isEmpty {
            ContentUnavailableView(
                "No Containers",
                systemImage: "shippingbox",
                description: Text("Create a new container to get started")
            )
        } else {
            List(containers, id: \.id, selection: Binding(
                get: {
                    if case .container(let container) = selectedItem {
                        return container
                    }
                    return nil
                },
                set: { container in
                    if let container = container {
                        selectedItem = .container(container)
                    }
                }
            )) { container in
                ContainerRow(container: container)
                    .tag(container)
                    .contextMenu {
                        Button("Start", systemImage: "play.fill") {
                            onContainerAction("start", container)
                        }
                        .disabled(container.status == .running)
                        
                        Button("Stop", systemImage: "stop.fill") {
                            onContainerAction("stop", container)
                        }
                        .disabled(container.status != .running)
                        
                        Button("View Logs", systemImage: "doc.text") {
                            onContainerAction("logs", container)
                        }
                        
                        Divider()
                        
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            onContainerAction("delete", container)
                        }
                    }
            }
        }
    }
}

struct ImageListView: View {
    let images: [ContainerImage]
    @Binding var selectedItem: SelectedItem?
    let onImageAction: (String, ContainerImage) -> Void
    
    var body: some View {
        if images.isEmpty {
            ContentUnavailableView(
                "No Images",
                systemImage: "disc",
                description: Text("Pull an image to get started")
            )
        } else {
            List(images, id: \.id, selection: Binding(
                get: {
                    if case .image(let image) = selectedItem {
                        return image
                    }
                    return nil
                },
                set: { image in
                    if let image = image {
                        selectedItem = .image(image)
                    }
                }
            )) { image in
                ImageRow(image: image)
                    .tag(image)
                    .contextMenu {
                        Button("Create Container", systemImage: "plus.rectangle") {
                            onImageAction("create", image)
                        }
                        
                        Divider()
                        
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            onImageAction("delete", image)
                        }
                    }
            }
        }
    }
}

struct SystemListView: View {
    @Binding var selectedItem: SelectedItem?
    @ObservedObject var containerService: ContainerService
    
    var body: some View {
        VStack(spacing: 20) {
            // System Status Card
            Button(action: {
                selectedItem = .system
            }) {
                SystemStatusCard(systemInfo: containerService.systemInfo)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding()
    }
}

struct SystemStatusCard: View {
    let systemInfo: SystemInfo?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text("Container System")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let systemInfo = systemInfo {
                        HStack {
                            Circle()
                                .fill(systemInfo.serviceStatus.color)
                                .frame(width: 8, height: 8)
                            Text(systemInfo.serviceStatus.displayName)
                                .font(.caption)
                        }
                    } else {
                        Text("Loading...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if let systemInfo = systemInfo {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("DNS Domains:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(systemInfo.dnsSettings.count)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    if !systemInfo.dnsSettings.isEmpty {
                        ForEach(systemInfo.dnsSettings.prefix(3)) { domain in
                            HStack {
                                if domain.isDefault {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundColor(.yellow)
                                }
                                Text(domain.domain)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        if systemInfo.dnsSettings.count > 3 {
                            Text("and \(systemInfo.dnsSettings.count - 3) more...")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
    }
}

struct ContainerRow: View {
    let container: Container
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(container.name)
                    .font(.headline)
                
                Spacer()
                
                Text(container.status.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(container.status.color.opacity(0.2))
                    .foregroundColor(container.status.color)
                    .clipShape(Capsule())
            }
            
            Text(container.image)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct ImageRow: View {
    let image: ContainerImage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(image.displayName)
                    .font(.headline)
                
                Spacer()
                
                Text("Image")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }
            
            Text(image.digest.prefix(12))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}

struct ImageDetailView: View {
    let image: ContainerImage
    @EnvironmentObject private var containerService: ContainerService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading) {
                    Text(image.displayName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(image.digest)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Image")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                }
            }
            
            Divider()
            
            HStack(spacing: 12) {
                Button("Create Container") {
                    Task {
                        do {
                            try await containerService.createAndRunContainer(image: image.displayName)
                            await containerService.refreshContainers()
                        } catch {
                            print("Failed to create container: \(error)")
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await containerService.deleteImage(image.displayName)
                            await containerService.refreshImages()
                        } catch {
                            print("Failed to delete image: \(error)")
                        }
                    }
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct ContainerInspectorView: View {
    let container: Container
    @ObservedObject var containerService: ContainerService
    let onShowLogs: () -> Void
    
    var body: some View {
        List {
            Section("Container Info") {
                LabeledContent("Container ID") {
                    Text(container.containerID)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
                LabeledContent("Short ID", value: container.name)
                LabeledContent("Image", value: container.image)
                LabeledContent("Status") {
                    HStack {
                        Circle()
                            .fill(container.status.color)
                            .frame(width: 8, height: 8)
                        Text(container.status.displayName)
                    }
                }
            }
            
            Section("System Info") {
                LabeledContent("Operating System", value: container.os)
                LabeledContent("Architecture", value: container.arch)
                if let addr = container.addr {
                    LabeledContent("IP Address", value: addr)
                } else {
                    LabeledContent("IP Address", value: "Not available")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Actions") {
                Button("Start Container") {
                    Task {
                        do {
                            try await containerService.startContainer(container.containerID)
                            await containerService.refreshContainers()
                        } catch {
                            print("Failed to start container: \(error)")
                        }
                    }
                }
                .disabled(container.status == .running)
                
                Button("Stop Container") {
                    Task {
                        do {
                            try await containerService.stopContainer(container.containerID)
                            await containerService.refreshContainers()
                        } catch {
                            print("Failed to stop container: \(error)")
                        }
                    }
                }
                .disabled(container.status != .running)
                
                Button("Restart Container") {
                    Task {
                        do {
                            try await containerService.stopContainer(container.containerID)
                            try await containerService.startContainer(container.containerID)
                            await containerService.refreshContainers()
                        } catch {
                            print("Failed to restart container: \(error)")
                        }
                    }
                }
            }
            
            Section("Debug") {
                Button("View Logs") {
                    onShowLogs()
                }
                
                Button("Open Terminal") {
                    Task {
                        do {
                            try await containerService.openTerminal(for: container.containerID)
                        } catch {
                            print("Failed to open terminal: \(error)")
                        }
                    }
                }
            }
            
            Section("Danger Zone") {
                Button("Delete Container", role: .destructive) {
                    Task {
                        do {
                            try await containerService.deleteContainer(container.containerID)
                            await containerService.refreshContainers()
                        } catch {
                            print("Failed to delete container: \(error)")
                        }
                    }
                }
            }
        }
        .navigationTitle("Container Details")
    }
}

struct ImageInspectorView: View {
    let image: ContainerImage
    @ObservedObject var containerService: ContainerService
    
    var body: some View {
        List {
            Section("Image Info") {
                LabeledContent("Name", value: image.name)
                LabeledContent("Tag", value: image.tag)
                LabeledContent("Digest") {
                    Text(image.digest)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
            
            Section("Actions") {
                Button("Create Container") {
                    Task {
                        do {
                            try await containerService.createAndRunContainer(image: image.displayName)
                            await containerService.refreshContainers()
                        } catch {
                            print("Failed to create container: \(error)")
                        }
                    }
                }
            }
            
            Section("Danger Zone") {
                Button("Delete Image", role: .destructive) {
                    Task {
                        do {
                            try await containerService.deleteImage(image.displayName)
                            await containerService.refreshImages()
                        } catch {
                            print("Failed to delete image: \(error)")
                        }
                    }
                }
            }
        }
        .navigationTitle("Image Details")
    }
}

struct SystemInspectorView: View {
    @ObservedObject var containerService: ContainerService
    @State private var showingSystemLogsSheet = false
    @State private var newDomainName = ""
    @State private var showingAddDomainAlert = false
    
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
                    showingSystemLogsSheet = true
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
        .sheet(isPresented: $showingSystemLogsSheet) {
            SystemLogsView(containerService: containerService)
        }
    }
}

struct ContainerDetailView: View {
    let container: Container
    @EnvironmentObject private var containerService: ContainerService
    @State private var showingLogsSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading) {
                    Text(container.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(container.image)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(container.status.displayName)
                        .font(.title2)
                        .foregroundColor(container.status.color)
                        .fontWeight(.semibold)
                }
            }
            
            Divider()
            
            HStack(spacing: 12) {
                Button("Start") {
                    Task {
                        do {
                            try await containerService.startContainer(container.containerID)
                            await containerService.refreshContainers()
                        } catch {
                            print("Failed to start container: \(error)")
                        }
                    }
                }
                .disabled(container.status == .running)
                .buttonStyle(.borderedProminent)
                
                Button("Stop") {
                    Task {
                        do {
                            try await containerService.stopContainer(container.containerID)
                            await containerService.refreshContainers()
                        } catch {
                            print("Failed to stop container: \(error)")
                        }
                    }
                }
                .disabled(container.status != .running)
                .buttonStyle(.bordered)
                
                Button("Restart") {
                    Task {
                        do {
                            try await containerService.stopContainer(container.containerID)
                            try await containerService.startContainer(container.containerID)
                            await containerService.refreshContainers()
                        } catch {
                            print("Failed to restart container: \(error)")
                        }
                    }
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Open Terminal") {
                    Task {
                        do {
                            try await containerService.openTerminal(for: container.containerID)
                        } catch {
                            print("Failed to open terminal: \(error)")
                        }
                    }
                }
                .buttonStyle(.bordered)
                
                Button("View Logs") {
                    showingLogsSheet = true
                }
                .buttonStyle(.bordered)
                
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await containerService.deleteContainer(container.containerID)
                            await containerService.refreshContainers()
                        } catch {
                            print("Failed to delete container: \(error)")
                        }
                    }
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingLogsSheet) {
            LogsView(container: container, containerService: containerService)
        }
    }
}

struct NewContainerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var containerService: ContainerService
    
    @State private var imageName = "alpine:latest"
    @State private var containerName = ""
    @State private var isCreating = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Container Configuration") {
                    TextField("Image", text: $imageName)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Container Name (optional)", text: $containerName)
                        .textFieldStyle(.roundedBorder)
                }
                
                Section("Common Images") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                        ForEach(commonImages, id: \.self) { image in
                            Button(image) {
                                imageName = image
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .navigationTitle("New Container")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createContainer()
                    }
                    .disabled(imageName.isEmpty || isCreating)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private var commonImages: [String] {
        [
            "alpine:latest",
            "ubuntu:latest",
            "nginx:alpine",
            "node:alpine",
            "python:alpine",
            "redis:alpine",
            "postgres:15"
        ]
    }
    
    private func createContainer() {
        isCreating = true
        Task {
            do {
                let name = containerName.isEmpty ? nil : containerName
                try await containerService.createAndRunContainer(image: imageName, name: name)
                await containerService.refreshContainers()
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Failed to create container: \(error)")
            }
            isCreating = false
        }
    }
}

struct LogsView: View {
    let container: Container
    @ObservedObject var containerService: ContainerService
    @Environment(\.dismiss) private var dismiss
    
    @State private var logs = ""
    @State private var isLoading = false
    @State private var showBootLogs = false
    @State private var lineLimit = 100
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Toggle("Boot Logs", isOn: $showBootLogs)
                    
                    Spacer()
                    
                    if !showBootLogs {
                        Picker("Lines", selection: $lineLimit) {
                            Text("50").tag(50)
                            Text("100").tag(100)
                            Text("500").tag(500)
                            Text("All").tag(-1)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                    
                    Button("Refresh") {
                        loadLogs()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                
                Divider()
                
                if isLoading {
                    VStack {
                        ProgressView("Loading logs...")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        ScrollViewReader { proxy in
                            VStack(alignment: .leading, spacing: 0) {
                                Text(logs.isEmpty ? "No logs available" : logs)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .id("bottom")
                            }
                            .onAppear {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                            .onChange(of: logs) { _, _ in
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                    .background(Color(NSColor.textBackgroundColor))
                }
            }
            .navigationTitle("Logs - \(container.name)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .task {
            loadLogs()
        }
        .onChange(of: showBootLogs) { _, _ in
            loadLogs()
        }
        .onChange(of: lineLimit) { _, _ in
            if !showBootLogs {
                loadLogs()
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
    
    private func loadLogs() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let result: String
                if showBootLogs {
                    result = try await containerService.getContainerBootLogs(container.containerID)
                } else {
                    let lines = lineLimit == -1 ? nil : lineLimit
                    result = try await containerService.getContainerLogs(container.containerID, lines: lines)
                }
                
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
    }
}

struct SystemLogsView: View {
    @ObservedObject var containerService: ContainerService
    @Environment(\.dismiss) private var dismiss
    
    @State private var logs = ""
    @State private var isLoading = false
    @State private var timeFilter = "5m"
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Text("Time Filter:")
                    
                    Picker("Time Filter", selection: $timeFilter) {
                        Text("5 minutes").tag("5m")
                        Text("1 hour").tag("1h")
                        Text("1 day").tag("1d")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 250)
                    
                    Spacer()
                    
                    Button("Refresh") {
                        loadLogs()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                
                Divider()
                
                if isLoading {
                    VStack {
                        ProgressView("Loading system logs...")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(logs.isEmpty ? "No system logs available" : logs)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        }
                    }
                    .background(Color(NSColor.textBackgroundColor))
                }
            }
            .navigationTitle("System Logs")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .task {
            loadLogs()
        }
        .onChange(of: timeFilter) { _, _ in
            loadLogs()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    private func loadLogs() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await containerService.getSystemLogs(timeFilter: timeFilter)
                
                await MainActor.run {
                    logs = result
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load system logs: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
