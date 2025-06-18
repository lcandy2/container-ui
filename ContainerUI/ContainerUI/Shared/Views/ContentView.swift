//
//  ContentView.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

struct ContentView: View {
    @Environment(ContainerService.self) private var containerService
    @State private var selectedTab: AppTab = .containers
    
    var body: some View {
        NavigationSplitView {
            // Left Sidebar
            VStack(spacing: 0) {
                // Main navigation list
                List(selection: $selectedTab) {
                    ForEach([AppTab.containers, AppTab.images], id: \.self) { tab in
                        NavigationLink(value: tab) {
                            Label(tab.rawValue, systemImage: tab.systemImage)
                        }
                    }
                }
                
                // Bottom section for system
                Divider()
                
                List(selection: $selectedTab) {
                    NavigationLink(value: AppTab.system) {
                        Label(AppTab.system.rawValue, systemImage: AppTab.system.systemImage)
                    }
                }
                .frame(height: 44)
                .scrollDisabled(true)
            }
            .navigationTitle("Container UI")
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 250)
        } detail: {
            // Main Content Area
            Group {
                switch selectedTab {
                case .containers:
                    ContainerListView()
                case .images:
                    ImageListView()
                case .system:
                    SystemListView()
                }
            }
            .navigationTitle(selectedTab.rawValue)
            .navigationSplitViewColumnWidth(min: 400, ideal: 600, max: .infinity)
        }
        .task {
            await refreshAll()
        }
    }
    
    private func refreshAll() async {
        await containerService.refreshContainers()
        await containerService.refreshImages()
        await containerService.refreshSystemInfo()
    }
}

#Preview {
    ContentView()
}