//
//  ContainerInspectorView.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

struct ContainerInspectorView: View {
    let container: Container
    @ObservedObject var containerService: ContainerService
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        List {
            Section("Container Info") {
                LabeledContent("Container ID") {
                    Text(container.containerID)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
                LabeledContent("Short ID", value: container.name)
                LabeledContent("Image", value: container.image)
                LabeledContent("Status") {
                    HStack {
                        Circle()
                            .fill(container.status.color)
                            .frame(width: 8, height: 8)
                        Text(container.status.displayName)
                    }
                }
            }
            
            Section("System Info") {
                LabeledContent("Operating System", value: container.os)
                LabeledContent("Architecture", value: container.arch)
                if let addr = container.addr {
                    LabeledContent("IP Address", value: addr)
                } else {
                    LabeledContent("IP Address", value: "Not available")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Actions") {
                Button("Start Container") {
                    Task {
                        do {
                            try await containerService.startContainer(container.containerID)
                            await containerService.refreshContainers()
                        } catch {
                            print("Failed to start container: \(error)")
                        }
                    }
                }
                .disabled(container.status == .running)
                
                Button("Stop Container") {
                    Task {
                        do {
                            try await containerService.stopContainer(container.containerID)
                            await containerService.refreshContainers()
                        } catch {
                            print("Failed to stop container: \(error)")
                        }
                    }
                }
                .disabled(container.status != .running)
                
                Button("Restart Container") {
                    Task {
                        do {
                            try await containerService.stopContainer(container.containerID)
                            try await containerService.startContainer(container.containerID)
                            await containerService.refreshContainers()
                        } catch {
                            print("Failed to restart container: \(error)")
                        }
                    }
                }
            }
            
            Section("Debug") {
                Button("View Logs") {
                    let logSource = containerService.createContainerLogSource(for: container)
                    openWindow(id: "universal-logs", value: logSource.id)
                }
                
                Button("View Boot Logs") {
                    let logSource = containerService.createContainerBootLogSource(for: container)
                    openWindow(id: "universal-logs", value: logSource.id)
                }
                
                Button("Open Terminal") {
                    Task {
                        do {
                            try await containerService.openTerminal(for: container.containerID)
                        } catch {
                            print("Failed to open terminal: \(error)")
                        }
                    }
                }
            }
            
            Section("Danger Zone") {
                Button("Delete Container", role: .destructive) {
                    Task {
                        do {
                            try await containerService.deleteContainer(container.containerID)
                            await containerService.refreshContainers()
                        } catch {
                            print("Failed to delete container: \(error)")
                        }
                    }
                }
            }
        }
        .navigationTitle("Container Details")
    }
}