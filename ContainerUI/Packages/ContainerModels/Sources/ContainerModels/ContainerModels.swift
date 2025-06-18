//
//  ContainerModels.swift
//  ContainerModels Package
//
//  Created by ContainerUI on 6/17/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation
import SwiftUI

// MARK: - Core Models

public struct Container: Identifiable, Hashable {
    public let id = UUID()
    public let containerID: String
    public let name: String
    public let image: String
    public let imageReference: String
    public let imageDigest: String
    public let hostname: String
    public let status: ContainerStatus
    public let os: String
    public let arch: String
    public let cpus: Int
    public let memoryInBytes: Int64
    public let networks: [ContainerNetwork]
    public let rosetta: Bool
    
    public init(containerID: String, name: String, image: String, imageReference: String, imageDigest: String, hostname: String, status: ContainerStatus, os: String, arch: String, cpus: Int, memoryInBytes: Int64, networks: [ContainerNetwork], rosetta: Bool) {
        self.containerID = containerID
        self.name = name
        self.image = image
        self.imageReference = imageReference
        self.imageDigest = imageDigest
        self.hostname = hostname
        self.status = status
        self.os = os
        self.arch = arch
        self.cpus = cpus
        self.memoryInBytes = memoryInBytes
        self.networks = networks
        self.rosetta = rosetta
    }
    
    // Computed properties for display
    public var displayName: String {
        // Use hostname if different from containerID, otherwise use first 12 chars of ID
        hostname != containerID ? hostname : String(containerID.prefix(12))
    }
    
    public var primaryAddress: String? {
        networks.first?.address
    }
    
    public var memoryDisplay: String {
        let gb = Double(memoryInBytes) / 1_073_741_824 // Convert bytes to GB
        return String(format: "%.1f GB", gb)
    }
}

public struct ContainerNetwork: Identifiable, Hashable {
    public let id = UUID()
    public let hostname: String?
    public let address: String
    public let gateway: String
    public let network: String
    
    public init(hostname: String?, address: String, gateway: String, network: String) {
        self.hostname = hostname
        self.address = address
        self.gateway = gateway
        self.network = network
    }
}

public enum ContainerStatus: String, CaseIterable {
    case running = "running"
    case stopped = "stopped"
    case exited = "exited"
    case starting = "starting"
    case stopping = "stopping"
    
    public var displayName: String {
        switch self {
        case .running:
            return "Running"
        case .stopped:
            return "Stopped"
        case .exited:
            return "Exited"
        case .starting:
            return "Starting"
        case .stopping:
            return "Stopping"
        }
    }
    
    public var color: Color {
        switch self {
        case .running:
            return .green
        case .stopped, .exited:
            return .gray
        case .starting:
            return .orange
        case .stopping:
            return .orange
        }
    }
}

public struct ContainerImage: Identifiable, Hashable {
    public let id = UUID()
    public let name: String
    public let tag: String
    public let digest: String
    public let reference: String
    public let registry: String
    public let repository: String
    public let mediaType: String
    public let size: Int64
    
    public init(name: String, tag: String, digest: String, reference: String, registry: String, repository: String, mediaType: String, size: Int64) {
        self.name = name
        self.tag = tag
        self.digest = digest
        self.reference = reference
        self.registry = registry
        self.repository = repository
        self.mediaType = mediaType
        self.size = size
    }
    
    public var displayName: String {
        return "\(name):\(tag)"
    }
    
    public var fullReference: String {
        return reference
    }
    
    public var sizeDisplay: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    public var shortDigest: String {
        String(digest.dropFirst(7).prefix(12)) // Remove "sha256:" and show first 12 chars
    }
    
    public var isDockerHub: Bool {
        registry == "docker.io"
    }
}

public struct DNSDomain: Identifiable, Hashable {
    public let id = UUID()
    public let domain: String
    public let isDefault: Bool
    
    public init(domain: String, isDefault: Bool) {
        self.domain = domain
        self.isDefault = isDefault
    }
}

public enum SystemServiceStatus {
    case running
    case stopped
    case starting
    case error
    
    public var displayName: String {
        switch self {
        case .running:
            return "Running"
        case .stopped:
            return "Stopped"
        case .starting:
            return "Starting"
        case .error:
            return "Error"
        }
    }
    
    public var color: Color {
        switch self {
        case .running:
            return .green
        case .stopped:
            return .gray
        case .starting:
            return .blue
        case .error:
            return .red
        }
    }
    
