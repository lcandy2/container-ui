//
//  Container.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

struct Container: Identifiable, Hashable {
    let id = UUID()
    let containerID: String
    let name: String
    let image: String
    let imageReference: String
    let imageDigest: String
    let hostname: String
    let status: ContainerStatus
    let os: String
    let arch: String
    let cpus: Int
    let memoryInBytes: Int64
    let networks: [ContainerNetwork]
    let rosetta: Bool
    
    // Computed properties for display
    var displayName: String {
        // Use hostname if different from containerID, otherwise use first 12 chars of ID
        hostname != containerID ? hostname : String(containerID.prefix(12))
    }
    
    var primaryAddress: String? {
        networks.first?.address
    }
    
    var memoryDisplay: String {
        let gb = Double(memoryInBytes) / 1_073_741_824 // Convert bytes to GB
        return String(format: "%.1f GB", gb)
    }
}

struct ContainerNetwork: Identifiable, Hashable {
    let id = UUID()
    let hostname: String?
    let address: String
    let gateway: String
    let network: String
}