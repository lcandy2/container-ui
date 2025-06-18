//
//  ContainerListView.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI
import ContainerModels

struct ContainerListView: View {
    @Environment(ContainerService.self) private var containerService
    @Environment(\.openWindow) private var openWindow
    
    @State private var selectedContainer: Container?
    @State private var isInspectorPresented = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            // Check if system is stopped
            if containerService.systemInfo?.serviceStatus == .stopped {
                ContentUnavailableView {
                    Label("Container System Stopped", systemImage: "server.rack")
                } actions: {
                    Button("Turn On") {
                        Task {
                            do {
                                try await containerService.startSystem()
                                await containerService.refreshSystemInfo()
                                await containerService.refreshContainers()
                            } catch {
                                errorMessage = "Failed to start system: \(error.localizedDescription)"
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if containerService.containers.isEmpty {
                ContentUnavailableView(
                    "No Containers",
                    systemImage: "shippingbox",
                    description: Text("Create a container to get started")
                )
            } else {
                List(containerService.containers, id: \.id, selection: $selectedContainer) { container in
                    ContainerRow(container: container)
                        .tag(container)
                        .contextMenu {
                            Button("Start", systemImage: "play.fill") {
                                startContainer(container)
                            }
                            .disabled(container.status == .running)
                            
                            Button("Stop", systemImage: "stop.fill") {
                                stopContainer(container)
                            }
                            .disabled(container.status != .running)
                            
                            Button("View Logs", systemImage: "doc.text") {
                                showLogs(for: container)
                            }
                            
                            Divider()
                            
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                deleteContainer(container)
                            }
                        }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button("Refresh") {
                    Task { @MainActor in
                        await containerService.refreshContainers()
                    }
                }
                .buttonStyle(.bordered)
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isInspectorPresented.toggle()
                    }
                } label: {
                    Label("Inspector", systemImage: "sidebar.trailing")
                }
                .help("Show Inspector")
            }
            
            ToolbarItemGroup(placement: .status) {
                if containerService.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
        .inspector(isPresented: $isInspectorPresented) {
            if let selectedContainer = selectedContainer {
                ContainerInspectorView(container: selectedContainer)
            } else {
                ContentUnavailableView(
                    "No Container Selected",
                    systemImage: "shippingbox",
                    description: Text("Select a container to view details")
                )
            }
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { _ in errorMessage = nil }
        )) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    // MARK: - Container Actions
    
    private func startContainer(_ container: Container) {
        Task { @MainActor in
            do {
                try await containerService.startContainer(container.containerID)
                await containerService.refreshContainers()
            } catch {
                errorMessage = "Failed to start container: \(error.localizedDescription)"
            }
        }
    }
    
    private func stopContainer(_ container: Container) {
        Task { @MainActor in
            do {
                try await containerService.stopContainer(container.containerID)
                await containerService.refreshContainers()
            } catch {
                errorMessage = "Failed to stop container: \(error.localizedDescription)"
            }
        }
    }
    
    private func deleteContainer(_ container: Container) {
        Task { @MainActor in
            do {
                try await containerService.deleteContainer(container.containerID)
                await containerService.refreshContainers()
                // Clear selection if deleted container was selected
                if selectedContainer?.id == container.id {
                    selectedContainer = nil
                }
            } catch {
                errorMessage = "Failed to delete container: \(error.localizedDescription)"
            }
        }
    }
    
    private func showLogs(for container: Container) {
        let logSource = containerService.createContainerLogSource(for: container)
        openWindow(id: "universal-logs", value: logSource.id)
    }
}
