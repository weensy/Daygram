# Daygram Current Data Structure

> 📅 Created: 2026-02-08  
> 📌 Purpose: Complete snapshot of data structures before implementing iCloud sync

---

## 1. SwiftData Model (Database)

### MemoryEntry

**Storage Location**: SwiftData (SQLite database)  
**File Path**: `~/Library/Application Support/default.store`

```swift
@Model
final class MemoryEntry {
    var id: UUID                    // Unique identifier
    var date: Date                  // Entry date (user-selected date)
    var text: String                // Diary text content
    var imageFileName: String       // Original image file name
    var thumbnailFileName: String   // Thumbnail image file name
    var createdAt: Date            // Creation timestamp (metadata)
    var updatedAt: Date            // Last modification timestamp (metadata)
}
```

**Field Details**:
| Field | Type | Description | Example Value |
|-------|------|-------------|---------------|
| `id` | UUID | Unique entry identifier, auto-generated | `550e8400-e29b-41d4-a716-446655440000` |
| `date` | Date | Date the entry belongs to (diary date) | `2026-02-08 00:00:00` |
| `text` | String | User-written diary text | `"Had a great day today"` |
| `imageFileName` | String | Image file name (HEIC) | `"a1b2c3d4.heic"` |
| `thumbnailFileName` | String | Thumbnail file name (HEIC) | `"e5f6g7h8_thumb.heic"` |
| `createdAt` | Date | Entry creation timestamp | `2026-02-08 14:30:00` |
| `updatedAt` | Date | Last modification timestamp | `2026-02-08 15:45:00` |

**Extension Methods**:
```swift
extension MemoryEntry {
    var dayKey: String              // Date key in "yyyy-MM-dd" format
    // Example: "2026-02-08"
}
```

---

## 2. Image File System

### Directory Structure

```
📁 Document Directory/
├── 📁 Images/
│   ├── {UUID}.heic        (Original images)
│   ├── {UUID}.heic
│   └── ...
│
└── 📁 Thumbnails/
    ├── {UUID}_thumb.heic  (Thumbnail images)
    ├── {UUID}_thumb.heic
    └── ...
```

**Path Information**:
- **Documents Directory**: `FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!`
- **Images Directory**: `Documents/Images/`
- **Thumbnails Directory**: `Documents/Thumbnails/`

### Image File Specifications

#### Original Images
- **Format**: HEIC (High Efficiency Image Coding)
- **Filename Pattern**: `{UUID}.heic`
- **Compression Quality**: 0.9 (90%)
- **Max Size**: Unlimited (preserves original resolution)
- **Orientation**: Normalized (orientation metadata removed, baked into pixel data)

#### Thumbnail Images
- **Format**: HEIC
- **Filename Pattern**: `{UUID}_thumb.heic`
- **Compression Quality**: 0.8 (80%)
- **Max Size**: 400px (longest side)
- **Purpose**: List views, carousel previews

### Image Storage Process

```
1. User selects photo
2. Load as UIImage
3. Normalize orientation (redraw)
4. Convert to HEIC (original: 90%, thumbnail: 80%)
5. Resize thumbnail (maxDimension: 400px)
6. Save to file system
   - Documents/Images/{UUID}.heic
   - Documents/Thumbnails/{UUID}_thumb.heic
7. Store filenames in MemoryEntry
```

---

## 3. UserDefaults (App Settings)

**Storage Location**: `~/Library/Preferences/com.yourteam.Daygram.plist`

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `requireAuthentication` | Bool | `false` | App lock enabled status |
| `dailyReminderEnabled` | Bool | `false` | Daily reminder enabled status |
| `reminderHour` | Int | `22` | Reminder hour (24-hour format) |
| `reminderMinute` | Int | `0` | Reminder minute |

**Usage Example**:
```swift
@AppStorage("requireAuthentication") private var requireAuthentication = false
@AppStorage("dailyReminderEnabled") private var dailyReminderEnabled = false
@AppStorage("reminderHour") private var reminderHour = 22
@AppStorage("reminderMinute") private var reminderMinute = 0
```

---

## 4. Keychain (Security Data)

**Storage Location**: iOS Keychain (encrypted)

### App Passcode

- **Key**: `"appPasscode"`
- **Service**: `Bundle.main.bundleIdentifier` (e.g., `"com.yourteam.Daygram"`)
- **Value**: 4-digit numeric passcode (encrypted)
- **Manager**: `AppPasscodeManager.swift`

**Storage Method**:
```swift
// Keychain Item Attributes
kSecClass: kSecClassGenericPassword
kSecAttrService: Bundle.main.bundleIdentifier
kSecAttrAccount: "appPasscode"
kSecValueData: Data(passcode.utf8)
```

