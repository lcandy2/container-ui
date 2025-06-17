//
//  main.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/17/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation
import os.log

// Create logger for XPC Service
let xpcLogger = Logger(subsystem: "cc.citrons.ContainerXPCService", category: "XPCService")

class ServiceDelegate: NSObject, NSXPCListenerDelegate {
    
    /// This method is where the NSXPCListener configures, accepts, and resumes a new incoming NSXPCConnection.
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        xpcLogger.info("🔗 XPC Service: New connection request received")
        
        // Configure the connection.
        // First, set the interface that the exported object implements.
        newConnection.exportedInterface = NSXPCInterface(with: ContainerXPCServiceProtocol.self)
        
        // Next, set the object that the connection exports. All messages sent on the connection to this service will be sent to the exported object to handle. The connection retains the exported object.
        let exportedObject = ContainerXPCService()
        newConnection.exportedObject = exportedObject
        
        // Add connection handlers
        newConnection.interruptionHandler = {
            xpcLogger.warning("🔌 XPC Service: Connection interrupted")
        }
        
        newConnection.invalidationHandler = {
            xpcLogger.info("❌ XPC Service: Connection invalidated")
        }
        
        // Resuming the connection allows the system to deliver more incoming messages.
        newConnection.resume()
        xpcLogger.info("✅ XPC Service: Connection accepted and resumed")
        
        // Returning true from this method tells the system that you have accepted this connection. If you want to reject the connection for some reason, call invalidate() on the connection and return false.
        return true
    }
}

xpcLogger.info("🚀 XPC Service: Starting up...")

// Create the delegate for the service.
let delegate = ServiceDelegate()

// Set up the one NSXPCListener for this service. It will handle all incoming connections.
let listener = NSXPCListener.service()
listener.delegate = delegate

xpcLogger.info("👂 XPC Service: Listener configured, starting to listen...")

// Resuming the serviceListener starts this service. This method does not return.
listener.resume()

xpcLogger.info("🔄 XPC Service: Listener resumed, service is now running")
