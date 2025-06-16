//
//  LogSource.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

struct LogSource: Identifiable, Hashable {
    let id: String
    let title: String
    let type: LogType
    let supportsRealTime: Bool
    let availableFilters: [LogFilter]
    
    static func == (lhs: LogSource, rhs: LogSource) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}