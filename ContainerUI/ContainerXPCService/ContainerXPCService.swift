//
//  ContainerXPCService.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/17/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation
import os.log
import ContainerModels

// Create logger for XPC Service implementation
private let serviceLogger = Logger(subsystem: "cc.citrons.ContainerUI.ContainerXPCService", category: "Implementation")

/// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
class ContainerXPCService: NSObject, ContainerXPCServiceProtocol {
    
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
    
    // MARK: - Container Management
    
    func listContainers(reply: @escaping ([String: Any]) -> Void) {
        serviceLogger.info("📋 XPC Service: listContainers called")
        Task {
            do {
                let output = try await executeCommand([containerCommand, "ls", "-a", "--format", "json"])
                let containers = try parseContainerList(output)
                
                let containersDict = containers.map { container in
                    containerToDict(container)
                }
                
                serviceLogger.info("✅ XPC Service: listContainers returning \(containers.count) containers")
                reply(["containers": containersDict])
            } catch {
                serviceLogger.error("❌ XPC Service: listContainers failed: \(error.localizedDescription)")
                reply(["error": error.localizedDescription])
            }
        }
    }
    
    func listImages(reply: @escaping ([String: Any]) -> Void) {
        Task {
            do {
                let output = try await executeCommand([containerCommand, "image", "ls", "--format", "json"])
                let images = try parseImageList(output)
                
                let imagesDict = images.map { image in
                    imageToDict(image)
                }
                
                reply(["images": imagesDict])
            } catch {
                reply(["error": error.localizedDescription])
            }
        }
    }
    
    func startContainer(_ containerID: String, reply: @escaping (Error?) -> Void) {
        Task {
            do {
                _ = try await executeCommand([containerCommand, "start", containerID])
                reply(nil)
            } catch {
                reply(error)
            }
        }
    }
    
    func stopContainer(_ containerID: String, reply: @escaping (Error?) -> Void) {
        Task {
            do {
                _ = try await executeCommand([containerCommand, "stop", containerID])
                reply(nil)
            } catch {
                reply(error)
            }
        }
    }
    
    func deleteContainer(_ containerID: String, reply: @escaping (Error?) -> Void) {
        Task {
            do {
                _ = try await executeCommand([containerCommand, "delete", containerID])
                reply(nil)
            } catch {
                reply(error)
            }
        }
    }
    
    func deleteImage(_ imageName: String, reply: @escaping (Error?) -> Void) {
        Task {
            do {
                _ = try await executeCommand([containerCommand, "images", "delete", imageName])
                reply(nil)
            } catch {
                reply(error)
            }
        }
    }
    
    func createAndRunContainer(image: String, name: String?, reply: @escaping (Error?) -> Void) {
        Task {
            do {
                var args = [containerCommand, "run", "-d"]
                if let name = name {
                    args.append(contentsOf: ["--name", name])
                }
                args.append(image)
                
                _ = try await executeCommand(args)
                reply(nil)
            } catch {
                reply(error)
            }
        }
    }
    
    // MARK: - Log Operations
    
    func getContainerLogs(_ containerID: String, lines: NSNumber?, follow: Bool, reply: @escaping ([String: Any]) -> Void) {
        Task {
            do {
                var args = [containerCommand, "logs"]
                if let lines = lines {
                    args.append(contentsOf: ["-n", "\(lines.intValue)"])
                }
                if follow {
                    args.append("-f")
                }
                args.append(containerID)
                
                let logs = try await executeCommand(args)
                reply(["logs": logs])
            } catch {
                reply(["error": error.localizedDescription])
            }
        }
    }
    
    func getContainerBootLogs(_ containerID: String, reply: @escaping ([String: Any]) -> Void) {
        Task {
            do {
                let args = [containerCommand, "logs", "--boot", containerID]
                let logs = try await executeCommand(args)
                reply(["logs": logs])
            } catch {
                reply(["error": error.localizedDescription])
            }
        }
    }
    
    // MARK: - System Management
    
    func getSystemStatus(reply: @escaping ([String: Any]) -> Void) {
        Task {
            do {
                // Try to run a simple command to check if system is responsive
                _ = try await executeCommand([containerCommand, "system", "logs", "--last", "1m"])
                reply(["status": "running"])
            } catch {
                reply(["status": "stopped"])
            }
        }
    }
    
    func startSystem(reply: @escaping (Error?) -> Void) {
        Task {
            do {
                _ = try await executeCommand([containerCommand, "system", "start"])
                reply(nil)
            } catch {
                reply(error)
            }
        }
    }
    
    func stopSystem(reply: @escaping (Error?) -> Void) {
        Task {
            do {
                _ = try await executeCommand([containerCommand, "system", "stop"])
                reply(nil)
            } catch {
                reply(error)
            }
        }
    }
    
