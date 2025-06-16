//
//  ContainerImageJSON.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

// MARK: - JSON Parsing Models for container image ls --format json

struct ContainerImageJSON: Codable {
    let descriptor: ImageDescriptorJSON
    let reference: String
}

struct ImageDescriptorJSON: Codable {
    let mediaType: String
    let size: Int64
    let digest: String
}

// MARK: - Conversion Extensions

extension ContainerImageJSON {
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