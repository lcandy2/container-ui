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
        HStack(spacing: 16) {
            // Status Icon
            Circle()
                .fill(statusBackgroundColor)
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: statusIconName)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                }
            
            // System Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Container System")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                    
                    Text(statusText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Kernel Info (if available)
            if let systemInfo = systemInfo, let kernelInfo = systemInfo.kernelInfo {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Kernel")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)
                    
                    Text(kernelInfo.components(separatedBy: " ").first ?? kernelInfo)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.separator.opacity(0.3), lineWidth: 0.5)
        )
    }
    
    // MARK: - Computed Properties
    
    private var statusIconName: String {
        return "server.rack"
    }
    
    private var statusBackgroundColor: Color {
        guard let systemInfo = systemInfo else { return .gray }
        
        switch systemInfo.serviceStatus {
        case .running:
            return .green
        case .stopped:
            return .gray
        case .error:
            return .red
        case .starting:
            return .blue
        }
    }
    
    private var statusText: String {
        guard let systemInfo = systemInfo else { return "Unknown" }
        return systemInfo.serviceStatus.displayName
    }
    
    private var statusColor: Color {
        guard let systemInfo = systemInfo else { return .secondary }
        return systemInfo.serviceStatus.color
    }
}