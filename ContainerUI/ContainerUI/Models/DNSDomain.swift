//
//  DNSDomain.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

struct DNSDomain: Identifiable, Hashable {
    let id = UUID()
    let domain: String
    let isDefault: Bool
}