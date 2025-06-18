//
//  AppTab.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

enum AppTab: String, CaseIterable {
    case containers = "Containers"
    case images = "Images"
    case system = "System"
    
    var systemImage: String {
        switch self {
        case .containers: return "shippingbox"
        case .images: return "externaldrive"
        case .system: return "server.rack"
        }
    }
}