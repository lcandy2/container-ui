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
        ScrollView {
            VStack(alignment: .leading) {
                Section("System Logs") {
                    Button("View System Logs") {
                        let logSource = containerService.createSystemLogSource()
                        openWindow(id: "universal-logs", value: logSource.id)
                    }
                }
            }
            .padding(.vertical)
            .frame(maxWidth: .infinity)
            
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SystemInspectorView()
} 
