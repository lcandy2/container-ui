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
    let containerID: String  // The actual container ID from the command
    let name: String
    let image: String
    let os: String
    let arch: String
    let status: ContainerStatus
    let addr: String?  // Optional since it might be empty for stopped containers
}