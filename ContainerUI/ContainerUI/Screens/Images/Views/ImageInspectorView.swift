//
//  ImageInspectorView.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

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