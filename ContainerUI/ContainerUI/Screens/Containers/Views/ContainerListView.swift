//
//  ContainerListView.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

struct ContainerListView: View {
    let containers: [Container]
    @Binding var selectedItem: SelectedItem?
    let onContainerAction: (String, Container) -> Void
    
    var body: some View {
        if containers.isEmpty {
            ContentUnavailableView(
                "No Containers",
                systemImage: "shippingbox",
                description: Text("Create a container to get started")
            )
        } else {
            List(containers, id: \.id, selection: Binding(
                get: {
                    if case .container(let container) = selectedItem {
                        return container
                    }
                    return nil
                },
                set: { container in
                    if let container = container {
                        selectedItem = .container(container)
                    }
                }
            )) { container in
                ContainerRow(container: container)
                    .tag(container)
                    .contextMenu {
                        Button("Start", systemImage: "play.fill") {
                            onContainerAction("start", container)
                        }
                        .disabled(container.status == .running)
                        
                        Button("Stop", systemImage: "stop.fill") {
                            onContainerAction("stop", container)
                        }
                        .disabled(container.status != .running)
                        
                        Button("View Logs", systemImage: "doc.text") {
                            onContainerAction("logs", container)
                        }
                        
                        Divider()
                        
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            onContainerAction("delete", container)
                        }
                    }
            }
        }
    }
}