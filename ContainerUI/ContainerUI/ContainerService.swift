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
            
            let output = try await executeCommand([containerCommand, "list"])
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
            _ = try await executeCommand([containerCommand, "list"])
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
        
        let lines = trimmedOutput.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        // Always skip header line - first line is always the header
        let dataLines = lines.count > 1 ? Array(lines.dropFirst()) : []
        
        var containers: [Container] = []
        
        for line in dataLines {
            // Split by multiple spaces to handle the column format properly
            let components = line.split(separator: " ", omittingEmptySubsequences: true)
                .map { String($0) }
            
            // Expected format: ID  IMAGE  OS  ARCH  STATE  ADDR
            if components.count >= 5 {
                let containerID = components[0]
                let image = components[1]
                let os = components[2]
                let arch = components[3]
                let stateString = components[4]
                let addr = components.count >= 6 ? components[5] : nil
                
                let status: ContainerStatus
                switch stateString.lowercased() {
                case "running":
                    status = .running
                case "stopped", "stop":
                    status = .stopped
                case "exited", "exit":
                    status = .exited
                default:
                    status = .stopped
                }
                
                // Clean up image name (remove registry prefix for display)
                let displayImage = image.components(separatedBy: "/").last ?? image
                
                let container = Container(
                    containerID: containerID,
                    name: containerID.prefix(12).description, // Use first 12 chars as display name
                    image: displayImage,
                    os: os,
                    arch: arch,
                    status: status,
                    addr: addr
                )
                containers.append(container)
            }
        }
        
        return containers
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
