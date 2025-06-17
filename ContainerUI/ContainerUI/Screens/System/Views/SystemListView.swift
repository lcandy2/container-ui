//
//  SystemListView.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI
import ContainerModels

struct SystemListView: View {
    @Binding var selectedItem: SelectedItem?
    @Environment(ContainerService.self) private var containerService
    
    var body: some View {
        VStack(spacing: 20) {
            // System Status Card
            Button(action: {
                selectedItem = .system
            }) {
                SystemStatusCard(systemInfo: containerService.systemInfo)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Refresh") {
                    Task { @MainActor in
                        await containerService.refreshSystemInfo()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
    }
}