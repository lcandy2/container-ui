//
//  ContainerUIApp.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

@main
struct ContainerUIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        WindowGroup("Logs", id: "universal-logs", for: String.self) { $logSourceId in
            if let logSourceId = logSourceId {
                UniversalLogsWindow(logSourceId: logSourceId)
            } else {
                ContentUnavailableView(
                    "No Log Source",
                    systemImage: "doc.text",
                    description: Text("Unable to load log source")
                )
            }
        }
        .windowResizability(.contentSize)
        .windowStyle(.titleBar)
        .defaultSize(width: 800, height: 600)
    }
}
