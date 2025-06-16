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
                
                Text(image.digest.prefix(12))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fontDesign(.monospaced)
            }
            
            Spacer()
            
            Image(systemName: "disc")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}