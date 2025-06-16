//
//  ContainerImage.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

struct ContainerImage: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let tag: String
    let digest: String
    let reference: String
    let registry: String
    let repository: String
    let mediaType: String
    let size: Int64
    
    var displayName: String {
        return "\(name):\(tag)"
    }
    
    var fullReference: String {
        return reference
    }
    
    var sizeDisplay: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    var shortDigest: String {
        String(digest.dropFirst(7).prefix(12)) // Remove "sha256:" and show first 12 chars
    }
    
    var isDockerHub: Bool {
        registry == "docker.io"
    }
}