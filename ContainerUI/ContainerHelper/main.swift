//
//  main.swift
//  ContainerHelper
//
//  Created by 甜檸Citron(lcandy2) on 6/17/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

class ContainerHelper {
    private var containerCommand: String {
        let possiblePaths = [
            "/usr/local/bin/container",
            "/opt/homebrew/bin/container",
            "/usr/bin/container"
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        return "container" // Fallback to PATH lookup
    }
    
    func executeCommand(_ arguments: [String]) throws -> String {
        let containerPath = containerCommand
        
        // For privileged operations, we have more access
        guard FileManager.default.isExecutableFile(atPath: containerPath) || containerPath == "container" else {
            throw HelperError.commandFailed("Container CLI tool not found at \(containerPath). Please ensure Apple's container tool is installed and accessible.")
        }
        
        let process = Process()
        let pipe = Pipe()
        let errorPipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = errorPipe
        
        // Try direct execution first
        if containerPath != "container" && FileManager.default.isExecutableFile(atPath: containerPath) {
            process.executableURL = URL(fileURLWithPath: containerPath)
            process.arguments = Array(arguments.dropFirst())
        } else {
            // Fallback to shell execution for PATH lookup
            process.executableURL = URL(fileURLWithPath: "/bin/sh")
            let commandString = arguments.joined(separator: " ")
            process.arguments = ["-c", "PATH=/usr/local/bin:/opt/homebrew/bin:$PATH; \(commandString)"]
        }
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        if process.terminationStatus == 0 {
            return String(data: data, encoding: .utf8) ?? ""
        } else {
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw HelperError.commandFailed("Command failed: \(errorMessage)")
        }
    }
    
    func processRequest(_ request: [String: Any]) -> [String: Any] {
        guard let command = request["command"] as? String,
              let arguments = request["arguments"] as? [String] else {
            return ["error": "Invalid request format"]
        }
        
        do {
            let result = try executeCommand([command] + arguments)
            return ["result": result]
        } catch {
            return ["error": error.localizedDescription]
        }
    }
}

enum HelperError: LocalizedError {
    case commandFailed(String)
    case invalidRequest
    
    var errorDescription: String? {
        switch self {
        case .commandFailed(let message):
            return message
        case .invalidRequest:
            return "Invalid request"
        }
    }
}

// Helper tool main execution
func main() {
    let helper = ContainerHelper()
    
    // Read input from stdin
    var input = ""
    while let line = readLine() {
        input += line
    }
    
    guard let data = input.data(using: .utf8),
          let request = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        let errorResponse = ["error": "Invalid JSON input"]
        if let responseData = try? JSONSerialization.data(withJSONObject: errorResponse),
           let responseString = String(data: responseData, encoding: .utf8) {
            print(responseString)
        }
        exit(1)
    }
    
    let response = helper.processRequest(request)
    
    guard let responseData = try? JSONSerialization.data(withJSONObject: response),
          let responseString = String(data: responseData, encoding: .utf8) else {
        let errorResponse = ["error": "Failed to serialize response"]
        if let errorData = try? JSONSerialization.data(withJSONObject: errorResponse),
           let errorString = String(data: errorData, encoding: .utf8) {
            print(errorString)
        }
        exit(1)
    }
    
    print(responseString)
    exit(0)
}

main()

