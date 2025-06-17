//
//  ContainerXPCService.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

@objc protocol ContainerXPCServiceProtocol {
    // MARK: - Container Management
    func listContainers(reply: @escaping ([String: Any]) -> Void)
    func listImages(reply: @escaping ([String: Any]) -> Void)
    func startContainer(_ containerID: String, reply: @escaping (Error?) -> Void)
    func stopContainer(_ containerID: String, reply: @escaping (Error?) -> Void)
    func deleteContainer(_ containerID: String, reply: @escaping (Error?) -> Void)
    func deleteImage(_ imageName: String, reply: @escaping (Error?) -> Void)
    func createAndRunContainer(image: String, name: String?, reply: @escaping (Error?) -> Void)
    
    // MARK: - Log Operations
    func getContainerLogs(_ containerID: String, lines: Int?, follow: Bool, reply: @escaping (Result<String, Error>) -> Void)
    func getContainerBootLogs(_ containerID: String, reply: @escaping (Result<String, Error>) -> Void)
    
    // MARK: - System Management
    func getSystemStatus(reply: @escaping ([String: Any]) -> Void)
    func startSystem(reply: @escaping (Error?) -> Void)
    func stopSystem(reply: @escaping (Error?) -> Void)
    func restartSystem(reply: @escaping (Error?) -> Void)
    func getSystemLogs(timeFilter: String?, follow: Bool, reply: @escaping (Result<String, Error>) -> Void)
    
    // MARK: - DNS Management
    func listDNSDomains(reply: @escaping ([String: Any]) -> Void)
    func createDNSDomain(_ domain: String, reply: @escaping (Error?) -> Void)
    func deleteDNSDomain(_ domain: String, reply: @escaping (Error?) -> Void)
    func setDefaultDNSDomain(_ domain: String, reply: @escaping (Error?) -> Void)
    
    // MARK: - Terminal Operations
    func openTerminal(for containerID: String, reply: @escaping (Error?) -> Void)
}

class ContainerXPCServiceManager {
    private var connection: NSXPCConnection?
    
    init() {
        setupConnection()
    }
    
    private func setupConnection() {
        connection = NSXPCConnection(serviceName: "cc.citrons.ContainerXPCService")
        connection?.remoteObjectInterface = NSXPCInterface(with: ContainerXPCServiceProtocol.self)
        connection?.resume()
    }
    
    // MARK: - Container Management
    
