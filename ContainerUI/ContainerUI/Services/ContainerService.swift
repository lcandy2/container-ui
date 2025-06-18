//
//  ContainerService.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation
import Observation
import os.log
import ContainerModels

// Create logger for main app XPC client
private let xpcClientLogger = Logger(subsystem: "cc.citrons.ContainerUI", category: "XPCClient")

// MARK: - XPC Service Protocol Reference
// The actual protocol is defined in ContainerXPCService target
@objc protocol ContainerXPCServiceProtocol {
    func listContainers(reply: @escaping ([String: Any]) -> Void)
    func listImages(reply: @escaping ([String: Any]) -> Void)
    func startContainer(_ containerID: String, reply: @escaping (Error?) -> Void)
    func stopContainer(_ containerID: String, reply: @escaping (Error?) -> Void)
    func deleteContainer(_ containerID: String, reply: @escaping (Error?) -> Void)
    func deleteImage(_ imageName: String, reply: @escaping (Error?) -> Void)
    func createAndRunContainer(image: String, name: String?, reply: @escaping (Error?) -> Void)
    func getContainerLogs(_ containerID: String, lines: NSNumber?, follow: Bool, reply: @escaping ([String: Any]) -> Void)
    func getContainerBootLogs(_ containerID: String, reply: @escaping ([String: Any]) -> Void)
    func getSystemStatus(reply: @escaping ([String: Any]) -> Void)
    func startSystem(reply: @escaping (Error?) -> Void)
    func stopSystem(reply: @escaping (Error?) -> Void)
    func restartSystem(reply: @escaping (Error?) -> Void)
    func getSystemLogs(timeFilter: String?, follow: Bool, reply: @escaping ([String: Any]) -> Void)
    func listDNSDomains(reply: @escaping ([String: Any]) -> Void)
    func createDNSDomain(_ domain: String, reply: @escaping (Error?) -> Void)
    func deleteDNSDomain(_ domain: String, reply: @escaping (Error?) -> Void)
    func setDefaultDNSDomain(_ domain: String, reply: @escaping (Error?) -> Void)
    func openTerminal(for containerID: String, reply: @escaping (Error?) -> Void)
}

@Observable @MainActor
class ContainerService {
    var containers: [Container] = []
    var images: [ContainerImage] = []
    var systemInfo: SystemInfo?
    var isLoading = false
    var errorMessage: String?
    
    private let xpcService = ContainerXPCServiceManager()

    func refreshAll() async {
        await refreshContainers()
        await refreshImages()
        await refreshSystemInfo()
    }
    
