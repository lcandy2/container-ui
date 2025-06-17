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
    @State private var showingNewContainerSheet = false
    
    var body: some View {
        NavigationSplitView {
            // Left Sidebar
            List(selection: $selectedTab) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    NavigationLink(value: tab) {
                        Label(tab.rawValue, systemImage: tab.systemImage)
                    }
                }
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
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("New Container") {
                        showingNewContainerSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .task {
            await refreshAll()
        }
        .sheet(isPresented: $showingNewContainerSheet) {
            NewContainerView()
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