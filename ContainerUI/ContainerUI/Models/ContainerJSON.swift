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

// MARK: - Conversion Extensions

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