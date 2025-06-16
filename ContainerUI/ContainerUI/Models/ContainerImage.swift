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
    
    var displayName: String {
        return "\(name):\(tag)"
    }
}