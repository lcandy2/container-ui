//
//  ImageListView.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

struct ImageListView: View {
    let images: [ContainerImage]
    @Binding var selectedItem: SelectedItem?
    let onImageAction: (String, ContainerImage) -> Void
    
    var body: some View {
        if images.isEmpty {
            ContentUnavailableView(
                "No Images",
                systemImage: "disc",
                description: Text("Pull an image to get started")
            )
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
                        Button("Create Container", systemImage: "plus.rectangle") {
                            onImageAction("create", image)
                        }
                        
                        Divider()
                        
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            onImageAction("delete", image)
                        }
                    }
            }
        }
    }
}