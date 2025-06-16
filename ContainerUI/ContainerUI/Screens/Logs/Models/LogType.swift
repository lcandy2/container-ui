//
//  LogType.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

enum LogType: Hashable {
    case container(containerID: String)
    case containerBoot(containerID: String)
    case system
    case builder
    case registry
    
    var displayName: String {
        switch self {
        case .container: return "Container Logs"
        case .containerBoot: return "Boot Logs"
        case .system: return "System Logs"
        case .builder: return "Builder Logs"
        case .registry: return "Registry Logs"
        }
    }
    
    var systemImage: String {
        switch self {
        case .container: return "doc.text"
        case .containerBoot: return "power"
        case .system: return "gearshape"
        case .builder: return "hammer"
        case .registry: return "server.rack"
        }
    }
}