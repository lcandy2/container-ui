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
    let name: String
    let image: String
    let status: ContainerStatus
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

enum AppTab: String, CaseIterable {
    case containers = "Containers"
    case images = "Images"
    
    var systemImage: String {
        switch self {
        case .containers: return "shippingbox"
        case .images: return "disc"
        }
    }
}

enum SelectedItem: Hashable {
    case container(Container)
    case image(ContainerImage)
}

struct ContentView: View {
    @StateObject private var containerService = ContainerService()
    @State private var selectedTab: AppTab = .containers
    @State private var selectedItem: SelectedItem?
    @State private var showingNewContainerSheet = false
    @State private var showingLogsSheet = false
    @State private var logsContainer: Container?
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Sidebar - Tabs
            VStack(spacing: 0) {
                Text("Container UI")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding()
                
                Divider()
                
                VStack(spacing: 8) {
                    ForEach(AppTab.allCases, id: \.self) { tab in
                        Button(action: {
                            selectedTab = tab
                            selectedItem = nil // Clear selection when switching tabs
                        }) {
                            HStack {
                                Image(systemName: tab.systemImage)
                                    .frame(width: 16)
                                Text(tab.rawValue)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedTab == tab ? Color.accentColor.opacity(0.2) : Color.clear)
                            .foregroundColor(selectedTab == tab ? .accentColor : .primary)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                
                Spacer()
                
                VStack(spacing: 8) {
                    Button("Refresh") {
                        refreshAll()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("New Container") {
                        showingNewContainerSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .frame(width: 180)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Center Content Area
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(selectedTab.rawValue)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if containerService.isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
                .padding()
                
                Divider()
                
                // Content List
                if selectedTab == .containers {
                    ContainerListView(
                        containers: containerService.containers,
                        selectedItem: $selectedItem,
                        onContainerAction: { action, container in
                            handleContainerAction(action, container)
                        }
                    )
                } else {
                    ImageListView(
                        images: containerService.images,
                        selectedItem: $selectedItem,
                        onImageAction: { action, image in
                            handleImageAction(action, image)
                        }
                    )
                }
            }
            .frame(minWidth: 300)
            
            Divider()
            
            // Right Sidebar - Actions
            if let selectedItem = selectedItem {
                switch selectedItem {
                case .container(let container):
                    ContainerActionsView(
                        container: container,
                        containerService: containerService,
                        onShowLogs: { showLogs(for: container) }
                    )
                case .image(let image):
                    ImageActionsView(
                        image: image,
                        containerService: containerService
                    )
                }
            } else {
                VStack {
                    Image(systemName: selectedTab.systemImage)
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    
                    Text("Select a \(selectedTab.rawValue.lowercased().dropLast())")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("Choose an item to see available actions")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(width: 250)
                .frame(maxHeight: .infinity)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
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
        }
    }
    
    private func startContainer(_ container: Container) {
        Task {
            do {
                try await containerService.startContainer(container.name)
                await containerService.refreshContainers()
            } catch {
                print("Failed to start container: \(error)")
            }
        }
    }
    
    private func stopContainer(_ container: Container) {
        Task {
            do {
                try await containerService.stopContainer(container.name)
                await containerService.refreshContainers()
            } catch {
                print("Failed to stop container: \(error)")
            }
        }
    }
    
    private func deleteContainer(_ container: Container) {
        Task {
            do {
                try await containerService.deleteContainer(container.name)
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
            VStack(spacing: 16) {
                Image(systemName: "shippingbox")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                
                Text("No containers")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                Text("Create a new container to get started")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        Button("Start") {
                            onContainerAction("start", container)
                        }
                        .disabled(container.status == .running)
                        
                        Button("Stop") {
                            onContainerAction("stop", container)
                        }
                        .disabled(container.status != .running)
                        
                        Button("View Logs") {
                            onContainerAction("logs", container)
                        }
                        
                        Divider()
                        
                        Button("Delete", role: .destructive) {
                            onContainerAction("delete", container)
                        }
                    }
            }
            .listStyle(.plain)
        }
    }
}

struct ImageListView: View {
    let images: [ContainerImage]
    @Binding var selectedItem: SelectedItem?
    let onImageAction: (String, ContainerImage) -> Void
    
    var body: some View {
        if images.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "disc")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                
                Text("No images")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                Text("Pull an image to get started")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        Button("Create Container") {
                            onImageAction("create", image)
                        }
                        
                        Divider()
                        
                        Button("Delete", role: .destructive) {
                            onImageAction("delete", image)
                        }
                    }
            }
            .listStyle(.plain)
        }
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

struct ContainerActionsView: View {
    let container: Container
    @ObservedObject var containerService: ContainerService
    let onShowLogs: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(container.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
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
            .padding()
            
            Divider()
            
            // Actions
            VStack(alignment: .leading, spacing: 8) {
                Text("Actions")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top)
                
                VStack(spacing: 4) {
                    ActionButton(
                        title: "Start",
                        systemImage: "play.fill",
                        color: .green,
                        disabled: container.status == .running
                    ) {
                        Task {
                            do {
                                try await containerService.startContainer(container.name)
                                await containerService.refreshContainers()
                            } catch {
                                print("Failed to start container: \(error)")
                            }
                        }
                    }
                    
                    ActionButton(
                        title: "Stop",
                        systemImage: "stop.fill",
                        color: .orange,
                        disabled: container.status != .running
                    ) {
                        Task {
                            do {
                                try await containerService.stopContainer(container.name)
                                await containerService.refreshContainers()
                            } catch {
                                print("Failed to stop container: \(error)")
                            }
                        }
                    }
                    
                    ActionButton(
                        title: "Restart",
                        systemImage: "arrow.clockwise",
                        color: .blue
                    ) {
                        Task {
                            do {
                                try await containerService.stopContainer(container.name)
                                try await containerService.startContainer(container.name)
                                await containerService.refreshContainers()
                            } catch {
                                print("Failed to restart container: \(error)")
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    ActionButton(
                        title: "View Logs",
                        systemImage: "doc.text",
                        color: .blue
                    ) {
                        onShowLogs()
                    }
                    
                    ActionButton(
                        title: "Open Terminal",
                        systemImage: "terminal",
                        color: .blue
                    ) {
                        Task {
                            do {
                                try await containerService.openTerminal(for: container.name)
                            } catch {
                                print("Failed to open terminal: \(error)")
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    ActionButton(
                        title: "Delete",
                        systemImage: "trash",
                        color: .red
                    ) {
                        Task {
                            do {
                                try await containerService.deleteContainer(container.name)
                                await containerService.refreshContainers()
                            } catch {
                                print("Failed to delete container: \(error)")
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .frame(width: 250)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct ImageActionsView: View {
    let image: ContainerImage
    @ObservedObject var containerService: ContainerService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(image.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(image.digest.prefix(12))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            
            Divider()
            
            // Actions
            VStack(alignment: .leading, spacing: 8) {
                Text("Actions")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top)
                
                VStack(spacing: 4) {
                    ActionButton(
                        title: "Create Container",
                        systemImage: "plus.rectangle",
                        color: .blue
                    ) {
                        Task {
                            do {
                                try await containerService.createAndRunContainer(image: image.displayName)
                                await containerService.refreshContainers()
                            } catch {
                                print("Failed to create container: \(error)")
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    ActionButton(
                        title: "Delete Image",
                        systemImage: "trash",
                        color: .red
                    ) {
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
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .frame(width: 250)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct ActionButton: View {
    let title: String
    let systemImage: String
    let color: Color
    var disabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                    .frame(width: 16)
                    .foregroundColor(disabled ? .secondary : color)
                
                Text(title)
                    .foregroundColor(disabled ? .secondary : .primary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(disabled ? Color.clear : Color(NSColor.controlColor))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
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
                            try await containerService.startContainer(container.name)
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
                            try await containerService.stopContainer(container.name)
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
                            try await containerService.stopContainer(container.name)
                            try await containerService.startContainer(container.name)
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
                            try await containerService.openTerminal(for: container.name)
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
                            try await containerService.deleteContainer(container.name)
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
                    result = try await containerService.getContainerBootLogs(container.name)
                } else {
                    let lines = lineLimit == -1 ? nil : lineLimit
                    result = try await containerService.getContainerLogs(container.name, lines: lines)
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

#Preview {
    ContentView()
}