---

## 5. Memory Cache (Runtime Only)

### ThumbnailCache

**Storage Location**: Memory (only while app is running)

```swift
class ThumbnailCache {
    private let thumbnailCache = NSCache<NSString, UIImage>()
    private let fullImageCache = NSCache<NSString, UIImage>()
    
    // Limits
    thumbnailCache.countLimit = 100
    fullImageCache.countLimit = 20
    fullImageCache.totalCostLimit = 100 * 1024 * 1024  // 100MB
}
```

**Caching Strategy**:
- **Thumbnails**: Cache up to 100 items
- **Full Images**: Cache up to 20 items, 100MB limit
- **Purpose**: Improve UI performance, prevent repeated loading
- **Volatile**: Cleared on app termination

---

## 6. Data Relationship Diagram

```mermaid
graph TB
    A[MemoryEntry] -->|imageFileName| B[Images/{UUID}.heic]
    A -->|thumbnailFileName| C[Thumbnails/{UUID}_thumb.heic]
    A -->|SwiftData| D[(SQLite DB)]
    
    E[UserDefaults] -->|Settings| F[App Behavior]
    G[Keychain] -->|App Passcode| H[Authentication System]
    
    B -->|On Load| I[ThumbnailCache]
    C -->|On Load| I
    
    style A fill:#e1f5ff
    style D fill:#ffe1e1
    style E fill:#fff4e1
    style G fill:#e8e1ff
    style I fill:#e1ffe8
```

---

## 7. Data Lifecycle

### Entry Creation
```
1. User selects photo in AddEntryView
2. Call ImageStorageManager.saveImage()
   → Save original image (Images/)
   → Generate and save thumbnail (Thumbnails/)
   → Return filenames
3. Create MemoryEntry object
4. Add to SwiftData context
5. context.save() → Save to SQLite DB
```

### Entry Retrieval
```
1. Query entries with @Query in CalendarView/EntryDetailView
2. SwiftData loads data from SQLite
3. Extract imageFileName/thumbnailFileName
4. Load images with ImageStorageManager
5. Check ThumbnailCache first → Load from file system if not cached
6. Render UI
```

### Entry Update
```
1. Edit text in EditEntryView
2. Call MemoryEntry.updateText()
3. Update updatedAt = Date()
4. SwiftData auto-saves
```

### Entry Deletion
```
1. Tap delete button
2. Call ImageStorageManager.deleteEntry()
   → Delete Images/{imageFileName}
   → Delete Thumbnails/{thumbnailFileName}
3. Delete entry from SwiftData context
4. context.save() → Remove from SQLite
```

---

## 8. Current Storage Size Estimation

**Example Calculation** (based on 100 entries):

| Item | Size per Item | Count | Total Size |
|------|---------------|-------|------------|
| MemoryEntry (SQLite) | ~500 bytes | 100 | ~50 KB |
| Original Images (HEIC) | ~2-5 MB | 100 | ~200-500 MB |
| Thumbnails (HEIC) | ~50-100 KB | 100 | ~5-10 MB |
| UserDefaults | ~1 KB | 1 | ~1 KB |
| Keychain | ~100 bytes | 1 | ~100 bytes |
| **Total** | - | - | **~205-510 MB** |

---

## 9. Current Constraints and Characteristics

### Advantages
- ✅ **Local-First**: All data stored locally for fast access
- ✅ **Privacy**: No external servers, stored only on user's device
- ✅ **Offline**: No internet connection required
- ✅ **HEIC Format**: Efficient compression saves storage space

### Limitations
- ⚠️ **Single Device**: No cross-device synchronization
- ⚠️ **Backup Dependent**: Relies on iCloud Backup or iTunes Backup
- ⚠️ **Device Change**: Manual migration required
- ⚠️ **Storage Space**: All data stored locally, consumes device storage

---

## 10. Planned Changes for iCloud Sync Implementation

### New Data Structures

#### UserDefaults
```
+ iCloudSyncEnabled: Bool (default: false)
```

#### iCloud Container
```
📁 iCloud Container (iCloud.com.yourteam.Daygram)/
├── 📁 Documents/
│   ├── 📁 Images/
│   │   └── {UUID}.heic
│   └── 📁 Thumbnails/
│       └── {UUID}_thumb.heic
│
└── CloudKit Database
    └── MemoryEntry Records
```

#### SwiftData Configuration
```swift
// Current: Local only
cloudKitDatabase: .none

// After: Dynamic
cloudKitDatabase: iCloudEnabled ? .automatic : .none
```

### Dual Mode Support
- **Local Mode**: Same as current
- **iCloud Mode**: Uses CloudKit + iCloud Container
- **Mode Switch**: Automatic data migration
