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
    let created: Date
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

enum SidebarItem: Hashable {
    case container(Container)
    case image(ContainerImage)
}

struct ContentView: View {
    @StateObject private var containerService = ContainerService()
    @State private var selectedContainer: Container?
    @State private var selectedImage: ContainerImage?
    @State private var selectedItem: SidebarItem?
    @State private var showingNewContainerSheet = false
    
    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Container Manager")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Refresh") {
                        refreshAll()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                if containerService.containers.isEmpty && containerService.images.isEmpty && !containerService.isLoading {
                    VStack(spacing: 16) {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        
                        Text("No containers or images found")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        
                        Text("Create a new container to get started")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        
                        Button("New Container") {
                            showingNewContainerSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(selection: $selectedItem) {
                        Section("Containers") {
                            if containerService.containers.isEmpty {
                                Text("No containers")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            } else {
                                ForEach(containerService.containers) { container in
                                    ContainerRow(container: container)
                                        .tag(SidebarItem.container(container))
                                        .contextMenu {
                                            Button("Start") {
                                                startContainer(container)
                                            }
                                            .disabled(container.status == .running)
                                            
                                            Button("Stop") {
                                                stopContainer(container)
                                            }
                                            .disabled(container.status != .running)
                                            
                                            Divider()
                                            
                                            Button("Delete", role: .destructive) {
                                                deleteContainer(container)
                                            }
                                        }
                                }
                            }
                        }
                        
                        Section("Images") {
                            if containerService.images.isEmpty {
                                Text("No images")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            } else {
                                ForEach(containerService.images) { image in
                                    ImageRow(image: image)
                                        .tag(SidebarItem.image(image))
                                        .contextMenu {
                                            Button("Create Container") {
                                                // TODO: Create container from image
                                            }
                                            
                                            Divider()
                                            
                                            Button("Delete", role: .destructive) {
                                                deleteImage(image)
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .listStyle(.sidebar)
                }
            }
        } detail: {
            if let selectedItem = selectedItem {
                switch selectedItem {
                case .container(let container):
                    ContainerDetailView(container: container)
                        .environmentObject(containerService)
                case .image(let image):
                    ImageDetailView(image: image)
                        .environmentObject(containerService)
                }
            } else {
                VStack {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)
                    Text("Select a container or image")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New Container") {
                    showingNewContainerSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .task {
            await refreshAll()
        }
        .overlay {
            if containerService.isLoading {
                ProgressView("Loading containers...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.regularMaterial)
            }
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
            
            Text("Created \(container.created, style: .relative)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
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

struct ContainerDetailView: View {
    let container: Container
    @EnvironmentObject private var containerService: ContainerService
    
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
                    
                    Text("Created \(container.created, style: .relative)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

#Preview {
    ContentView()
}