    func restartSystem(reply: @escaping (Error?) -> Void) {
        Task {
            do {
                _ = try await executeCommand([containerCommand, "system", "restart"])
                reply(nil)
            } catch {
                reply(error)
            }
        }
    }
    
    func getSystemLogs(timeFilter: String?, follow: Bool, reply: @escaping ([String: Any]) -> Void) {
        Task {
            do {
                var args = [containerCommand, "system", "logs"]
                if let timeFilter = timeFilter {
                    args.append(contentsOf: ["--last", timeFilter])
                }
                if follow {
                    args.append("--follow")
                }
                
                let logs = try await executeCommand(args)
                reply(["logs": logs])
            } catch {
                reply(["error": error.localizedDescription])
            }
        }
    }
    
    // MARK: - DNS Management
    
    func listDNSDomains(reply: @escaping ([String: Any]) -> Void) {
        Task {
            do {
                let output = try await executeCommand([containerCommand, "system", "dns", "list"])
                let domains = try parseDNSDomains(output)
                
                let domainsDict = domains.map { domain in
                    ["domain": domain.domain, "isDefault": domain.isDefault]
                }
                
                reply(["domains": domainsDict])
            } catch {
                reply(["error": error.localizedDescription])
            }
        }
    }
    
    func createDNSDomain(_ domain: String, reply: @escaping (Error?) -> Void) {
        Task {
            do {
                _ = try await executeCommand([containerCommand, "system", "dns", "create", domain])
                reply(nil)
            } catch {
                reply(error)
            }
        }
    }
    
    func deleteDNSDomain(_ domain: String, reply: @escaping (Error?) -> Void) {
        Task {
            do {
                _ = try await executeCommand([containerCommand, "system", "dns", "delete", domain])
                reply(nil)
            } catch {
                reply(error)
            }
        }
    }
    
    func setDefaultDNSDomain(_ domain: String, reply: @escaping (Error?) -> Void) {
        Task {
            do {
                _ = try await executeCommand([containerCommand, "system", "dns", "default", domain])
                reply(nil)
            } catch {
                reply(error)
            }
        }
    }
    
    // MARK: - Terminal Operations
    
