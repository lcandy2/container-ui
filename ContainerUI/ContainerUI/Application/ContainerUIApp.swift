//
//  ContainerUIApp.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI
import Sparkle

@main
struct ContainerUIApp: App {
    @State private var containerService = ContainerService()
    private let updaterController: SPUStandardUpdaterController
    
    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(containerService)
        }
        
        WindowGroup("Logs", id: "universal-logs", for: String.self) { $logSourceId in
            if let logSourceId = logSourceId {
                UniversalLogsWindow(logSourceId: logSourceId)
                    .environment(containerService)
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
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    updaterController.updater.checkForUpdates()
                }
                .keyboardShortcut("u", modifiers: .command)
            }
        }
    }
}
