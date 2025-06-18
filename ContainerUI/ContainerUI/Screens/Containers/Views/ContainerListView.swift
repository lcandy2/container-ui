//
//  ContainerListView.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI
import ContainerModels
import ButtonKit

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
                    AsyncButton {
                        try await containerService.startSystem()
                        await containerService.refreshSystemInfo()
                        await containerService.refreshContainers()
                    } label: {
                        Text("Turn On")
                    }
                    .buttonStyle(.borderedProminent)
                    .asyncButtonStyle(.overlay)
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
                            AsyncButton {
                                try await startContainer(container)
                            } label: {
                                Label("Start", systemImage: "play.fill")
                            }
                            .disabled(container.status == .running)
                            .asyncButtonStyle(.none)
                            
                            AsyncButton {
                                try await stopContainer(container)
                            } label: {
                                Label("Stop", systemImage: "stop.fill")
                            }
                            .disabled(container.status != .running)
                            .asyncButtonStyle(.none)
                            
                            Button("View Logs", systemImage: "doc.text") {
                                showLogs(for: container)
                            }
                            
                            Divider()
                            
                            AsyncButton {
                                try await deleteContainer(container)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .asyncButtonStyle(.none)
                        }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                if containerService.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button {
                        Task {
                            await containerService.refreshContainers()
                        }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                }
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
    
    private func startContainer(_ container: Container) async throws {
        try await containerService.startContainer(container.containerID)
        await containerService.refreshContainers()
    }
    
    private func stopContainer(_ container: Container) async throws {
        try await containerService.stopContainer(container.containerID)
        await containerService.refreshContainers()
    }
    
    private func deleteContainer(_ container: Container) async throws {
        try await containerService.deleteContainer(container.containerID)
        await containerService.refreshContainers()
        // Clear selection if deleted container was selected
        if selectedContainer?.id == container.id {
            selectedContainer = nil
        }
    }
    
    private func showLogs(for container: Container) {
        let logSource = containerService.createContainerLogSource(for: container)
        openWindow(id: "universal-logs", value: logSource.id)
    }
}
