//
//  SystemInspectorView.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI
import ContainerModels

struct SystemInspectorView: View {
    @Environment(ContainerService.self) private var containerService
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        List {
            Section("System Logs") {
                Button("View System Logs") {
                    let logSource = containerService.createSystemLogSource()
                    openWindow(id: "universal-logs", value: logSource.id)
                }
                
                Button("View Boot Logs") {
                    // Assuming there's a boot log source method
                    let logSource = containerService.createSystemLogSource()
                    openWindow(id: "universal-logs", value: logSource.id)
                }
                
                Button("View Error Logs") {
                    // Assuming there's an error log source method
                    let logSource = containerService.createSystemLogSource()
                    openWindow(id: "universal-logs", value: logSource.id)
                }
            }
            
            Section("Log Options") {
                Button("Export All Logs") {
                    // Export functionality could be added here
                    print("Export logs functionality")
                }
                
                Button("Clear Log Cache") {
                    // Clear cache functionality could be added here
                    print("Clear log cache functionality")
                }
            }
        }
        .navigationTitle("System Logs")
    }
}

#Preview {
    SystemInspectorView()
} 