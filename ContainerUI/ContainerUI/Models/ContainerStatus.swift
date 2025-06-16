//
//  ContainerStatus.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

enum ContainerStatus: Hashable {
    case running
    case stopped
    case exited
    
    var displayName: String {
        switch self {
        case .running: return "Running"
        case .stopped: return "Stopped"
        case .exited: return "Exited"
        }
    }
    
    var color: Color {
        switch self {
        case .running: return .green
        case .stopped: return .orange
        case .exited: return .red
        }
    }
}