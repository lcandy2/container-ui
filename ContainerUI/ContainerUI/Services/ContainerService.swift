//
//  ContainerService.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation
internal import Combine

@MainActor
class ContainerService: ObservableObject {
    @Published var containers: [Container] = []
    @Published var images: [ContainerImage] = []
    @Published var systemInfo: SystemInfo?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let xpcService = ContainerXPCServiceManager()
    
    func refreshContainers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            containers = try await xpcService.listContainers()
        } catch {
            errorMessage = "Failed to load containers: \(error.localizedDescription)"
            print("Container list error: \(error)")
        }
        
        isLoading = false
    }
    
    func refreshImages() async {
        do {
            images = try await xpcService.listImages()
        } catch {
            print("Image list error: \(error)")
        }
    }
    
    func startContainer(_ containerID: String) async throws {
        try await xpcService.startContainer(containerID)
    }
    
    func stopContainer(_ containerID: String) async throws {
        try await xpcService.stopContainer(containerID)
    }
    
    func deleteContainer(_ containerID: String) async throws {
        try await xpcService.deleteContainer(containerID)
    }
    
    func deleteImage(_ imageName: String) async throws {
        try await xpcService.deleteImage(imageName)
    }
    
    func getContainerLogs(_ containerID: String, lines: Int? = nil, follow: Bool = false) async throws -> String {
        return try await xpcService.getContainerLogs(containerID, lines: lines, follow: follow)
    }
    
    func getContainerBootLogs(_ containerID: String) async throws -> String {
        return try await xpcService.getContainerBootLogs(containerID)
    }
    
    func createAndRunContainer(image: String, name: String? = nil) async throws {
        try await xpcService.createAndRunContainer(image: image, name: name)
    }
    
    func openTerminal(for containerID: String) async throws {
        try await xpcService.openTerminal(for: containerID)
    }
    
    
    // MARK: - System Management
    
    func refreshSystemInfo() async {
        do {
            let serviceStatus = try await getSystemStatus()
            let dnsSettings = try await listDNSDomains()
            let kernelInfo = try await getKernelInfo()
            
            systemInfo = SystemInfo(
                serviceStatus: serviceStatus,
                dnsSettings: dnsSettings,
                kernelInfo: kernelInfo
            )
        } catch {
            print("Failed to refresh system info: \(error)")
        }
    }
    
    func getSystemStatus() async throws -> SystemServiceStatus {
        return try await xpcService.getSystemStatus()
    }
    
    func startSystem() async throws {
        try await xpcService.startSystem()
    }
    
    func stopSystem() async throws {
        try await xpcService.stopSystem()
    }
    
    func restartSystem() async throws {
        try await xpcService.restartSystem()
    }
    
    func listDNSDomains() async throws -> [DNSDomain] {
        return try await xpcService.listDNSDomains()
    }
    
    func createDNSDomain(_ domain: String) async throws {
        try await xpcService.createDNSDomain(domain)
    }
    
    func deleteDNSDomain(_ domain: String) async throws {
        try await xpcService.deleteDNSDomain(domain)
    }
    
    func setDefaultDNSDomain(_ domain: String) async throws {
        try await xpcService.setDefaultDNSDomain(domain)
    }
    
    func getSystemLogs(timeFilter: String? = nil, follow: Bool = false) async throws -> String {
        return try await xpcService.getSystemLogs(timeFilter: timeFilter, follow: follow)
    }
    
    func getKernelInfo() async throws -> String? {
        // This might not have a direct query command, so we'll return nil for now
        // In a real implementation, you might need to check configuration files
        return nil
    }
    
    
    // MARK: - Log Sources
    
    func createContainerLogSource(for container: Container) -> LogSource {
        LogSource(
            id: "container-\(container.containerID)",
            title: "Container: \(container.name)",
            type: .container(containerID: container.containerID),
            supportsRealTime: true,
            availableFilters: [.timeRange, .textSearch]
        )
    }
    
    func createContainerBootLogSource(for container: Container) -> LogSource {
        LogSource(
            id: "boot-\(container.containerID)",
            title: "Boot Logs: \(container.name)",
            type: .containerBoot(containerID: container.containerID),
            supportsRealTime: false,
            availableFilters: [.textSearch]
        )
    }
    
    func createSystemLogSource() -> LogSource {
        LogSource(
            id: "system",
            title: "System Logs",
            type: .system,
            supportsRealTime: false,
            availableFilters: [.timeRange, .textSearch]
        )
    }
    
    func fetchLogs(for logSource: LogSource, timeFilter: String? = nil, lines: Int? = nil) async throws -> String {
        switch logSource.type {
        case .container(let containerID):
            return try await getContainerLogs(containerID, lines: lines)
        case .containerBoot(let containerID):
            return try await getContainerBootLogs(containerID)
        case .system:
            return try await getSystemLogs(timeFilter: timeFilter)
        case .builder, .registry:
            // Future implementation
            return "Logs not yet implemented for \(logSource.type.displayName)"
        }
    }
}

enum ContainerError: LocalizedError {
    case commandFailed(String)
    case containerNotFound
    case invalidOutput
    
    var errorDescription: String? {
        switch self {
        case .commandFailed(let message):
            return "Command failed: \(message)"
        case .containerNotFound:
            return "Container not found"
        case .invalidOutput:
            return "Invalid command output"
        }
    }
}
