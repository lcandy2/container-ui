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
    
    private var containerCommand: String {
        let possiblePaths = [
            "/usr/local/bin/container",
            "/opt/homebrew/bin/container",
            "/usr/bin/container"
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        return "container" // Fallback to PATH lookup
    }
    
    func refreshContainers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Ensure container system is started
            try await ensureContainerSystemStarted()
            
            let output = try await executeCommand([containerCommand, "ls", "-a", "--format", "json"])
            containers = try parseContainerList(output)
        } catch {
            errorMessage = "Failed to load containers: \(error.localizedDescription)"
            print("Container list error: \(error)")
        }
        
        isLoading = false
    }
    
    func refreshImages() async {
        do {
            let output = try await executeCommand([containerCommand, "images", "list"])
            images = try parseImageList(output)
        } catch {
            print("Image list error: \(error)")
        }
    }
    
    private func ensureContainerSystemStarted() async throws {
        // Check if system is already running by trying a simple command
        do {
            _ = try await executeCommand([containerCommand, "ls", "-a", "--format", "json"])
        } catch {
            // If list fails, try starting the system
            print("Container system not running, attempting to start...")
            _ = try await executeCommand([containerCommand, "system", "start"])
            
            // Wait a moment for system to initialize
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        }
    }
    
    func startContainer(_ containerID: String) async throws {
        _ = try await executeCommand([containerCommand, "start", containerID])
    }
    
    func stopContainer(_ containerID: String) async throws {
        _ = try await executeCommand([containerCommand, "stop", containerID])
    }
    
    func deleteContainer(_ containerID: String) async throws {
        _ = try await executeCommand([containerCommand, "delete", containerID])
    }
    
    func deleteImage(_ imageName: String) async throws {
        _ = try await executeCommand([containerCommand, "images", "delete", imageName])
    }
    
    func getContainerLogs(_ containerID: String, lines: Int? = nil, follow: Bool = false) async throws -> String {
        var args = [containerCommand, "logs"]
        if let lines = lines {
            args.append(contentsOf: ["-n", "\(lines)"])
        }
        if follow {
            args.append("-f")
        }
        args.append(containerID)
        
        return try await executeCommand(args)
    }
    
    func getContainerBootLogs(_ containerID: String) async throws -> String {
        let args = [containerCommand, "logs", "--boot", containerID]
        return try await executeCommand(args)
    }
    
    func createAndRunContainer(image: String, name: String? = nil) async throws {
        var args = [containerCommand, "run", "-d"]
        if let name = name {
            args.append(contentsOf: ["--name", name])
        }
        args.append(image)
        
        _ = try await executeCommand(args)
    }
    
    func openTerminal(for containerID: String) async throws {
        let process = Process()
        process.launchPath = "/usr/bin/open"
        process.arguments = ["-a", "Terminal", "--args", containerCommand, "exec", "-ti", containerID, "sh"]
        process.launch()
    }
    
    private func executeCommand(_ arguments: [String]) async throws -> String {
        // Check if we can access the container binary
        let containerPath = containerCommand
        
        // For sandboxed apps, we need to check if the container tool is accessible
        guard FileManager.default.isExecutableFile(atPath: containerPath) || containerPath == "container" else {
            throw ContainerError.commandFailed("Container CLI tool not found at \(containerPath). Please ensure Apple's container tool is installed and accessible.")
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let pipe = Pipe()
            let errorPipe = Pipe()
            
            process.standardOutput = pipe
            process.standardError = errorPipe
            
            // Try direct execution first
            if containerPath != "container" && FileManager.default.isExecutableFile(atPath: containerPath) {
                process.executableURL = URL(fileURLWithPath: containerPath)
                process.arguments = Array(arguments.dropFirst())
            } else {
                // Fallback to shell execution for PATH lookup
                process.executableURL = URL(fileURLWithPath: "/bin/sh")
                let commandString = arguments.joined(separator: " ")
                process.arguments = ["-c", "PATH=/usr/local/bin:/opt/homebrew/bin:$PATH; \(commandString)"]
            }
            
            process.terminationHandler = { process in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                
                if process.terminationStatus == 0 {
                    let output = String(data: data, encoding: .utf8) ?? ""
                    continuation.resume(returning: output)
                } else {
                    let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                    let fullError = "Command failed: \(errorMessage)\n\nThis may be due to sandboxing restrictions. For development, consider temporarily disabling App Sandbox in project settings."
                    continuation.resume(throwing: ContainerError.commandFailed(fullError))
                }
            }
            
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func parseContainerList(_ output: String) throws -> [Container] {
        let trimmedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedOutput.isEmpty else {
            return []
        }
        
        // Parse JSON output from container ls -a --format json
        guard let data = trimmedOutput.data(using: .utf8) else {
            throw ContainerError.invalidOutput
        }
        
        do {
            let containerJSONList = try JSONDecoder().decode([ContainerJSON].self, from: data)
            return containerJSONList.map { $0.toContainer() }
        } catch {
            print("JSON parsing error: \(error)")
            throw ContainerError.invalidOutput
        }
    }
    
    private func parseImageList(_ output: String) throws -> [ContainerImage] {
        let trimmedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedOutput.isEmpty else {
            return []
        }
        
        let lines = trimmedOutput.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        // Skip header line if present
        let dataLines = lines.count > 1 && lines[0].contains("NAME") ? Array(lines.dropFirst()) : lines
        
        var images: [ContainerImage] = []
        
        for line in dataLines {
            // Split by multiple spaces to handle the column format properly
            let components = line.split(separator: " ", omittingEmptySubsequences: true)
                .map { String($0) }
            
            // Expected format: NAME  TAG  DIGEST
            if components.count >= 3 {
                let name = components[0]
                let tag = components[1]
                let digest = components[2]
                
                let image = ContainerImage(
                    name: name,
                    tag: tag,
                    digest: digest
                )
                images.append(image)
            }
        }
        
        return images
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
        do {
            // Try to run a simple command to check if system is responsive
            _ = try await executeCommand([containerCommand, "system", "logs", "--last", "1m"])
            return .running
        } catch {
            // If it fails, assume system is stopped or having issues
            return .stopped
        }
    }
    
    func startSystem() async throws {
        _ = try await executeCommand([containerCommand, "system", "start"])
    }
    
    func stopSystem() async throws {
        _ = try await executeCommand([containerCommand, "system", "stop"])
    }
    
    func restartSystem() async throws {
        _ = try await executeCommand([containerCommand, "system", "restart"])
    }
    
    func listDNSDomains() async throws -> [DNSDomain] {
        let output = try await executeCommand([containerCommand, "system", "dns", "list"])
        return try parseDNSDomains(output)
    }
    
    func createDNSDomain(_ domain: String) async throws {
        _ = try await executeCommand([containerCommand, "system", "dns", "create", domain])
    }
    
    func deleteDNSDomain(_ domain: String) async throws {
        _ = try await executeCommand([containerCommand, "system", "dns", "delete", domain])
    }
    
    func setDefaultDNSDomain(_ domain: String) async throws {
        _ = try await executeCommand([containerCommand, "system", "dns", "default", domain])
    }
    
    func getSystemLogs(timeFilter: String? = nil, follow: Bool = false) async throws -> String {
        var args = [containerCommand, "system", "logs"]
        if let timeFilter = timeFilter {
            args.append(contentsOf: ["--last", timeFilter])
        }
        if follow {
            args.append("--follow")
        }
        
        return try await executeCommand(args)
    }
    
    func getKernelInfo() async throws -> String? {
        // This might not have a direct query command, so we'll return nil for now
        // In a real implementation, you might need to check configuration files
        return nil
    }
    
    private func parseDNSDomains(_ output: String) throws -> [DNSDomain] {
        let trimmedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedOutput.isEmpty else {
            return []
        }
        
        let lines = trimmedOutput.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        var domains: [DNSDomain] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            // Check if this line indicates a default domain (marked with *)
            let isDefault = trimmedLine.hasPrefix("*")
            let domain = isDefault ? String(trimmedLine.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines) : trimmedLine
            
            if !domain.isEmpty {
                domains.append(DNSDomain(domain: domain, isDefault: isDefault))
            }
        }
        
        return domains
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
