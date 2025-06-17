//
//  InspectorView.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/17/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI
import ContainerModels

struct InspectorView: View {
    let selectedItem: SelectedItem?
    let selectedTab: AppTab
    @Environment(ContainerService.self) private var containerService
    
    var body: some View {
        Group {
            if let selectedItem = selectedItem {
                switch selectedItem {
                case .container(let container):
                    ContainerInspectorView(container: container)
                case .image(let image):
                    ImageInspectorView(image: image)
                case .system:
                    SystemInspectorView()
                }
            } else {
                // Show appropriate empty state based on the current tab
                ContentUnavailableView(
                    emptyStateTitle,
                    systemImage: emptyStateIcon,
                    description: Text(emptyStateDescription)
                )
            }
        }
        .frame(minWidth: 300, idealWidth: 350)
        .background(.ultraThinMaterial)
    }
    
    private var emptyStateTitle: String {
        switch selectedTab {
        case .containers:
            return "No Container Selected"
        case .images:
            return "No Image Selected"
        case .system:
            return "System Inspector"
        }
    }
    
    private var emptyStateIcon: String {
        switch selectedTab {
        case .containers:
            return "shippingbox"
        case .images:
            return "disc"
        case .system:
            return "gearshape"
        }
    }
    
    private var emptyStateDescription: String {
        switch selectedTab {
        case .containers:
            return "Select a container from the list to view its details and perform actions."
        case .images:
            return "Select an image from the list to view its details and perform actions."
        case .system:
            return "Manage system settings and DNS configuration."
        }
    }
}

#Preview {
    InspectorView(
        selectedItem: nil,
        selectedTab: .containers
    )
    .environment(ContainerService())
    .frame(width: 350, height: 600)
}