//
//  ContentView.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI
import ContainerModels

struct ContentView: View {
    @State private var containerService = ContainerService()
    @State private var selectedTab: AppTab = .containers
    @State private var selectedItem: SelectedItem?
    @State private var showingNewContainerSheet = false
    @State private var isInspectorPresented = false
    @Environment(\.openWindow) private var openWindow
    
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
                    Button("New Container") {
                        showingNewContainerSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        } detail: {
            // Main Content Area
            Group {
                if selectedTab == .containers {
                    ContainerListView(
                        containers: containerService.containers,
                        selectedItem: $selectedItem,
                        onContainerAction: { action, container in
                            handleContainerAction(action, container)
                        },
                        onRefresh: {
                            Task {
                                await containerService.refreshContainers()
                            }
                        }
                    )
                } else if selectedTab == .images {
                    ImageListView(
                        images: containerService.images,
                        selectedItem: $selectedItem,
                        onImageAction: { action, image in
                            handleImageAction(action, image)
                        },
                        onRefresh: {
                            Task {
                                await containerService.refreshImages()
                            }
                        }
                    )
                } else {
                    SystemListView(
                        selectedItem: $selectedItem,
                        containerService: containerService,
                        onRefresh: {
                            Task {
                                await containerService.refreshSystemInfo()
                            }
                        }
                    )
                }
            }
            .navigationTitle(selectedTab.rawValue)
            .navigationSplitViewColumnWidth(min: 400, ideal: 600, max: .infinity)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    if containerService.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    
                    // Inspector Toggle Button
                    Button {
                        isInspectorPresented.toggle()
                    } label: {
                        Label("Inspector", systemImage: "sidebar.trailing")
                    }
                    .help("Show Inspector")
                }
            }
            .inspector(isPresented: $isInspectorPresented) {
                // Inspector Content
                InspectorView(
                    selectedItem: selectedItem,
                    selectedTab: selectedTab,
                    containerService: containerService
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
                try await containerService.deleteImage(image.displayName)
                await containerService.refreshImages()
            } catch {
                print("Failed to delete image: \(error)")
            }
        }
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
            let logSource = containerService.createContainerLogSource(for: container)
            openWindow(id: "universal-logs", value: logSource.id)
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

#Preview {
    ContentView()
}