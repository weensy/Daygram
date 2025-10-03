# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Daygram is a private baby photo diary iOS app built with SwiftUI and SwiftData. The app allows parents to capture one photo and one line of text per day to document their baby's growth. Focus is on simplicity, privacy, and speed (5 seconds to add an entry).

## Architecture

- **App Entry Point**: `DaygramApp.swift` - Main app with SwiftData ModelContainer setup and AuthenticationView as root
- **Data Model**: `MemoryEntry.swift` - SwiftData model with date, text, image filenames, and timestamps
- **Image Storage**: `ImageStorageManager.swift` - Handles saving/loading images to Documents directory with automatic resizing
- **Authentication**: `BiometricAuthManager.swift` + `AuthenticationView.swift` - Optional Face ID/Touch ID app lock
- **Main Features**:
  - `CalendarView.swift` - Monthly calendar with day thumbnails, shows first entry of each day
  - `DayDetailView.swift` - Lists all entries for selected day, sorted newest first
  - `AddEntryView.swift` - Camera/photo library picker with text input (≤500 chars)
  - `EntryDetailView.swift` - Full image view with editable text and delete functionality
  - `SettingsView.swift` - Privacy settings and app information

## Key Features

- **Privacy First**: All data stored locally, no cloud sync, optional biometric app lock
- **Image Management**: Automatic resizing (3000px max) + 400px thumbnails stored in Documents/
- **One Entry Per Photo**: Simple constraint of one photo + text per entry
- **Fast UX**: Designed for quick daily capture without complex workflows

## Development Commands

### Building
```bash
# Build for iOS Simulator
xcodebuild -scheme Daygram -destination 'platform=iOS Simulator,name=iPhone 15' build

# Build for iOS Device  
xcodebuild -scheme Daygram -destination 'platform=iOS,name=Any iOS Device' build

# Build for macOS (Designed for iPad)
xcodebuild -scheme Daygram -destination 'platform=macOS' build
```

### Testing
```bash
# Run unit tests
xcodebuild test -scheme Daygram -destination 'platform=iOS Simulator,name=iPhone 15'

# Run UI tests
xcodebuild test -scheme Daygram -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:DaygramUITests
```

### Project Structure
```
Daygram/
├── Daygram/                 # Main app source
│   ├── DaygramApp.swift     # App entry point with SwiftData setup
│   ├── ContentView.swift    # Main UI with NavigationSplitView
│   ├── Item.swift           # SwiftData model
│   └── Assets.xcassets/     # App assets
├── DaygramTests/            # Unit tests (Swift Testing)
└── DaygramUITests/          # UI tests
```

## Key Frameworks Used
- SwiftUI for UI
- SwiftData for data persistence  
- Swift Testing for unit tests (not XCTest)

## Build Configurations
- Debug
- Release

Available targets: Daygram (main app), DaygramTests, DaygramUITests