    func listContainers() async throws -> [Container] {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.listContainers { result in
                if let containers = result["containers"] as? [[String: Any]] {
                    let parsedContainers = containers.compactMap { dict -> Container? in
                        self.parseContainerFromDict(dict)
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
    
    func listImages() async throws -> [ContainerImage] {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.listImages { result in
                if let images = result["images"] as? [[String: Any]] {
                    let parsedImages = images.compactMap { dict -> ContainerImage? in
                        self.parseImageFromDict(dict)
                    }
                    continuation.resume(returning: parsedImages)
                } else if let error = result["error"] as? String {
                    continuation.resume(throwing: ContainerError.commandFailed(error))
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }
    
    func startContainer(_ containerID: String) async throws {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.startContainer(containerID) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func stopContainer(_ containerID: String) async throws {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.stopContainer(containerID) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func deleteContainer(_ containerID: String) async throws {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.deleteContainer(containerID) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func deleteImage(_ imageName: String) async throws {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.deleteImage(imageName) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func createAndRunContainer(image: String, name: String? = nil) async throws {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.createAndRunContainer(image: image, name: name) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Log Operations
    
    func getContainerLogs(_ containerID: String, lines: Int? = nil, follow: Bool = false) async throws -> String {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.getContainerLogs(containerID, lines: lines, follow: follow) { result in
                switch result {
                case .success(let logs):
                    continuation.resume(returning: logs)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func getContainerBootLogs(_ containerID: String) async throws -> String {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.getContainerBootLogs(containerID) { result in
                switch result {
                case .success(let logs):
                    continuation.resume(returning: logs)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - System Management
    
    func getSystemStatus() async throws -> SystemServiceStatus {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.getSystemStatus { result in
                if let statusString = result["status"] as? String {
                    let status: SystemServiceStatus = statusString == "running" ? .running : .stopped
                    continuation.resume(returning: status)
                } else if let error = result["error"] as? String {
                    continuation.resume(throwing: ContainerError.commandFailed(error))
                } else {
                    continuation.resume(returning: .stopped)
                }
            }
        }
    }
    
    func startSystem() async throws {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.startSystem { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func stopSystem() async throws {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.stopSystem { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func restartSystem() async throws {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.restartSystem { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func getSystemLogs(timeFilter: String? = nil, follow: Bool = false) async throws -> String {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.getSystemLogs(timeFilter: timeFilter, follow: follow) { result in
                switch result {
                case .success(let logs):
                    continuation.resume(returning: logs)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - DNS Management
    
    func listDNSDomains() async throws -> [DNSDomain] {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.listDNSDomains { result in
                if let domains = result["domains"] as? [[String: Any]] {
                    let parsedDomains = domains.compactMap { dict -> DNSDomain? in
                        guard let domain = dict["domain"] as? String else { return nil }
                        let isDefault = dict["isDefault"] as? Bool ?? false
                        return DNSDomain(domain: domain, isDefault: isDefault)
                    }
                    continuation.resume(returning: parsedDomains)
                } else if let error = result["error"] as? String {
                    continuation.resume(throwing: ContainerError.commandFailed(error))
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }
    
    func createDNSDomain(_ domain: String) async throws {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.createDNSDomain(domain) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func deleteDNSDomain(_ domain: String) async throws {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.deleteDNSDomain(domain) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func setDefaultDNSDomain(_ domain: String) async throws {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.setDefaultDNSDomain(domain) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Terminal Operations
    
    func openTerminal(for containerID: String) async throws {
        guard let connection = connection else {
            throw ContainerError.invalidOutput
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let service = connection.remoteObjectProxy as! ContainerXPCServiceProtocol
            service.openTerminal(for: containerID) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func parseContainerFromDict(_ dict: [String: Any]) -> Container? {
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
        
        let imageReference = dict["imageReference"] as? String ?? image
        let imageDigest = dict["imageDigest"] as? String ?? ""
        let hostname = dict["hostname"] as? String ?? name
        let cpus = dict["cpus"] as? Int ?? 0
        let memoryInBytes = dict["memoryInBytes"] as? Int64 ?? 0
        let rosetta = dict["rosetta"] as? Bool ?? false
        
        // Parse networks
        var networks: [ContainerNetwork] = []
        if let networkArray = dict["networks"] as? [[String: Any]] {
            networks = networkArray.compactMap { networkDict in
                guard let address = networkDict["address"] as? String,
                      let gateway = networkDict["gateway"] as? String,
                      let network = networkDict["network"] as? String else {
                    return nil
                }
                let hostname = networkDict["hostname"] as? String
                return ContainerNetwork(hostname: hostname, address: address, gateway: gateway, network: network)
            }
        }
        
        return Container(
            containerID: containerID,
            name: name,
            image: image,
            imageReference: imageReference,
            imageDigest: imageDigest,
            hostname: hostname,
            status: status,
            os: os,
            arch: arch,
            cpus: cpus,
            memoryInBytes: memoryInBytes,
            networks: networks,
            rosetta: rosetta
        )
    }
    
    private func parseImageFromDict(_ dict: [String: Any]) -> ContainerImage? {
        guard let name = dict["name"] as? String,
              let tag = dict["tag"] as? String,
              let size = dict["size"] as? Int64 else {
            return nil
        }
        
        let reference = dict["reference"] as? String ?? "\(name):\(tag)"
        let digest = dict["digest"] as? String ?? ""
        let created = dict["created"] as? String
        
        return ContainerImage(
            name: name,
            tag: tag,
            reference: reference,
            digest: digest,
            size: size,
            created: created
        )
    }
    
    deinit {
        connection?.invalidate()
    }
}
