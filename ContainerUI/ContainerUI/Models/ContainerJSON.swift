//
//  ContainerJSON.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

// MARK: - JSON Parsing Models for container ls -a --format json

struct ContainerJSON: Codable {
    let status: String
    let networks: [ContainerNetworkJSON]
    let configuration: ContainerConfigurationJSON
}

struct ContainerNetworkJSON: Codable {
    let hostname: String?
    let address: String
    let gateway: String
    let network: String
}

struct ContainerConfigurationJSON: Codable {
    let id: String
    let hostname: String
    let image: ContainerImageRefJSON
    let platform: ContainerPlatformJSON
    let resources: ContainerResourcesJSON
    let rosetta: Bool
}

struct ContainerImageRefJSON: Codable {
    let reference: String
    let descriptor: ContainerImageDescriptorJSON
}

struct ContainerImageDescriptorJSON: Codable {
    let digest: String
    let size: Int64
    let mediaType: String
}

struct ContainerPlatformJSON: Codable {
    let architecture: String
    let os: String
}

struct ContainerResourcesJSON: Codable {
    let cpus: Int
    let memoryInBytes: Int64
}

// MARK: - Image List JSON Models (for container image ls --format json)

struct ImageListItemJSON: Codable {
    let descriptor: ImageDescriptorJSON
    let reference: String
}

struct ImageDescriptorJSON: Codable {
    let mediaType: String
    let size: Int64
    let digest: String
}

// MARK: - Conversion Extensions

extension ImageListItemJSON {
    func toContainerImage() -> ContainerImage {
        // Parse the reference to extract registry, repository, and tag
        let components = reference.components(separatedBy: "/")
        
        let registry: String
        let repositoryAndTag: String
        
        if components.count > 2 && components[0].contains(".") {
            // Has registry (e.g., "docker.io/library/alpine:latest")
            registry = components[0]
            repositoryAndTag = components.dropFirst().joined(separator: "/")
        } else {
            // No explicit registry (e.g., "alpine:latest")
            registry = "docker.io" // Default registry
            repositoryAndTag = reference
        }
        
        // Split repository and tag
        let tagComponents = repositoryAndTag.components(separatedBy: ":")
        let repository = tagComponents.first ?? repositoryAndTag
        let tag = tagComponents.count > 1 ? tagComponents.last! : "latest"
        
        // Clean up repository name (remove "library/" prefix for Docker Hub)
        let cleanRepository = repository.replacingOccurrences(of: "library/", with: "")
        
        return ContainerImage(
            name: cleanRepository,
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

extension ContainerJSON {
    func toContainer() -> Container {
        let containerStatus: ContainerStatus
        switch status.lowercased() {
        case "running":
            containerStatus = .running
        case "stopped":
            containerStatus = .stopped
        case "exited":
            containerStatus = .exited
        default:
            containerStatus = .stopped
        }
        
        let networks = self.networks.map { networkJSON in
            ContainerNetwork(
                hostname: networkJSON.hostname,
                address: networkJSON.address,
                gateway: networkJSON.gateway,
                network: networkJSON.network
            )
        }
        
        // Extract image name from reference (remove registry prefix)
        let imageName = configuration.image.reference.components(separatedBy: "/").last ?? configuration.image.reference
        
        return Container(
            containerID: configuration.id,
            name: configuration.hostname,
            image: imageName,
            imageReference: configuration.image.reference,
            imageDigest: configuration.image.descriptor.digest,
            hostname: configuration.hostname,
            status: containerStatus,
            os: configuration.platform.os,
            arch: configuration.platform.architecture,
            cpus: configuration.resources.cpus,
            memoryInBytes: configuration.resources.memoryInBytes,
            networks: networks,
            rosetta: configuration.rosetta
        )
    }
}