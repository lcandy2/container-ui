//
//  LogsContentView.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

struct LogsContentView: View {
    let logs: String
    let showLineNumbers: Bool
    let wordWrap: Bool
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            HStack(alignment: .top, spacing: 0) {
                // Line Numbers
                if showLineNumbers {
                    VStack(alignment: .trailing, spacing: 0) {
                        ForEach(Array(logs.components(separatedBy: .newlines).enumerated()), id: \.offset) { index, _ in
                            Text("\(index + 1)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.tertiary)
                                .frame(minWidth: 40, alignment: .trailing)
                                .padding(.trailing, 8)
                        }
                    }
                    .background(.quaternary.opacity(0.3))
                }
                
                // Log Content
                VStack(alignment: .leading, spacing: 0) {
                    if wordWrap {
                        Text(logs.isEmpty ? "No logs available" : logs)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(Array(logs.components(separatedBy: .newlines).enumerated()), id: \.offset) { _, line in
                            Text(line.isEmpty ? " " : line)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color(NSColor.textBackgroundColor))
    }
}