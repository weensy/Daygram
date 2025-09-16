# Daygram Codebase Notes

## High-Level Overview
- SwiftUI app that stores baby diary entries locally using SwiftData's `DiaryEntry` model.
- Launch flow always starts with `AuthenticationView`; if biometrics/passcode succeed (or app lock disabled) the user sees the calendar timeline.
- Core experience revolves around calendar browsing (`CalendarView`), entry creation (`AddEntryView`), and entry inspection/editing (`EntryDetailView`).
- Images persist under the Documents directory (`Images/` + `Thumbnails/`) via `ImageStorageManager`; in-memory reuse handled by `ThumbnailCache`.

## Data Model & Persistence
- `DiaryEntry` (`Daygram/DiaryEntry.swift`): stores id, date, text, file names, and timestamps. Provides helpers like `dayKey` for lookups and `updateText` for editing metadata.
- `DaygramApp` wires a persistent `ModelContainer` (disk-backed) and injects it across the view hierarchy.
- SwiftData queries: most views rely on `@Query` (e.g., `CalendarView`) or `@Bindable` wrappers to keep SwiftUI state synchronized.

## Authentication Path
- `AuthenticationView` (`Daygram/AuthenticationView.swift`): gates entry with biometrics or passcode depending on `@AppStorage("requireAuthentication")` flag.
- `BiometricAuthManager` wraps `LAContext` to report availability, perform biometric or device-owner auth, and expose friendly icon/name metadata.
- Settings toggle updates `requireAuthentication` and reuses the same manager to reflect available biometrics.

## Calendar & Browsing Experience
- `CalendarView` renders a horizontally scrolling carousel of month cards (±12 months) with a custom peek layout.
- Each card shows weekday headers and a 6×7 grid of `DayCell` buttons. Cells load thumbnails lazily via `ThumbnailCache` or `ImageStorageManager` fallback.
- Tapping a day opens either `EntryDetailView` (if an entry exists) or `AddEntryView` through `.sheet` binding to `selectedDate`.
- Quick-add floating button: if today's entry exists it jumps to that date; otherwise presents the add sheet. Stats (`currentStreak`, `fullWeeks`, total entries) computed from cached day keys.
- `ThumbnailCache` preloads entries for the visible month whenever `selectedMonth` updates.

## Entry Creation & Editing
- `AddEntryView`: lets user choose photo (camera via `ImagePicker` or `PhotosPicker` for library), enter optional text (500 char limit), and persists via SwiftData + `ImageStorageManager` resizing (3000px max, 400px thumbnail).
- `EntryDetailView`: shows full image (cached) and note. Provides inline text editing, share sheet, and deletion (including cleanup of stored files). Keeps UI responsive by loading images in a detached task and caching results.

## Settings & Misc Views
- `SettingsView`: simple list with branding, privacy information, and authentication toggle. Uses `BiometricAuthManager` to display context-aware labels/icons.
- `StatItem` struct: reusable small card for metrics in the calendar footer (currently streak/weeks/memories).
- Reusable helpers: `DateWrapper` enables binding optional `Date` to a sheet; `ShareSheet` bridges `UIActivityViewController` for sharing.

## Storage & Caching
- `ImageStorageManager` centralizes disk operations (create folders, save JPEGs, resize via Core Graphics context, delete entries). Generates unique filenames for each save call.
- `ThumbnailCache` maintains dictionaries for thumbnails and full images, using a dedicated queue for background loading and main-thread updates for UI safety.

## Testing Status
- XCTest & `Testing` targets are mostly boilerplate placeholders (`DaygramTests`, `DaygramUITests`, launch performance skeleton). No functional tests implemented yet.

## Open Questions / Follow-Up Ideas
1. Consider deduping `DateFormatter` and `Calendar` usage with shared utilities to avoid repeated instantiation cost.
2. Evaluate memory usage of `ThumbnailCache` (no eviction policy yet).
3. Add error surfaces for failed image saves/loads instead of silent `print` statements.
4. Expand testing around data persistence, authentication fallback, and calendar stats calculations.
