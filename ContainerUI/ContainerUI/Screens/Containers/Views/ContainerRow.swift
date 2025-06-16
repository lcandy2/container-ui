//
//  ContainerRow.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

struct ContainerRow: View {
    let container: Container
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(container.name)
                    .font(.headline)
                
                Text(container.image)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack {
                Circle()
                    .fill(container.status.color)
                    .frame(width: 8, height: 8)
                
                Text(container.status.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding(.vertical, 2)
    }
}