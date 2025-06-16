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
            let output = try await executeCommand([containerCommand, "list"])
            containers = try parseContainerList(output)
        } catch {
            errorMessage = "Failed to load containers: \(error.localizedDescription)\n\nNote: This app requires sandboxing to be disabled to execute the container CLI. Please disable App Sandbox in the project settings or run from Xcode."
            print("Container list error: \(error)")
        }
        
        isLoading = false
    }
    
    func startContainer(_ containerName: String) async throws {
        _ = try await executeCommand([containerCommand, "start", containerName])
    }
    
    func stopContainer(_ containerName: String) async throws {
        _ = try await executeCommand([containerCommand, "stop", containerName])
    }
    
    func deleteContainer(_ containerName: String) async throws {
        _ = try await executeCommand([containerCommand, "rm", containerName])
    }
    
    func openTerminal(for containerName: String) async throws {
        let process = Process()
        process.launchPath = "/usr/bin/open"
        process.arguments = ["-a", "Terminal", "--args", containerCommand, "exec", "-ti", containerName, "sh"]
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
        guard !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        let lines = output.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        var containers: [Container] = []
        
        for line in lines {
            let components = line.components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
            
            if components.count >= 3 {
                let name = components[0]
                let image = components[1]
                let statusString = components[2]
                
                let status: ContainerStatus
                switch statusString.lowercased() {
                case "running":
                    status = .running
                case "stopped":
                    status = .stopped
                default:
                    status = .exited
                }
                
                let container = Container(
                    name: name,
                    image: image,
                    status: status,
                    created: Date().addingTimeInterval(-Double.random(in: 0...86400))
                )
                containers.append(container)
            }
        }
        
        return containers
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