    func openTerminal(for containerID: String, reply: @escaping (Error?) -> Void) {
        Task {
            do {
                let process = Process()
                process.launchPath = "/usr/bin/open"
                process.arguments = ["-a", "Terminal", "--args", containerCommand, "exec", "-ti", containerID, "sh"]
                process.launch()
                reply(nil)
            } catch {
                reply(error)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    
    private func executeCommand(_ arguments: [String]) async throws -> String {
        serviceLogger.info("🚀 XPC Service: Executing command: \(arguments.joined(separator: " "))")
        
        // Check if we can access the container binary
        let containerPath = containerCommand
        serviceLogger.info("🔍 XPC Service: Using container path: \(containerPath)")
        
        // XPC service runs outside sandbox, so should have access
        guard FileManager.default.isExecutableFile(atPath: containerPath) || containerPath == "container" else {
            serviceLogger.error("❌ XPC Service: Container CLI tool not found at \(containerPath)")
            throw ContainerXPCError.commandFailed("Container CLI tool not found at \(containerPath). Please ensure Apple's container tool is installed and accessible.")
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
                
                serviceLogger.info("🏁 XPC Service: Command completed with exit code: \(process.terminationStatus)")
                
                if process.terminationStatus == 0 {
                    let output = String(data: data, encoding: .utf8) ?? ""
                    serviceLogger.info("✅ XPC Service: Command output length: \(output.count) characters")
                    serviceLogger.debug("📄 XPC Service: Raw output: \(output)")
                    continuation.resume(returning: output)
                } else {
                    let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                    serviceLogger.error("❌ XPC Service: Command failed with error: \(errorMessage)")
                    let fullError = "Command failed: \(errorMessage)"
                    continuation.resume(throwing: ContainerXPCError.commandFailed(fullError))
                }
            }
            
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - JSON Parsing Methods
    
    private func parseContainerList(_ output: String) throws -> [ContainerData] {
        serviceLogger.info("🔍 XPC Service: Parsing container list output")
        let trimmedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)
        serviceLogger.debug("📝 XPC Service: Trimmed output: '\(trimmedOutput)'")
        
        guard !trimmedOutput.isEmpty else {
            serviceLogger.info("ℹ️ XPC Service: Empty output, returning empty container list")
            return []
        }
        
        // Parse JSON output from container ls -a --format json
        guard let data = trimmedOutput.data(using: .utf8) else {
            serviceLogger.error("❌ XPC Service: Failed to convert output to UTF-8 data")
            throw ContainerXPCError.invalidOutput
        }
        
        do {
            let containerJSONList = try JSONDecoder().decode([ContainerJSONData].self, from: data)
            serviceLogger.info("✅ XPC Service: Successfully parsed \(containerJSONList.count) containers")
            return containerJSONList.map { containerJSON in
                let container = containerJSON.toContainer()
                return ContainerData(
                    containerID: container.containerID,
                    name: container.name,
                    image: container.image,
                    imageReference: container.imageReference,
                    imageDigest: container.imageDigest,
                    hostname: container.hostname,
                    status: container.status.rawValue,
                    os: container.os,
                    arch: container.arch,
                    cpus: container.cpus,
                    memoryInBytes: container.memoryInBytes,
                    networks: container.networks.map { network in
                        NetworkData(hostname: network.hostname, address: network.address, gateway: network.gateway, network: network.network)
                    },
                    rosetta: container.rosetta
                )
            }
        } catch {
            serviceLogger.error("❌ XPC Service: JSON parsing error: \(error)")
            serviceLogger.error("🔍 XPC Service: Failed to parse JSON: '\(trimmedOutput)'")
            throw ContainerXPCError.invalidOutput
        }
    }
    
    private func parseImageList(_ output: String) throws -> [ImageData] {
        serviceLogger.info("🔍 XPC Service: Parsing image list output")
        let trimmedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)
        serviceLogger.debug("📝 XPC Service: Trimmed image output: '\(trimmedOutput)'")
        
        guard !trimmedOutput.isEmpty else {
            serviceLogger.info("ℹ️ XPC Service: Empty output, returning empty image list")
            return []
        }
        
        // Parse JSON output from container image ls --format json
        guard let data = trimmedOutput.data(using: .utf8) else {
            serviceLogger.error("❌ XPC Service: Failed to convert image output to UTF-8 data")
            throw ContainerXPCError.invalidOutput
        }
        
        do {
            let imageJSONList = try JSONDecoder().decode([ImageJSONData].self, from: data)
            serviceLogger.info("✅ XPC Service: Successfully parsed \(imageJSONList.count) images")
            return imageJSONList.map { imageJSON in
                let image = imageJSON.toContainerImage()
                return ImageData(
                    name: image.name,
                    tag: image.tag,
                    reference: image.reference,
                    digest: image.digest,
                    size: image.size,
                    created: nil
                )
            }
        } catch {
            serviceLogger.error("❌ XPC Service: Image JSON parsing error: \(error)")
            serviceLogger.error("🔍 XPC Service: Failed to parse image JSON: '\(trimmedOutput)'")
            throw ContainerXPCError.invalidOutput
        }
    }
    
    private func parseDNSDomains(_ output: String) throws -> [DNSDomainData] {
        let trimmedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedOutput.isEmpty else {
            return []
        }
        
        let lines = trimmedOutput.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        var domains: [DNSDomainData] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            // Check if this line indicates a default domain (marked with *)
            let isDefault = trimmedLine.hasPrefix("*")
            let domain = isDefault ? String(trimmedLine.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines) : trimmedLine
            
            if !domain.isEmpty {
                domains.append(DNSDomainData(domain: domain, isDefault: isDefault))
            }
        }
        
        return domains
    }
    
    // MARK: - Data Conversion Methods
    
    private func containerToDict(_ container: ContainerData) -> [String: Any] {
        var dict: [String: Any] = [
            "containerID": container.containerID,
            "name": container.name,
            "image": container.image,
            "imageReference": container.imageReference,
            "imageDigest": container.imageDigest,
            "hostname": container.hostname,
            "status": container.status,
            "os": container.os,
            "arch": container.arch,
            "cpus": container.cpus,
            "memoryInBytes": container.memoryInBytes,
            "rosetta": container.rosetta
        ]
        
        if !container.networks.isEmpty {
            dict["networks"] = container.networks.map { network in
                [
                    "hostname": network.hostname ?? "",
                    "address": network.address,
                    "gateway": network.gateway,
                    "network": network.network
                ]
            }
        }
        
        return dict
    }
    
    private func imageToDict(_ image: ImageData) -> [String: Any] {
        var dict: [String: Any] = [
            "name": image.name,
            "tag": image.tag,
            "reference": image.reference,
            "digest": image.digest,
            "size": image.size
        ]
        
        if let created = image.created {
            dict["created"] = created
        }
        
        return dict
    }
}

// MARK: - Data Models for XPC Service

struct ContainerData {
    let containerID: String
    let name: String
    let image: String
    let imageReference: String
    let imageDigest: String
    let hostname: String
    let status: String
    let os: String
    let arch: String
    let cpus: Int
    let memoryInBytes: Int64
    let networks: [NetworkData]
    let rosetta: Bool
}

struct NetworkData {
    let hostname: String?
    let address: String
    let gateway: String
    let network: String
}

struct ImageData {
    let name: String
    let tag: String
    let reference: String
    let digest: String
    let size: Int64
    let created: String?
}

struct DNSDomainData {
    let domain: String
    let isDefault: Bool
}

// MARK: - Local Data Models for XPC Transfer

// MARK: - Error Types

enum ContainerXPCError: LocalizedError {
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
