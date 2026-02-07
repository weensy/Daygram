# AGENTS.md

This file provides guidance to AI coding agents (including Claude, Gemini, GPT, etc.) when working with code in this repository.

## Project Overview

Daygram is a private photo diary iOS app built with SwiftUI and SwiftData. The app allows users to capture one photo and one line of text per day to document their daily life. Focus is on simplicity, privacy, and beautiful UI with modern iOS design patterns.

## Architecture

### Core Components

- **App Entry Point**: `DaygramApp.swift` - Main app with SwiftData ModelContainer setup
- **Data Model**: `MemoryEntry.swift` - SwiftData model with date, text, image filenames, and timestamps
- **Image Storage**: `ImageStorageManager.swift` - Handles saving/loading HEIC images to Documents directory
- **Image Caching**: `ThumbnailCache.swift` - NSCache-based in-memory caching for performance

### Main Views

- **CalendarView.swift** - Monthly calendar with entry thumbnails, main navigation hub
- **AddEntryView.swift** - Photo picker with text input and date selection
- **EditEntryView.swift** - Edit existing entry text and image
- **EntryDetailView.swift** - Full-screen entry carousel with swipe navigation
- **EntryCarouselView.swift** - Horizontal carousel for browsing entries
- **ThumbnailIndicatorView.swift** - Thumbnail preview bar with tap-to-center
- **SettingsView.swift** - Daily reminder and app information

### Authentication (Currently Disabled)

- **AuthenticationView.swift** - Optional biometric app lock (disabled for initial release)
- **BiometricAuthManager.swift** - Face ID/Touch ID integration
- **AppPasscodeManager.swift** - 4-digit passcode management with Keychain
- **PasscodeSetupView.swift** / **PasscodeEntryView.swift** - Passcode UI

### Supporting Files

- **NotificationManager.swift** - Daily reminder notifications
- **ShareableEntryView.swift** - Shareable card view for entry export
- **AppColor.swift** - App color scheme
- **Font+Extension.swift** - Custom font loading (Pretendard)

## Key Features

### Current Features
- **Privacy First**: All data stored locally, no cloud sync by default
- **HEIC Image Format**: Efficient compression (90% for originals, 80% for thumbnails)
- **Image Management**: Original images preserved, 400px thumbnails for quick loading
- **Entry Carousel**: Swipeable full-screen image viewer with thumbnail navigation
- **Daily Reminders**: Optional notification to encourage daily journaling
- **Localization**: English, Korean, and Japanese support
- **Custom Fonts**: Pretendard font family

### Planned Features (See `implementation_plan.md`)
- **iCloud Sync**: User-controlled CloudKit synchronization
- **Data Migration**: Seamless transition between local and iCloud storage

## Data Structure

See [DATA_STRUCTURE.md](./DATA_STRUCTURE.md) for complete documentation of:
- SwiftData models
- File system layout
- UserDefaults settings
- Keychain security
- Memory caching strategy

## Development Commands

### Building
```bash
# Build for iOS Simulator
xcodebuild -scheme Daygram -destination 'platform=iOS Simulator,name=iPhone 16' build

# Build for iOS Device  
xcodebuild -scheme Daygram -destination 'platform=iOS,name=Any iOS Device' build
```

### Testing
```bash
# Run unit tests
xcodebuild test -scheme Daygram -destination 'platform=iOS Simulator,name=iPhone 16'

# Run UI tests
xcodebuild test -scheme Daygram -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:DaygramUITests
```

### Project Structure
```
Daygram/
├── Daygram/                      # Main app source
│   ├── DaygramApp.swift          # App entry point with SwiftData setup
│   ├── MemoryEntry.swift         # SwiftData model
│   ├── ImageStorageManager.swift # HEIC image storage
│   ├── ThumbnailCache.swift      # In-memory image cache
│   ├── CalendarView.swift        # Main calendar UI
│   ├── AddEntryView.swift        # Entry creation
│   ├── EditEntryView.swift       # Entry editing
│   ├── EntryDetailView.swift     # Full-screen entry view
│   ├── EntryCarouselView.swift   # Swipeable carousel
│   ├── ThumbnailIndicatorView.swift # Thumbnail navigation
│   ├── SettingsView.swift        # Settings and reminders
│   ├── NotificationManager.swift # Daily reminder system
│   ├── ShareableEntryView.swift  # Export functionality
│   ├── AuthenticationView.swift  # (Disabled) Biometric lock
│   ├── BiometricAuthManager.swift
│   ├── AppPasscodeManager.swift
│   ├── PasscodeSetupView.swift
│   ├── PasscodeEntryView.swift
│   ├── AppColor.swift
│   ├── Font+Extension.swift
│   ├── Assets.xcassets/          # App assets
│   ├── Fonts/                    # Pretendard font family
│   ├── en.lproj/                 # English localization
│   ├── ko.lproj/                 # Korean localization
│   └── ja.lproj/                 # Japanese localization
├── DaygramTests/                 # Unit tests
├── DaygramUITests/               # UI tests
├── DATA_STRUCTURE.md             # Complete data architecture docs
└── AGENTS.md                     # This file
```

## Key Frameworks Used
- **SwiftUI** for declarative UI
- **SwiftData** for data persistence with CloudKit integration (planned)
- **PhotosUI** for photo picker
- **UserNotifications** for daily reminders
- **LocalAuthentication** for biometric authentication (disabled)
- **UniformTypeIdentifiers** for HEIC handling
- **ImageIO** for HEIC encoding/decoding

## Design Patterns

### iOS 26+ Features (Used)
- **Liquid Glass Effects**: `.glassEffectTransition(.materialize)` for UI animations
- **Modern SwiftUI**: Navigation stacks, @Observable, @Model
- **NSCache**: Memory-efficient image caching

### UI/UX Patterns
- **Swipe-to-dismiss**: Entry detail view dismisses with drag gesture
- **Tap-to-center**: Thumbnail indicators snap to center on tap
- **Carousel Navigation**: Horizontal scrolling with page-aligned entries
- **Date Picker**: Custom navigation bar date selector

## Localization

All user-facing strings use `String(localized:)`:
```swift
Text(String(localized: "calendar.title"))
```

Localization files:
- `en.lproj/Localizable.strings` - English
- `ko.lproj/Localizable.strings` - Korean  
- `ja.lproj/Localizable.strings` - Japanese

## Build Configurations
- **Debug**: Development builds
- **Release**: Production builds

Available targets:
- `Daygram` (main app)
- `DaygramTests` (unit tests)
- `DaygramUITests` (UI automation tests)

## Important Notes for AI Agents

1. **SwiftData**: Use `@Model` macro, `@Query` for fetching, avoid manual SQL
2. **Image Format**: Always use HEIC for storage efficiency
3. **Localization**: Never hardcode English strings, always use localization keys
4. **Privacy**: No external APIs, all data stays on device (until iCloud sync is enabled)
5. **Performance**: Use ThumbnailCache for images, avoid loading full images unnecessarily
6. **iOS Version**: Target iOS 17+ for SwiftData compatibility

## Current Development Focus

Working on iCloud Sync implementation (see `implementation_plan.md`):
- User-controlled CloudKit synchronization
- Dual-mode storage (local/iCloud)
- Data migration between modes
- Settings UI for sync toggle

## Code Style

- Use SwiftUI best practices
- Prefer composition over inheritance
- Keep views focused and reusable
- Use descriptive variable names
- Comment complex algorithms only
- Follow Apple's Swift API Design Guidelines
