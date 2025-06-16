//
//  ContainerXPCService.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

@objc protocol ContainerXPCServiceProtocol {
    func listContainers(reply: @escaping ([String: Any]) -> Void)
    func startContainer(_ name: String, reply: @escaping (Error?) -> Void)
    func stopContainer(_ name: String, reply: @escaping (Error?) -> Void)
    func deleteContainer(_ name: String, reply: @escaping (Error?) -> Void)
}

class ContainerXPCServiceManager {
    private var connection: NSXPCConnection?
    
    init() {
        setupConnection()
    }
    
    private func setupConnection() {
        connection = NSXPCConnection(serviceName: "cc.citrons.container-ui.ContainerXPCService")
        connection?.remoteObjectInterface = NSXPCInterface(with: ContainerXPCServiceProtocol.self)
        connection?.resume()
    }
    
    func listContainers() async throws -> [Container] {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.listContainers { result in
                // Parse result and convert to Container objects
                if let containers = result["containers"] as? [[String: Any]] {
                    let parsedContainers = containers.compactMap { dict -> Container? in
                        guard let containerID = dict["containerID"] as? String,
                              let name = dict["name"] as? String,
                              let image = dict["image"] as? String,
                              let statusString = dict["status"] as? String,
                              let os = dict["os"] as? String,
                              let arch = dict["arch"] as? String else {
                            return nil
                        }
                        
                        let status: ContainerStatus
                        switch statusString.lowercased() {
                        case "running":
                            status = .running
                        case "stopped":
                            status = .stopped
                        default:
                            status = .exited
                        }
                        
                        let addr = dict["addr"] as? String
                        
                        // TODO: Update XPC service to use new Container model with JSON parsing
                        // For now, create a minimal container with available fields
                        return Container(
                            containerID: containerID,
                            name: name,
                            image: image,
                            imageReference: image,
                            imageDigest: "",
                            hostname: name,
                            status: status,
                            os: os,
                            arch: arch,
                            cpus: 0,
                            memoryInBytes: 0,
                            networks: [],
                            rosetta: false
                        )
                    }
                    continuation.resume(returning: parsedContainers)
                } else if let error = result["error"] as? String {
                    continuation.resume(throwing: ContainerError.commandFailed(error))
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }
    
    func startContainer(_ name: String) async throws {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.startContainer(name) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func stopContainer(_ name: String) async throws {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.stopContainer(name) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func deleteContainer(_ name: String) async throws {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.deleteContainer(name) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    deinit {
        connection?.invalidate()
    }
}
