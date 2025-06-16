//
//  LogsStatusBar.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

struct LogsStatusBar: View {
    let logSource: LogSource
    let lineCount: Int
    let isStreaming: Bool
    let lastUpdated: Date
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: logSource.type.systemImage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(logSource.type.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Text("\(lineCount) lines")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if isStreaming {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                        Text("Live")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Updated \(lastUpdated, style: .relative) ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(.regularMaterial)
    }
}