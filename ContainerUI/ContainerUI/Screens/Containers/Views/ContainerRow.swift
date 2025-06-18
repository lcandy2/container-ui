//
//  ContainerRow.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI
import ContainerModels

struct ContainerRow: View {
    let container: Container
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(container.displayName)
                    .font(.headline)
                
                Text(container.image)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let address = container.primaryAddress {
                    Text(address)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .fontDesign(.monospaced)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                // Show progress or stable status
                if container.status.isInProgress {
                    HStack(spacing: 4) {
                        ProgressView()
                            .controlSize(.mini)
                            .scaleEffect(0.8)
                        
                        Text(container.status.progressMessage)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(container.status.color)
                    }
                } else {
                    HStack {
                        Circle()
                            .fill(container.status.color)
                            .frame(width: 8, height: 8)
                        
                        Text(container.status.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                
                Text("\(container.cpus) CPU • \(container.memoryDisplay)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}