    func refreshContainers() async {
        xpcClientLogger.info("🔄 ContainerService: Starting container refresh")
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let newContainers = try await xpcService.listContainers()
            await MainActor.run {
                containers = newContainers
            }
            xpcClientLogger.info("✅ ContainerService: Container refresh completed successfully")
        } catch {
            await MainActor.run {
                let errorDescription = error.localizedDescription.lowercased()
                if errorDescription.contains("xpc connection") || 
                   errorDescription.contains("connection invalid") ||
                   errorDescription.contains("interrupted") {
                    errorMessage = "Container system is not running. Please start the system first."
                } else {
                    errorMessage = "Failed to load containers: \(error.localizedDescription)"
                }
            }
            xpcClientLogger.error("❌ ContainerService: Container refresh failed: \(error.localizedDescription)")
            print("Container list error: \(error)")
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    func refreshImages() async {
        do {
            let newImages = try await xpcService.listImages()
            await MainActor.run {
                images = newImages
            }
        } catch {
            let errorDescription = error.localizedDescription.lowercased()
            if errorDescription.contains("xpc connection") || 
               errorDescription.contains("connection invalid") ||
               errorDescription.contains("interrupted") {
                print("Image list error: Container system is not running")
            } else {
                print("Image list error: \(error)")
            }
        }
    }
    
    func startContainer(_ containerID: String) async throws {
        // Immediately update container status to starting
        await MainActor.run {
            if let index = containers.firstIndex(where: { $0.containerID == containerID }) {
                var updatedContainer = containers[index]
                // Create a new Container with starting status
                containers[index] = Container(
                    containerID: updatedContainer.containerID,
                    name: updatedContainer.name,
                    image: updatedContainer.image,
                    imageReference: updatedContainer.imageReference,
                    imageDigest: updatedContainer.imageDigest,
                    hostname: updatedContainer.hostname,
                    status: .starting,
                    os: updatedContainer.os,
                    arch: updatedContainer.arch,
                    cpus: updatedContainer.cpus,
                    memoryInBytes: updatedContainer.memoryInBytes,
                    networks: updatedContainer.networks,
                    rosetta: updatedContainer.rosetta
                )
            }
        }
        
        try await xpcService.startContainer(containerID)
    }
    
    func stopContainer(_ containerID: String) async throws {
        // Immediately update container status to stopping
        await MainActor.run {
            if let index = containers.firstIndex(where: { $0.containerID == containerID }) {
                var updatedContainer = containers[index]
                // Create a new Container with stopping status
                containers[index] = Container(
                    containerID: updatedContainer.containerID,
                    name: updatedContainer.name,
                    image: updatedContainer.image,
                    imageReference: updatedContainer.imageReference,
                    imageDigest: updatedContainer.imageDigest,
                    hostname: updatedContainer.hostname,
                    status: .stopping,
                    os: updatedContainer.os,
                    arch: updatedContainer.arch,
                    cpus: updatedContainer.cpus,
                    memoryInBytes: updatedContainer.memoryInBytes,
                    networks: updatedContainer.networks,
                    rosetta: updatedContainer.rosetta
                )
            }
        }
        
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
            
            // Only try to get DNS settings and kernel info if system is running
            var dnsSettings: [DNSDomain]
            let kernelInfo: String?
            
            if serviceStatus == .running {
                do {
                    dnsSettings = try await listDNSDomains()
                    kernelInfo = try await getKernelInfo()
                } catch {
                    // If DNS/kernel info fails but system is running, use empty defaults
                    print("Failed to get DNS/kernel info: \(error)")
                    dnsSettings = []
                    kernelInfo = nil
                }
            } else {
                // System is stopped, use empty defaults
                dnsSettings = []
                kernelInfo = nil
            }
            
            let newSystemInfo = SystemInfo(
                serviceStatus: serviceStatus,
                dnsSettings: dnsSettings,
                kernelInfo: kernelInfo
            )
            
            await MainActor.run {
                systemInfo = newSystemInfo
            }
        } catch {
            print("Failed to refresh system info: \(error)")
            // Create a default SystemInfo with stopped status
            await MainActor.run {
                systemInfo = SystemInfo(
                    serviceStatus: .stopped,
                    dnsSettings: [],
                    kernelInfo: nil
                )
            }
        }
    }
    
