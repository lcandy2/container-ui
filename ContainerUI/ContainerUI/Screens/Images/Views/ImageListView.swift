//
//  ImageListView.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI
import ContainerModels

struct ImageListView: View {
    @Environment(ContainerService.self) private var containerService
    
    @State private var selectedImage: ContainerImage?
    @State private var isInspectorPresented = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            // Check if system is stopped
            if containerService.systemInfo?.serviceStatus == .stopped {
                ContentUnavailableView {
                    Label("Container System is Not Running", systemImage: "server.rack")
                } actions: {
                    Button("Turn On") {
                        Task {
                            do {
                                try await containerService.startSystem()
                                await containerService.refreshSystemInfo()
                                await containerService.refreshImages()
                            } catch {
                                errorMessage = "Failed to start system: \(error.localizedDescription)"
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if containerService.images.isEmpty {
                ContentUnavailableView(
                    "No Images",
                    systemImage: "externaldrive",
                    description: Text("Pull an image to get started")
                )
            } else {
                List(containerService.images, id: \.id, selection: $selectedImage) { image in
                    ImageRow(image: image)
                        .tag(image)
                        .contextMenu {
                            Button("Create Container", systemImage: "plus.rectangle") {
                                createContainer(from: image)
                            }
                            
                            Divider()
                            
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                deleteImage(image)
                            }
                        }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button("Refresh") {
                    Task { @MainActor in
                        await containerService.refreshImages()
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
            if let selectedImage = selectedImage {
                ImageInspectorView(image: selectedImage)
            } else {
                ContentUnavailableView(
                    "No Image Selected",
                    systemImage: "externaldrive",
                    description: Text("Select an image to view details")
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
    
    // MARK: - Image Actions
    
    private func createContainer(from image: ContainerImage) {
        Task { @MainActor in
            do {
                try await containerService.createAndRunContainer(image: image.displayName)
                await containerService.refreshContainers()
            } catch {
                errorMessage = "Failed to create container: \(error.localizedDescription)"
            }
        }
    }
    
    private func deleteImage(_ image: ContainerImage) {
        Task { @MainActor in
            do {
                try await containerService.deleteImage(image.displayName)
                await containerService.refreshImages()
                // Clear selection if deleted image was selected
                if selectedImage?.id == image.id {
                    selectedImage = nil
                }
            } catch {
                errorMessage = "Failed to delete image: \(error.localizedDescription)"
            }
        }
    }
}
