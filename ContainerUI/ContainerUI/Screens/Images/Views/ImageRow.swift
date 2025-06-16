//
//  ImageRow.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

struct ImageRow: View {
    let image: ContainerImage
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(image.displayName)
                    .font(.headline)
                
                if !image.isDockerHub {
                    Text(image.registry)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(image.shortDigest)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fontDesign(.monospaced)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(image.sizeDisplay)
                    .font(.caption)
                    .fontWeight(.medium)
                
                HStack(spacing: 4) {
                    Image(systemName: "disc")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    
                    Text(image.mediaType.contains("index") ? "Multi-arch" : "Single-arch")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}