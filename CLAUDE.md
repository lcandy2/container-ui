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