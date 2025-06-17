# ContainerUI

> ⚠️ **Under Rapid Development** - This project is actively being developed with frequent updates and new features.

A native macOS SwiftUI application for managing containers using Apple's built-in `container` CLI tool. ContainerUI provides an intuitive, three-column interface following Apple's Human Interface Guidelines for seamless container management on macOS.

![macOS](https://img.shields.io/badge/macOS-15.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Native-green.svg)
![Development](https://img.shields.io/badge/Status-Active%20Development-yellow.svg)

![CleanShot 2025-06-17 at 10 32 36@2x](https://github.com/user-attachments/assets/01fea8d4-0030-48eb-8c39-00903870d024)

## Features

### 🚢 Container Management
- **List all containers** with rich information including resource allocation and network details
- **Start, stop, and restart** containers with one-click actions
- **Create new containers** from images with customizable settings
- **Delete containers** with confirmation
- **Real-time status updates** showing running/stopped states

### 🖼️ Image Management
- **Browse container images** with size and architecture information
- **Multi-architecture detection** for Apple Silicon compatibility
- **Registry information** showing source repositories
- **Create containers** directly from images
- **Delete unused images** to free up space

### ⚙️ System Management
- **Container system status** monitoring
- **DNS domain management** for container networking
- **System logs** with filtering and search capabilities
- **Start/stop container runtime** as needed

### 📊 Advanced Logging
- **Universal logs viewer** supporting multiple log types:
  - Container runtime logs
  - Container boot logs
  - System logs
- **Multi-window support** for viewing multiple log streams simultaneously
- **Search and filtering** with real-time text search
- **Export capabilities** for log analysis
- **Native macOS UI** with line numbers and word wrap options

## Requirements

- **macOS 15.0** or later
- **Apple's container CLI tool** installed and accessible
- **Xcode 15.0** or later (for building from source)

## Installation

### Prerequisites

The app requires Apple's `container` CLI tool to be installed. This is typically available through:

```bash
# Check if container tool is available
which container

# The app will look for the tool in these locations:
# /usr/local/bin/container
# /opt/homebrew/bin/container
# /usr/bin/container
# Or via PATH lookup
```

### Building from Source

1. **Clone the repository:**
   ```bash
   git clone https://github.com/lcandy2/container-ui.git
   cd container-ui
   ```

2. **Open in Xcode:**
   ```bash
   open ContainerUI/ContainerUI.xcodeproj
   ```

3. **Build and run:**
   - Select the ContainerUI scheme
   - Press `Cmd+R` to build and run
   - Or use command line: `xcodebuild -scheme ContainerUI -configuration Debug`

## Architecture

ContainerUI follows a modern SwiftUI architecture with clear separation of concerns:

### Project Structure
```
ContainerUI/
├── Application/          # App entry point and configuration
├── Models/              # Core data models
├── Services/            # Business logic and CLI integration
├── Screens/             # Feature-based UI organization
│   ├── Containers/      # Container management views
│   ├── Images/         # Image management views
│   ├── Logs/           # Universal logs system
│   └── System/         # System management views
└── Shared/             # Reusable components and utilities
```

### Key Technologies
- **SwiftUI** with NavigationSplitView for native three-column layout
- **JSON parsing** for rich CLI data extraction
- **Async/await** for modern concurrency
- **Multi-window support** for enhanced productivity
- **Sandbox-compatible** process execution

## Usage

### Getting Started

1. **Launch ContainerUI** from Applications folder or Xcode
2. **Container system** will automatically start if needed
3. **Browse containers** in the left sidebar under "Containers"
4. **Select a container** to view details in the right inspector
5. **Manage containers** using context menus or inspector actions

### Container Operations

- **Right-click containers** for quick actions (start, stop, delete, logs)
- **Use the inspector** for detailed information and advanced operations
- **Create new containers** using the "New Container" button
- **View logs** by clicking "View Logs" - opens in a dedicated window

### Image Management

- **Switch to "Images" tab** to browse available container images
- **View image details** including size, registry, and architecture
- **Create containers** directly from images
- **Delete unused images** to free up disk space

### System Management

- **Access "System" tab** for container runtime management
- **Monitor system status** and resource usage
- **Manage DNS domains** for container networking
- **View system logs** for troubleshooting

## Development

### Build Commands

```bash
# Build project
xcodebuild -scheme ContainerUI -configuration Debug build

# Run application
xcodebuild -scheme ContainerUI -configuration Debug

# Clean build
xcodebuild clean
```

### Sandboxing

For development, you may need to temporarily disable App Sandbox:
- Set `ENABLE_APP_SANDBOX = NO` in build settings
- This allows access to external CLI tools
- **Not suitable for App Store distribution**

For production deployment, consider:
- **XPC Service** for secure CLI execution
- **Embedded helper tool** bundled with the app
- See `CLAUDE.md` for detailed architecture guidance

## CLI Integration

ContainerUI integrates with Apple's `container` CLI using JSON output for reliable parsing:

- **Containers:** `container ls -a --format json`
- **Images:** `container image ls --format json`
- **System:** `container system *` commands
- **Logs:** `container logs` with various filters

## Contributing

> 🚧 **Active Development Notice** - Due to rapid development, please check existing issues and PRs before starting work to avoid conflicts.

1. Fork the repository at [https://github.com/lcandy2/container-ui](https://github.com/lcandy2/container-ui)
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Follow the existing architecture patterns (see `CLAUDE.md` for guidance)
4. Ensure all features work with the JSON CLI format
5. Test thoroughly on macOS 15.0+
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## License

Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.

## Support

For issues and feature requests:
- **GitHub Issues**: [https://github.com/lcandy2/container-ui/issues](https://github.com/lcandy2/container-ui/issues)
- **Troubleshooting**: Check the built-in error messages and alerts
- **CLI Integration**: Review system logs for container tool issues
- **System Status**: Use the System tab for runtime diagnostics

> 💡 **Development Updates** - Check the repository frequently for new features and improvements as this project is under active development.

---

**ContainerUI** - Native container management for macOS developers.
