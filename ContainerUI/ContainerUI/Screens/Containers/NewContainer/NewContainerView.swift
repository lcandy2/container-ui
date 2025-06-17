//
//  NewContainerView.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI
import ContainerModels

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