//
//  SystemServiceStatus.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

enum SystemServiceStatus: Hashable {
    case running
    case stopped
    case unknown
    
    var displayName: String {
        switch self {
        case .running: return "Running"
        case .stopped: return "Stopped"
        case .unknown: return "Unknown"
        }
    }
    
    var color: Color {
        switch self {
        case .running: return .green
        case .stopped: return .red
        case .unknown: return .orange
        }
    }
}