//
//  LogFilter.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

enum LogFilter: String, CaseIterable {
    case timeRange = "Time Range"
    case textSearch = "Text Search"
    case logLevel = "Log Level"
    
    var systemImage: String {
        switch self {
        case .timeRange: return "clock"
        case .textSearch: return "magnifyingglass"
        case .logLevel: return "slider.horizontal.3"
        }
    }
}