    public var icon: String {
        switch self {
        case .running:
            return "checkmark.circle.fill"
        case .stopped:
            return "stop.circle.fill"
        case .starting:
            return "arrow.clockwise.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
}

public struct SystemInfo {
    public let serviceStatus: SystemServiceStatus
    public let dnsSettings: [DNSDomain]
    public let kernelInfo: String?
    
    public init(serviceStatus: SystemServiceStatus, dnsSettings: [DNSDomain], kernelInfo: String?) {
        self.serviceStatus = serviceStatus
        self.dnsSettings = dnsSettings
        self.kernelInfo = kernelInfo
    }
}

// MARK: - JSON Parsing Models for Apple Container CLI

public struct ContainerJSONData: Codable {
    public let status: String
    public let networks: [NetworkJSONData]?
    public let configuration: ConfigurationData
    
    public struct ConfigurationData: Codable {
        public let id: String
        public let hostname: String
        public let platform: PlatformData
        public let image: ImageRefData
        public let resources: ResourcesData
        public let rosetta: Bool
        
        public struct PlatformData: Codable {
            public let architecture: String
            public let os: String
        }
        
        public struct ImageRefData: Codable {
            public let reference: String
        }
        
        public struct ResourcesData: Codable {
            public let cpus: Int
            public let memoryInBytes: Int64
        }
    }
    
    public func toContainer() -> Container {
        // Extract name from image reference or use hostname
        let imageRef = configuration.image.reference
        let imageParts = imageRef.split(separator: "/").last?.split(separator: ":") ?? []
        let imageName = imageParts.first.map(String.init) ?? imageRef
        let name = configuration.hostname
        
        // Parse status
        let containerStatus: ContainerStatus
        switch status.lowercased() {
        case "running":
            containerStatus = .running
        case "stopped":
            containerStatus = .stopped
        default:
            containerStatus = .exited
        }
        
        return Container(
            containerID: configuration.id,
            name: name,
            image: imageName,
            imageReference: imageRef,
            imageDigest: "", // Not provided in this format
            hostname: configuration.hostname,
            status: containerStatus,
            os: configuration.platform.os,
            arch: configuration.platform.architecture,
            cpus: configuration.resources.cpus,
            memoryInBytes: configuration.resources.memoryInBytes,
            networks: networks?.map { $0.toContainerNetwork() } ?? [],
            rosetta: configuration.rosetta
        )
    }
}

public struct NetworkJSONData: Codable {
    public let hostname: String?
    public let address: String
    public let gateway: String
    public let network: String
    
    public func toContainerNetwork() -> ContainerNetwork {
        return ContainerNetwork(
            hostname: hostname,
            address: address,
            gateway: gateway,
            network: network
        )
    }
}

public struct ImageJSONData: Codable {
    public let reference: String
    public let descriptor: DescriptorData
    
    public struct DescriptorData: Codable {
        public let mediaType: String
        public let digest: String
        public let size: Int64
    }
    
    public func toContainerImage() -> ContainerImage {
        // Parse name and tag from reference like "docker.io/library/alpine:latest"
        let parts = reference.split(separator: "/")
        let nameWithTag = parts.last?.description ?? reference
        let nameTagParts = nameWithTag.split(separator: ":")
        
        let name = nameTagParts.first.map(String.init) ?? reference
        let tag = nameTagParts.count > 1 ? String(nameTagParts[1]) : "latest"
        
        // Parse registry and repository from reference
        let registry: String
        let repository: String
        
        if reference.contains("/") {
            let refParts = reference.split(separator: "/", maxSplits: 1)
            if refParts.count == 2 {
                registry = String(refParts[0])
                repository = String(refParts[1]).split(separator: ":").first.map(String.init) ?? name
            } else {
                registry = "docker.io"
                repository = name
            }
        } else {
            registry = "docker.io"
            repository = name
        }
        
        return ContainerImage(
            name: name,
            tag: tag,
            digest: descriptor.digest,
            reference: reference,
            registry: registry,
            repository: repository,
            mediaType: descriptor.mediaType,
            size: descriptor.size
        )
    }
}

public struct DNSDomainData {
    public let domain: String
    public let isDefault: Bool
    
    public init(domain: String, isDefault: Bool) {
        self.domain = domain
        self.isDefault = isDefault
    }
    
    public func toDNSDomain() -> DNSDomain {
        return DNSDomain(domain: domain, isDefault: isDefault)
    }
}


// MARK: - Error Types

public enum ContainerError: LocalizedError {
    case commandFailed(String)
    case containerNotFound
    case invalidOutput
    
    public var errorDescription: String? {
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
