# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ContainerUI is a macOS SwiftUI application built with Xcode. It's a developer tools application (LSApplicationCategoryType: public.app-category.developer-tools) targeting macOS 15.0+.

## Build Commands

- **Build project**: Open `ContainerUI/ContainerUI.xcodeproj` in Xcode and use Cmd+B, or use `xcodebuild` from the command line
- **Run application**: Use Cmd+R in Xcode or `xcodebuild -scheme ContainerUI -configuration Debug`
- **Clean build**: Product → Clean Build Folder in Xcode or `xcodebuild clean`

## Architecture

- **App Entry Point**: `ContainerUI/ContainerUI/ContainerUIApp.swift` - Main app structure using SwiftUI App protocol
- **Main View**: `ContainerUI/ContainerUI/ContentView.swift` - Primary UI view
- **Assets**: `ContainerUI/ContainerUI/Assets.xcassets/` - App icons and color assets
- **Bundle Identifier**: `cc.citrons.container-uI`
- **Swift Version**: 5.0 with MainActor isolation enabled

## Development Notes

- App runs in sandbox mode with user-selected files access (readonly)
- Uses Swift's upcoming feature for member import visibility
- Targets macOS deployment target 15.0 minimum
- String catalogs are enabled for localization
- Code signing is set to automatic

## Container CLI Integration

- App integrates with Apple's `container` CLI tool
- Supports paths: `/usr/local/bin/container`, `/opt/homebrew/bin/container`, or PATH lookup
- Commands used: `container list`, `container start/stop <name>`, `container rm <name>`

## Sandboxing and External Tools

For production use, consider these approaches per Apple's documentation:

1. **Embedded Helper Tool**: Bundle the container CLI as a helper tool in the app bundle
   - Add container binary to project as a target
   - Configure Copy Files build phase to embed in "Executables"
   - Use entitlements: `com.apple.security.app-sandbox` and `com.apple.security.inherit`

2. **XPC Service**: Create an XPC service for container operations
   - More secure isolation
   - Required for App Store distribution
   - Implement `ContainerXPCServiceProtocol` for container operations

3. **Development**: For local development, temporarily disable App Sandbox
   - Set `ENABLE_APP_SANDBOX = NO` in build settings
   - Not suitable for distribution

## Recommended Production Architecture

- Create XPC service target for container CLI execution
- Main app communicates with XPC service via NSXPCConnection
- XPC service handles all container binary execution
- Maintains sandbox security while enabling CLI access