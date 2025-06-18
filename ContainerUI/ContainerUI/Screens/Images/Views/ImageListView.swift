//
//  ImageListView.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI
import ContainerModels
import ButtonKit

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
                    Label("Container System Stopped", systemImage: "server.rack")
                } actions: {
                    AsyncButton {
                        try await containerService.startSystem()
                        await containerService.refreshSystemInfo()
                        await containerService.refreshImages()
                    } label: {
                        Text("Turn On")
                    }
                    .buttonStyle(.borderedProminent)
                    .asyncButtonStyle(.overlay)
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
                            AsyncButton {
                                try await createContainer(from: image)
                            } label: {
                                Label("Create Container", systemImage: "plus.rectangle")
                            }
                            .asyncButtonStyle(.none)
                            
                            Divider()
                            
                            AsyncButton {
                                try await deleteImage(image)
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
                            await containerService.refreshImages()
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
    
    private func createContainer(from image: ContainerImage) async throws {
        try await containerService.createAndRunContainer(image: image.displayName)
        await containerService.refreshContainers()
    }
    
    private func deleteImage(_ image: ContainerImage) async throws {
        try await containerService.deleteImage(image.displayName)
        await containerService.refreshImages()
        // Clear selection if deleted image was selected
        if selectedImage?.id == image.id {
            selectedImage = nil
        }
    }
}
