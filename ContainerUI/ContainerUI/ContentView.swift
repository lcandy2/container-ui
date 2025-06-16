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

struct ContentView: View {
    @StateObject private var containerService = ContainerService()
    @State private var selectedContainer: Container?
    
    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Containers")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Refresh") {
                        refreshContainers()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                
                List(containerService.containers, selection: $selectedContainer) { container in
                    ContainerRow(container: container)
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
                .listStyle(.sidebar)
            }
        } detail: {
            if let container = selectedContainer {
                ContainerDetailView(container: container)
                    .environmentObject(containerService)
            } else {
                VStack {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)
                    Text("Select a container")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New Container") {
                    // TODO: Show new container sheet
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .task {
            await containerService.refreshContainers()
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
    }
    
    private func refreshContainers() {
        Task {
            await containerService.refreshContainers()
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

#Preview {
    ContentView()
}
