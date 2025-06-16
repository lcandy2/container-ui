//
//  SystemInfo.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

struct SystemInfo {
    let serviceStatus: SystemServiceStatus
    let dnsSettings: [DNSDomain]
    let kernelInfo: String?
}