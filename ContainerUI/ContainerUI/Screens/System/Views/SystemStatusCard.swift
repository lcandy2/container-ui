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
    @State private var isAnimated = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            HStack(alignment: .center, spacing: 16) {
                // Status Icon with animated background
                ZStack {
                    Circle()
                        .fill(statusBackgroundColor.gradient)
                        .frame(width: 52, height: 52)
                        .scaleEffect(isAnimated ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimated)
                    
                    Image(systemName: statusIconName)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .symbolEffect(.pulse, isActive: systemInfo?.serviceStatus == .running)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Container System")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 6) {
                        statusIndicator
                        
                        Text(statusText)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(statusColor)
                    }
                }
                
                Spacer()
                
                // Chevron for potential navigation
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Divider
            Divider()
                .padding(.horizontal, 20)
            
            // Details Section
            if let systemInfo = systemInfo {
                VStack(spacing: 12) {
                    // DNS Information
                    HStack {
                        Label {
                            Text("DNS Domains")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } icon: {
                            Image(systemName: "network")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        
                        Spacer()
                        
                        Text("\(systemInfo.dnsSettings.count)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }
                    
                    // Kernel Information
                    if let kernelInfo = systemInfo.kernelInfo {
                        HStack {
                            Label {
                                Text("Kernel Version")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } icon: {
                                Image(systemName: "cpu")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                            
                            Spacer()
                            
                            Text(kernelInfo)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                    
                    // Uptime or additional info could be added here
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .padding(.top, 12)
            } else {
                // Loading state
                VStack(spacing: 8) {
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.quaternary)
                            .frame(width: 120, height: 12)
                        
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.quaternary)
                            .frame(width: 40, height: 12)
                    }
                    
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.quaternary)
                            .frame(width: 100, height: 12)
                        
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.quaternary)
                            .frame(width: 60, height: 12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .padding(.top, 12)
                .redacted(reason: .placeholder)
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.quaternary.opacity(0.5), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .shadow(color: .black.opacity(0.08), radius: 1, x: 0, y: 1)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).delay(0.1)) {
                isAnimated = true
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusIconName: String {
        guard let systemInfo = systemInfo else { return "questionmark.circle.fill" }
        
        switch systemInfo.serviceStatus {
        case .running:
            return "checkmark.circle.fill"
        case .stopped:
            return "stop.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        case .starting:
            return "arrow.clockwise.circle.fill"
        }
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
    
    private var statusIndicator: some View {
        Circle()
            .fill(statusColor.gradient)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .strokeBorder(.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: statusColor.opacity(0.3), radius: 2, x: 0, y: 1)
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