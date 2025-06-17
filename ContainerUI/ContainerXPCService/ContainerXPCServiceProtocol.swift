//
//  ContainerXPCServiceProtocol.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/17/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

/// The protocol that this service will vend as its API for container management operations.
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