    func getSystemStatus() async throws -> SystemServiceStatus {
        // Use container ls as a reliable way to check if system is running
        // When system is stopped: container ls fails with XPC connection error
        // When system is running: container ls succeeds (may return empty list)
        do {
            _ = try await xpcService.listContainers()
            // If listContainers succeeds, system is running
            return .running
        } catch {
            // Check if the error indicates system is not running
            let errorDescription = error.localizedDescription.lowercased()
            if errorDescription.contains("xpc connection") || 
               errorDescription.contains("connection invalid") ||
               errorDescription.contains("interrupted") {
                // System is not running
                return .stopped
            } else {
                // Try the original system status method as fallback
                do {
                    return try await xpcService.getSystemStatus()
                } catch {
                    // If both methods fail, assume system is stopped
                    return .stopped
                }
            }
        }
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

// MARK: - XPC Service Manager

class ContainerXPCServiceManager {
    private var connection: NSXPCConnection?
    
    init() {
        setupConnection()
    }
    
    private func setupConnection() {
        xpcClientLogger.info("🔌 Main App: Setting up XPC connection to cc.citrons.ContainerUI.ContainerXPCService")
        connection = NSXPCConnection(serviceName: "cc.citrons.ContainerUI.ContainerXPCService")
        connection?.remoteObjectInterface = NSXPCInterface(with: ContainerXPCServiceProtocol.self)
        
        connection?.interruptionHandler = {
            xpcClientLogger.warning("🔌 Main App: XPC connection interrupted")
        }
        
        connection?.invalidationHandler = {
            xpcClientLogger.info("❌ Main App: XPC connection invalidated")
        }
        
        connection?.resume()
        xpcClientLogger.info("✅ Main App: XPC connection established and resumed")
    }
    
    // MARK: - Container Management
    
    func listContainers() async throws -> [Container] {
        xpcClientLogger.info("📋 Main App: Requesting container list from XPC service")
        guard let connection = connection else {
            xpcClientLogger.error("❌ Main App: No XPC connection available")
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            // Add timeout to prevent hanging
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                xpcClientLogger.error("⏰ Main App: XPC call timed out")
                continuation.resume(throwing: ContainerError.commandFailed("XPC Service connection timed out"))
            }
            
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.listContainers { result in
                timeoutTask.cancel()
                xpcClientLogger.info("📨 Main App: Received response from XPC service")
                if let containers = result["containers"] as? [[String: Any]] {
                    let parsedContainers = containers.compactMap { dict -> Container? in
                        self.parseContainerFromDict(dict)
                    }
                    xpcClientLogger.info("✅ Main App: Successfully parsed \(parsedContainers.count) containers")
                    continuation.resume(returning: parsedContainers)
                } else if let error = result["error"] as? String {
                    xpcClientLogger.error("❌ Main App: XPC service returned error: \(error)")
                    continuation.resume(throwing: ContainerError.commandFailed(error))
                } else {
                    xpcClientLogger.warning("⚠️ Main App: XPC service returned unexpected response")
                    continuation.resume(returning: [])
                }
            }
        }
    }
    
    func listImages() async throws -> [ContainerImage] {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.listImages { result in
                if let images = result["images"] as? [[String: Any]] {
                    let parsedImages = images.compactMap { dict -> ContainerImage? in
                        self.parseImageFromDict(dict)
                    }
                    continuation.resume(returning: parsedImages)
                } else if let error = result["error"] as? String {
                    continuation.resume(throwing: ContainerError.commandFailed(error))
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }
    
    func startContainer(_ containerID: String) async throws {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.startContainer(containerID) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func stopContainer(_ containerID: String) async throws {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.stopContainer(containerID) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func deleteContainer(_ containerID: String) async throws {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.deleteContainer(containerID) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func deleteImage(_ imageName: String) async throws {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.deleteImage(imageName) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func createAndRunContainer(image: String, name: String? = nil) async throws {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.createAndRunContainer(image: image, name: name) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Log Operations
    
    func getContainerLogs(_ containerID: String, lines: Int? = nil, follow: Bool = false) async throws -> String {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            let linesNumber = lines != nil ? NSNumber(value: lines!) : nil
            service.getContainerLogs(containerID, lines: linesNumber, follow: follow) { result in
                if let logs = result["logs"] as? String {
                    continuation.resume(returning: logs)
                } else if let error = result["error"] as? String {
                    continuation.resume(throwing: ContainerError.commandFailed(error))
                } else {
                    continuation.resume(returning: "")
                }
            }
        }
    }
    
    func getContainerBootLogs(_ containerID: String) async throws -> String {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.getContainerBootLogs(containerID) { result in
                if let logs = result["logs"] as? String {
                    continuation.resume(returning: logs)
                } else if let error = result["error"] as? String {
                    continuation.resume(throwing: ContainerError.commandFailed(error))
                } else {
                    continuation.resume(returning: "")
                }
            }
        }
    }
    
    // MARK: - System Management
    
    func getSystemStatus() async throws -> SystemServiceStatus {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.getSystemStatus { result in
                if let statusString = result["status"] as? String {
                    let status: SystemServiceStatus = statusString == "running" ? .running : .stopped
                    continuation.resume(returning: status)
                } else if let error = result["error"] as? String {
                    continuation.resume(throwing: ContainerError.commandFailed(error))
                } else {
                    continuation.resume(returning: .stopped)
                }
            }
        }
    }
    
    func startSystem() async throws {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.startSystem { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func stopSystem() async throws {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.stopSystem { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func restartSystem() async throws {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.restartSystem { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func getSystemLogs(timeFilter: String? = nil, follow: Bool = false) async throws -> String {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.getSystemLogs(timeFilter: timeFilter, follow: follow) { result in
                if let logs = result["logs"] as? String {
                    continuation.resume(returning: logs)
                } else if let error = result["error"] as? String {
                    continuation.resume(throwing: ContainerError.commandFailed(error))
                } else {
                    continuation.resume(returning: "")
                }
            }
        }
    }
    
    // MARK: - DNS Management
    
    func listDNSDomains() async throws -> [DNSDomain] {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.listDNSDomains { result in
                if let domains = result["domains"] as? [[String: Any]] {
                    let parsedDomains = domains.compactMap { dict -> DNSDomain? in
                        guard let domain = dict["domain"] as? String else { return nil }
                        let isDefault = dict["isDefault"] as? Bool ?? false
                        return DNSDomain(domain: domain, isDefault: isDefault)
                    }
                    continuation.resume(returning: parsedDomains)
                } else if let error = result["error"] as? String {
                    continuation.resume(throwing: ContainerError.commandFailed(error))
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }
    
    func createDNSDomain(_ domain: String) async throws {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.createDNSDomain(domain) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func deleteDNSDomain(_ domain: String) async throws {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.deleteDNSDomain(domain) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func setDefaultDNSDomain(_ domain: String) async throws {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.setDefaultDNSDomain(domain) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Terminal Operations
    
    func openTerminal(for containerID: String) async throws {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.openTerminal(for: containerID) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func parseContainerFromDict(_ dict: [String: Any]) -> Container? {
        guard let containerID = dict["containerID"] as? String,
              let name = dict["name"] as? String,
              let image = dict["image"] as? String,
              let statusString = dict["status"] as? String,
              let os = dict["os"] as? String,
              let arch = dict["arch"] as? String else {
            return nil
        }
        
        let status: ContainerStatus
        switch statusString.lowercased() {
        case "running":
            status = .running
        case "stopped":
            status = .stopped
        default:
            status = .exited
        }
        
        let imageReference = dict["imageReference"] as? String ?? image
        let imageDigest = dict["imageDigest"] as? String ?? ""
        let hostname = dict["hostname"] as? String ?? name
        let cpus = dict["cpus"] as? Int ?? 0
        let memoryInBytes = dict["memoryInBytes"] as? Int64 ?? 0
        let rosetta = dict["rosetta"] as? Bool ?? false
        
        // Parse networks
        var networks: [ContainerNetwork] = []
        if let networkArray = dict["networks"] as? [[String: Any]] {
            networks = networkArray.compactMap { networkDict in
                guard let address = networkDict["address"] as? String,
                      let gateway = networkDict["gateway"] as? String,
                      let network = networkDict["network"] as? String else {
                    return nil
                }
                let hostname = networkDict["hostname"] as? String
                return ContainerNetwork(hostname: hostname, address: address, gateway: gateway, network: network)
            }
        }
        
        return Container(
            containerID: containerID,
            name: name,
            image: image,
            imageReference: imageReference,
            imageDigest: imageDigest,
            hostname: hostname,
            status: status,
            os: os,
            arch: arch,
            cpus: cpus,
            memoryInBytes: memoryInBytes,
            networks: networks,
            rosetta: rosetta
        )
    }
    
    private func parseImageFromDict(_ dict: [String: Any]) -> ContainerImage? {
        guard let name = dict["name"] as? String,
              let tag = dict["tag"] as? String,
              let size = dict["size"] as? Int64 else {
            return nil
        }
        
        let reference = dict["reference"] as? String ?? "\(name):\(tag)"
        let digest = dict["digest"] as? String ?? ""
        
        // Parse registry and repository from reference or name
        let registry: String
        let repository: String
        
        if reference.contains("/") {
            let parts = reference.split(separator: "/", maxSplits: 1)
            if parts.count == 2 {
                registry = String(parts[0])
                repository = String(parts[1]).split(separator: ":").first.map(String.init) ?? name
            } else {
                registry = "docker.io"
                repository = name
            }
        } else {
            registry = "docker.io"
            repository = name
        }
        
        let mediaType = dict["mediaType"] as? String ?? "application/vnd.docker.distribution.manifest.v2+json"
        
        return ContainerImage(
            name: name,
            tag: tag,
            digest: digest,
            reference: reference,
            registry: registry,
            repository: repository,
            mediaType: mediaType,
            size: size
        )
    }
    
    deinit {
        connection?.invalidate()
    }
}

