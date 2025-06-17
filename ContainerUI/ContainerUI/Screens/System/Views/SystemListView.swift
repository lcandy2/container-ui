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
    @Environment(ContainerService.self) private var containerService
    
    @State private var isSystemSelected = false
    @State private var isInspectorPresented = true
    
    var body: some View {
        VStack(spacing: 20) {
            // System Status Card
            Button(action: {
                isSystemSelected = true
            }) {
                SystemStatusCard(systemInfo: containerService.systemInfo)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding()
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button("Refresh") {
                    Task { @MainActor in
                        await containerService.refreshSystemInfo()
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
        }
        .inspector(isPresented: $isInspectorPresented) {
            if isSystemSelected {
                SystemInspectorView()
            } else {
                ContentUnavailableView(
                    "No System Item Selected",
                    systemImage: "gearshape",
                    description: Text("Select a system item to view details")
                )
            }
        }
        .onAppear {
            // Auto-select system when view appears
            isSystemSelected = true
        }
    }
}