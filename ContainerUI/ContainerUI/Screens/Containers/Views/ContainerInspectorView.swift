//
//  ContainerInspectorView.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI
import ContainerModels

struct ContainerInspectorView: View {
    let container: Container
    @Bindable var containerService: ContainerService
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        List {
            Section("Container Info") {
                LabeledContent("Container ID") {
                    Text(container.containerID)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
                LabeledContent("Display Name", value: container.displayName)
                LabeledContent("Hostname", value: container.hostname)
                LabeledContent("Image", value: container.image)
                LabeledContent("Image Reference") {
                    Text(container.imageReference)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
                LabeledContent("Image Digest") {
                    Text(container.imageDigest.prefix(20) + "...")
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
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
                LabeledContent("Rosetta", value: container.rosetta ? "Enabled" : "Disabled")
            }
            
            Section("Resources") {
                LabeledContent("CPUs", value: "\(container.cpus)")
                LabeledContent("Memory", value: container.memoryDisplay)
            }
            
            Section("Network") {
                if container.networks.isEmpty {
                    Text("No network connections")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(container.networks) { network in
                        VStack(alignment: .leading, spacing: 4) {
                            LabeledContent("Network", value: network.network)
                            LabeledContent("Address", value: network.address)
                            LabeledContent("Gateway", value: network.gateway)
                            if let hostname = network.hostname {
                                LabeledContent("Hostname", value: hostname)
                            }
                        }
                        .padding(.vertical, 4)
                    }
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