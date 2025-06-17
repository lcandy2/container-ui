//
//  SystemStatusCard.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI
import ContainerModels

struct SystemStatusCard: View {
    let systemInfo: SystemInfo?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text("Container System")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let systemInfo = systemInfo {
                        HStack {
                            Circle()
                                .fill(systemInfo.serviceStatus.color)
                                .frame(width: 8, height: 8)
                            Text(systemInfo.serviceStatus.displayName)
                                .font(.subheadline)
                        }
                    } else {
                        Text("Loading...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            
            if let systemInfo = systemInfo {
                VStack(alignment: .leading, spacing: 8) {
                    Text("DNS Domains: \(systemInfo.dnsSettings.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let kernelInfo = systemInfo.kernelInfo {
                        Text("Kernel: \(kernelInfo)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}